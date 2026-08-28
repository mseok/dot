#!/bin/sh
set -eu

secret_dir="${OBSIDIAN_GATEWAY_SECRET_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-mcp}"
token_file="${OBSIDIAN_GATEWAY_TOKEN_FILE:-$secret_dir/token}"
if [ -L "$secret_dir" ] || [ ! -d "$secret_dir" ] || [ "$(/usr/bin/stat -c %a "$secret_dir")" != "700" ]; then
  echo "Gateway secret directory must exist, not be a symlink, and have mode 0700: $secret_dir" >&2
  exit 1
fi
if [ -L "$token_file" ] || [ ! -f "$token_file" ] || [ "$(/usr/bin/stat -c %a "$token_file")" != "600" ]; then
  echo "Gateway token file must be a regular non-symlink file with mode 0600: $token_file" >&2
  exit 1
fi
export OBSIDIAN_GATEWAY_TOKEN_FILE="$token_file"

if command -v ip >/dev/null 2>&1 && ! ip -6 route show default 2>/dev/null | grep -q .; then
  case " ${RES_OPTIONS:-} " in
    *" no-aaaa "*) ;;
    *) RES_OPTIONS="${RES_OPTIONS:+$RES_OPTIONS }no-aaaa"; export RES_OPTIONS ;;
  esac
fi

if [ -z "${OBSIDIAN_GATEWAY_URL:-}" ] || [ -z "${OBSIDIAN_UPLOAD_ROOTS:-}" ]; then
  echo "OBSIDIAN_GATEWAY_URL and OBSIDIAN_UPLOAD_ROOTS are required." >&2
  exit 1
fi

bridge_node="${OBSIDIAN_BRIDGE_NODE:-node}"
bridge_path="${OBSIDIAN_BRIDGE_PATH:-$HOME/.local/share/obsidian-mcp-gateway/src/bridge.mjs}"
exec "$bridge_node" "$bridge_path"
