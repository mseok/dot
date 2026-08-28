#!/bin/zsh
set -euo pipefail

service="${OBSIDIAN_GATEWAY_KEYCHAIN_SERVICE:-local.obsidian-mcp-gateway.tokens}"
host="${OBSIDIAN_GATEWAY_HOST:-local}"
export OBSIDIAN_GATEWAY_TOKEN="$(/usr/bin/security find-generic-password -w -s "$service" -a "$host")"
export OBSIDIAN_GATEWAY_URL="${OBSIDIAN_GATEWAY_URL:-http://127.0.0.1:39123}"

if [[ -z "${OBSIDIAN_UPLOAD_ROOTS:-}" ]]; then
  print -u2 -- "OBSIDIAN_UPLOAD_ROOTS must be set by the MCP configuration."
  exit 1
fi

exec /opt/homebrew/bin/node /Volumes/ExternalSSD/Services/obsidian-mcp/app/src/bridge.mjs
