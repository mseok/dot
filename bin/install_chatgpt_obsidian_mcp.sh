#!/usr/bin/env bash
# Purpose: Install the ChatGPT <-> Obsidian MCP stack managed by launchd
# Usage: bash $HOME/dot/bin/install_chatgpt_obsidian_mcp.sh

set -euo pipefail

log()   { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

DOT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$DOT_HOME/config/chatgpt-obsidian-mcp"
APP_DIR="$HOME/Library/Application Support/chatgpt-obsidian-mcp"
BIN_DIR="$APP_DIR/bin"
LOG_DIR="$APP_DIR/logs"
STATE_DIR="$APP_DIR/state"
PLIST_LABEL="local.chatgpt-obsidian-mcp"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
PACKAGE_VERSION="2.0.7"

resolve_nvm_bin() {
  python3 - <<'PY'
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
if candidates:
    candidates.sort()
    print(candidates[-1][1])
PY
}

ensure_npm_on_path() {
  if exists npm && exists node; then
    return 0
  fi

  local nvm_bin
  nvm_bin="$(resolve_nvm_bin || true)"
  if [[ -n "$nvm_bin" ]]; then
    export PATH="$nvm_bin:$PATH"
  fi

  exists npm && exists node
}

render_plist() {
  python3 - <<'PY' "$TEMPLATE_DIR/chatgpt-obsidian-mcp.plist.template" "$PLIST_DEST" "$PLIST_LABEL" "$APP_DIR"
from pathlib import Path
import sys

template_path, output_path, label, app_dir = sys.argv[1:5]
text = Path(template_path).read_text()
text = text.replace("__LABEL__", label)
text = text.replace("__APP_DIR__", app_dir)
Path(output_path).write_text(text)
PY
}

main() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This installer only supports macOS."
    exit 1
  fi

  if [[ ! -d "$TEMPLATE_DIR" ]]; then
    error "Template directory not found: $TEMPLATE_DIR"
    exit 1
  fi

  if ! exists ngrok; then
    warn "ngrok is not installed. Install it first with:"
    warn "  brew install ngrok"
  fi

  if ! ensure_npm_on_path; then
    error "node/npm not found. Run $HOME/dot/bin/setup_macos.sh first or install Node.js."
    exit 1
  fi

  mkdir -p "$BIN_DIR" "$LOG_DIR" "$STATE_DIR" "$HOME/Library/LaunchAgents"

  log "Copying launchd-managed MCP scripts..."
  install -m 755 "$TEMPLATE_DIR/supervisor.zsh" "$BIN_DIR/supervisor.zsh"
  install -m 755 "$TEMPLATE_DIR/status.zsh" "$BIN_DIR/status.zsh"
  install -m 755 "$TEMPLATE_DIR/sync-local-rest-config.zsh" "$BIN_DIR/sync-local-rest-config.zsh"

  if [[ ! -f "$APP_DIR/settings.env" ]]; then
    install -m 644 "$TEMPLATE_DIR/settings.env.example" "$APP_DIR/settings.env"
    log "Created $APP_DIR/settings.env from template"
  else
    log "Preserved existing $APP_DIR/settings.env"
  fi

  log "Installing obsidian-mcp-server@$PACKAGE_VERSION into $APP_DIR"
  pushd "$APP_DIR" >/dev/null
  if [[ ! -f package.json ]]; then
    npm init -y >/dev/null
  fi
  npm install --save-exact "obsidian-mcp-server@$PACKAGE_VERSION"
  popd >/dev/null

  log "Rendering LaunchAgent plist"
  render_plist

  cat <<EOF

Install complete.

Next steps:
1. Edit:
   $APP_DIR/settings.env

2. Make sure Obsidian is installed and the community plugin
   "obsidian-local-rest-api" is enabled in your vault.

3. Add your ngrok authtoken if you have not already:
   ngrok config add-authtoken <TOKEN>

4. Sync the Local REST API key/port into launchd-readable state:
   $BIN_DIR/sync-local-rest-config.zsh

5. Load the LaunchAgent:
   launchctl unload "$PLIST_DEST" >/dev/null 2>&1 || true
   launchctl load -w "$PLIST_DEST"

6. Verify status:
   $BIN_DIR/status.zsh

7. Register the public MCP URL in ChatGPT:
   \${NGROK_URL}/mcp

Notes:
- local-rest.env contains the Obsidian API key and is intentionally kept out of git.
- If the Local REST API key or port changes, rerun:
  $BIN_DIR/sync-local-rest-config.zsh

EOF
}

main "$@"
