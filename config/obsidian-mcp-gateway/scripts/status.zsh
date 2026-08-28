#!/bin/zsh
set -euo pipefail

label="local.obsidian-mcp-gateway"
print -r -- "LaunchAgent:"
/bin/launchctl print "gui/$(/usr/bin/id -u)/$label" 2>&1 | /usr/bin/grep -E "state =|pid =|last exit code" || true
print -r -- "Health:"
/usr/bin/curl -fsS http://127.0.0.1:39123/healthz
print
print -r -- "Listener:"
/usr/sbin/lsof -nP -iTCP:39123 -sTCP:LISTEN || true
