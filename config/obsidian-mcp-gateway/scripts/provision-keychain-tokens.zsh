#!/bin/zsh
set -euo pipefail

service="${OBSIDIAN_GATEWAY_KEYCHAIN_SERVICE:-local.obsidian-mcp-gateway.tokens}"
copy_service="${OBSIDIAN_GATEWAY_COPY_KEYCHAIN_SERVICE:-local.obsidian-mcp-gateway-pilot.tokens}"

for host in local messi gpu22; do
  if /usr/bin/security find-generic-password -w -s "$service" -a "$host" >/dev/null 2>&1; then
    print -r -- "token already present: $host"
    continue
  fi
  if token="$(/usr/bin/security find-generic-password -w -s "$copy_service" -a "$host" 2>/dev/null)"; then
    origin="copied from rollback Keychain service"
  else
    token="$(/usr/bin/openssl rand -hex 32)"
    origin="newly generated"
  fi
  /usr/bin/security add-generic-password -U -s "$service" -a "$host" -w "$token" >/dev/null
  unset token
  print -r -- "token provisioned in Keychain: $host ($origin)"
done
