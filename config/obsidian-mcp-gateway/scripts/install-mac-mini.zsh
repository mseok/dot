#!/bin/zsh
set -euo pipefail

source_root="${0:A:h:h}"
runtime_root="/Volumes/ExternalSSD/Services/obsidian-mcp"
launch_agent="$HOME/Library/LaunchAgents/local.obsidian-mcp-gateway.plist"
log_root="$HOME/Library/Logs/obsidian-mcp-gateway"
mode="${1:-stage}"

if [[ "$mode" != "stage" && "$mode" != "activate" ]]; then
  print -u2 -- "usage: $0 [stage|activate]"
  exit 2
fi

if [[ ! -d "$source_root/node_modules/@modelcontextprotocol/sdk" ]]; then
  print -u2 -- "Run npm ci in $source_root before installing."
  exit 1
fi

/bin/mkdir -p \
  "$runtime_root/app" \
  "$runtime_root/state/logs" \
  "$runtime_root/state/previews" \
  "$log_root"

/usr/bin/rsync -a "$source_root/package.json" "$source_root/package-lock.json" "$runtime_root/app/"
/usr/bin/rsync -a "$source_root/src/" "$runtime_root/app/src/"
/usr/bin/rsync -a "$source_root/scripts/" "$runtime_root/app/scripts/"
/usr/bin/rsync -a "$source_root/node_modules/" "$runtime_root/app/node_modules/"
/bin/chmod -R go-rwx "$runtime_root"
/bin/chmod go-rwx "$log_root"

if [[ "$mode" == "activate" ]]; then
  if [[ ! -f "$runtime_root/state/journal.sqlite" ]]; then
    print -u2 -- "Refusing activation before the migrated main journal exists."
    exit 1
  fi
  /usr/bin/install -m 600 "$source_root/launchd/local.obsidian-mcp-gateway.plist" "$launch_agent"
  /bin/launchctl bootout "gui/$(/usr/bin/id -u)/local.obsidian-mcp-gateway" >/dev/null 2>&1 || true
  if ! /bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$launch_agent"; then
    /bin/sleep 1
    /bin/launchctl bootstrap "gui/$(/usr/bin/id -u)" "$launch_agent"
  fi
fi

print -r -- "installed source: $source_root"
print -r -- "installed runtime: $runtime_root"
print -r -- "LaunchAgent target: $launch_agent"
print -r -- "mode: $mode"
