#!/bin/zsh

set -u
set -o pipefail

BASE="$HOME/Library/Application Support/chatgpt-obsidian-mcp"
SETTINGS_FILE="$BASE/settings.env"
LOCAL_REST_ENV_FILE="$BASE/local-rest.env"
LOG_DIR="$BASE/logs"
STATE_DIR="$BASE/state"
PACKAGE_DIR="$BASE"
MCP_BIN="$PACKAGE_DIR/node_modules/.bin/obsidian-mcp-server"
NGROK_BIN="/opt/homebrew/bin/ngrok"
LOCK_DIR="$STATE_DIR/supervisor.lock"

mkdir -p "$LOG_DIR" "$STATE_DIR"

timestamp() {
  /bin/date '+%Y-%m-%d %H:%M:%S'
}

log() {
  print -r -- "[$(timestamp)] $*"
}

if [[ ! -f "$SETTINGS_FILE" ]]; then
  log "Missing settings file: $SETTINGS_FILE"
  exit 1
fi

source "$SETTINGS_FILE"

cleanup() {
  for pid_name in MCP_PID NGROK_PID; do
    local pid="${(P)pid_name:-}"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 1
      kill -9 "$pid" 2>/dev/null || true
    fi
  done
  rm -rf "$LOCK_DIR"
}

trap cleanup EXIT INT TERM

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    print -r -- "$$" > "$LOCK_DIR/pid"
    return 0
  fi

  if [[ -f "$LOCK_DIR/pid" ]]; then
    local existing_pid
    existing_pid="$(<"$LOCK_DIR/pid")"
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
      log "Another supervisor instance is already running with pid $existing_pid; exiting"
      return 1
    fi
  fi

  rm -rf "$LOCK_DIR"
  mkdir "$LOCK_DIR"
  print -r -- "$$" > "$LOCK_DIR/pid"
  return 0
}

resolve_node_bin_dir() {
  /usr/bin/python3 - <<'PY'
from pathlib import Path

base = Path.home() / ".nvm" / "versions" / "node"
candidates = []
for child in base.glob("v*/bin"):
    node = child / "node"
    npm = child / "npm"
    if node.exists() and npm.exists():
        try:
            version = tuple(int(part) for part in child.parent.name.lstrip("v").split("."))
            candidates.append((version, str(child)))
        except Exception:
            pass

if not candidates:
    raise SystemExit(1)

candidates.sort()
print(candidates[-1][1])
PY
}

assert_commands() {
  if [[ ! -x "$NGROK_BIN" ]]; then
    log "ngrok binary not found at $NGROK_BIN"
    return 1
  fi
  if [[ ! -f "$HOME/Library/Application Support/ngrok/ngrok.yml" ]]; then
    log "ngrok config not found at ~/Library/Application Support/ngrok/ngrok.yml"
    return 1
  fi
  if [[ ! -x "$MCP_BIN" ]]; then
    log "obsidian-mcp-server binary not found at $MCP_BIN"
    return 1
  fi
  if [[ ! -f "$LOCAL_REST_ENV_FILE" ]]; then
    log "Missing Local REST env file: $LOCAL_REST_ENV_FILE"
    return 1
  fi
  if [[ ! -d "$OBSIDIAN_APP" ]]; then
    log "Obsidian.app not found at $OBSIDIAN_APP"
    return 1
  fi
  if [[ ! -d "$VAULT_PATH" ]]; then
    log "Vault path not found: $VAULT_PATH"
    return 1
  fi
  return 0
}

read_local_rest_settings() {
  if [[ ! -f "$LOCAL_REST_ENV_FILE" ]]; then
    log "Missing Local REST env file: $LOCAL_REST_ENV_FILE"
    return 1
  fi
  source "$LOCAL_REST_ENV_FILE"
  if [[ -z "${REST_PORT:-}" || -z "${OBSIDIAN_API_KEY_DYNAMIC:-}" || -z "${OBSIDIAN_BASE_URL_DYNAMIC:-}" || -z "${OBSIDIAN_VERIFY_SSL_DYNAMIC:-}" ]]; then
    log "Local REST env file is missing required values"
    return 1
  fi
  return 0
}

ensure_obsidian_running() {
  if /usr/bin/pgrep -f "${OBSIDIAN_APP}/Contents/MacOS/Obsidian" >/dev/null 2>&1; then
    return 0
  fi

  log "Launching Obsidian for vault dependency"
  /usr/bin/open -a "$OBSIDIAN_APP" "$VAULT_PATH" >/dev/null 2>&1 || /usr/bin/open -a "$OBSIDIAN_APP" >/dev/null 2>&1 || true
  return 0
}

