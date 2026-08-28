#!/bin/sh
set -eu

host=${1:?usage: deploy-linux-client.sh <ssh-host>}
source_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ssh_options="-o BatchMode=yes -o ClearAllForwardings=yes -o ConnectTimeout=20"

# Stage a parallel client and migrate the already-provisioned pilot token into
# a durable mode-checked file without sending the token through this machine.
ssh $ssh_options "$host" 'set -eu
target="$HOME/.local/share/obsidian-mcp-gateway"
pilot="$HOME/.local/share/obsidian-mcp-pilot"
secret_dir="${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-mcp"
token_file="$secret_dir/token"
mkdir -p "$target" "$secret_dir"
chmod 0700 "$secret_dir"
if [ ! -d "$target/node_modules" ]; then
  [ -d "$pilot/node_modules" ] || { echo "pilot node_modules missing" >&2; exit 1; }
  cp -a "$pilot/node_modules" "$target/node_modules"
fi
if [ ! -f "$token_file" ]; then
  key_id=$(/usr/bin/keyctl search @u user obsidian-mcp-gateway-pilot-token)
  temporary="$secret_dir/.token.$$"
  umask 077
  /usr/bin/keyctl pipe "$key_id" >"$temporary"
  chmod 0600 "$temporary"
  mv "$temporary" "$token_file"
fi
[ ! -L "$secret_dir" ] && [ "$(/usr/bin/stat -c %a "$secret_dir")" = 700 ]
[ ! -L "$token_file" ] && [ -f "$token_file" ] && [ "$(/usr/bin/stat -c %a "$token_file")" = 600 ]
'

scp $ssh_options -q "$source_root/package.json" "$source_root/package-lock.json" "$host:.local/share/obsidian-mcp-gateway/"
scp $ssh_options -q -r "$source_root/src" "$source_root/scripts" "$host:.local/share/obsidian-mcp-gateway/"
ssh $ssh_options "$host" 'set -eu
chmod 0700 "$HOME/.local/share/obsidian-mcp-gateway/scripts/run-linux-bridge.sh"
printf "runtime=%s\nsecret_dir_mode=%s\ntoken_file_mode=%s\n" \
  "$HOME/.local/share/obsidian-mcp-gateway" \
  "$(/usr/bin/stat -c %a "${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-mcp")" \
  "$(/usr/bin/stat -c %a "${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-mcp/token")"
'
