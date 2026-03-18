#!/bin/zsh

set -u

BASE="$HOME/Library/Application Support/chatgpt-obsidian-mcp"
STATE_DIR="$BASE/state"
SETTINGS_FILE="$BASE/settings.env"
LOCAL_REST_ENV_FILE="$BASE/local-rest.env"
PLIST_LABEL="local.chatgpt-obsidian-mcp"

source "$SETTINGS_FILE"
[[ -f "$LOCAL_REST_ENV_FILE" ]] && source "$LOCAL_REST_ENV_FILE"

print "LaunchAgent label: $PLIST_LABEL"
print "Vault path: $VAULT_PATH"
print "Configured public MCP URL: $NGROK_URL/mcp"
print ""

print "Launchctl:"
/bin/launchctl list | /usr/bin/grep "$PLIST_LABEL" || print "not loaded"
print ""

print "Obsidian:"
if /usr/bin/pgrep -f "${OBSIDIAN_APP}/Contents/MacOS/Obsidian" >/dev/null 2>&1; then
  print "running"
else
  print "not running"
fi

print "REST API:"
if [[ -n "${REST_PORT:-}" ]]; then
  if /usr/bin/nc -z 127.0.0.1 "$REST_PORT" >/dev/null 2>&1; then
    print "listening on 127.0.0.1:$REST_PORT"
  else
    print "not reachable on 127.0.0.1:$REST_PORT"
  fi
else
  print "local-rest.env missing or incomplete"
fi

print "MCP HTTP:"
if /usr/bin/nc -z "$MCP_HTTP_HOST" "$MCP_HTTP_PORT" >/dev/null 2>&1; then
  print "listening on $MCP_HTTP_HOST:$MCP_HTTP_PORT"
else
  print "not reachable on $MCP_HTTP_HOST:$MCP_HTTP_PORT"
fi

print "Supervisor state files:"
/bin/ls -la "$STATE_DIR" 2>/dev/null || print "missing"
print ""
print "Config files:"
/bin/ls -la "$SETTINGS_FILE" "$LOCAL_REST_ENV_FILE" 2>/dev/null || true