wait_for_port() {
  local host="$1"
  local port="$2"
  local timeout="$3"
  local label="$4"
  local waited=0

  while ! /usr/bin/nc -z "$host" "$port" >/dev/null 2>&1; do
    if (( waited == 0 || waited % 10 == 0 )); then
      log "Waiting for $label on $host:$port"
    fi
    if (( waited >= timeout )); then
      log "Timed out waiting for $label on $host:$port"
      return 1
    fi
    sleep 1
    (( waited += 1 ))
    ensure_obsidian_running >/dev/null 2>&1 || true
  done

  log "$label is ready on $host:$port"
  return 0
}

start_mcp_server() {
  export PATH="$NODE_BIN_DIR:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  export NODE_ENV="development"
  export OBSIDIAN_API_KEY="$OBSIDIAN_API_KEY_DYNAMIC"
  export OBSIDIAN_BASE_URL="$OBSIDIAN_BASE_URL_DYNAMIC"
  export OBSIDIAN_VERIFY_SSL="$OBSIDIAN_VERIFY_SSL_DYNAMIC"
  export MCP_TRANSPORT_TYPE="http"
  export MCP_HTTP_HOST="$MCP_HTTP_HOST"
  export MCP_HTTP_PORT="$MCP_HTTP_PORT"
  export MCP_LOG_LEVEL="info"

  : > "$LOG_DIR/mcp-server.log"
  "$MCP_BIN" >> "$LOG_DIR/mcp-server.log" 2>&1 &
  MCP_PID=$!
  print -r -- "$MCP_PID" > "$STATE_DIR/mcp.pid"
  log "Started obsidian-mcp-server with pid $MCP_PID"
}

start_ngrok() {
  : > "$LOG_DIR/ngrok.log"
  "$NGROK_BIN" http "$MCP_HTTP_PORT" --url "$NGROK_URL" --log stdout --log-format logfmt >> "$LOG_DIR/ngrok.log" 2>&1 &
  NGROK_PID=$!
  print -r -- "$NGROK_PID" > "$STATE_DIR/ngrok.pid"
  print -r -- "$NGROK_URL/mcp" > "$STATE_DIR/public-mcp-url.txt"
  log "Started ngrok with pid $NGROK_PID"
}

stop_children() {
  cleanup
  rm -f "$STATE_DIR/mcp.pid" "$STATE_DIR/ngrok.pid"
}

main() {
  acquire_lock || exit 0

  NODE_BIN_DIR="$(resolve_node_bin_dir)" || {
    log "Unable to resolve an nvm node installation"
    exit 1
  }

  assert_commands || exit 1

  while true; do
    stop_children

    read_local_rest_settings || {
      sleep 5
      continue
    }

    ensure_obsidian_running
    wait_for_port "$REST_HOST" "$REST_PORT" 180 "Obsidian Local REST API" || {
      sleep 5
      continue
    }

    start_mcp_server
    wait_for_port "$MCP_HTTP_HOST" "$MCP_HTTP_PORT" 60 "Obsidian MCP HTTP transport" || {
      log "MCP server failed to become ready"
      sleep 5
      continue
    }

    start_ngrok
    sleep 3
    if ! kill -0 "$NGROK_PID" 2>/dev/null; then
      log "ngrok exited during startup"
      sleep 5
      continue
    fi

    log "Stack healthy. Public MCP URL: $NGROK_URL/mcp"

    while true; do
      sleep 5
      if ! /usr/bin/pgrep -f "${OBSIDIAN_APP}/Contents/MacOS/Obsidian" >/dev/null 2>&1; then
        log "Obsidian is no longer running; restarting stack"
        break
      fi
      if ! /usr/bin/nc -z "$REST_HOST" "$REST_PORT" >/dev/null 2>&1; then
        log "Obsidian Local REST API is no longer reachable; restarting stack"
        break
      fi
      if ! kill -0 "$MCP_PID" 2>/dev/null; then
        log "obsidian-mcp-server exited; restarting stack"
        break
      fi
      if ! kill -0 "$NGROK_PID" 2>/dev/null; then
        log "ngrok exited; restarting stack"
        break
      fi
    done

    stop_children
    sleep 3
  done
}

main "$@"
