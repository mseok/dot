#!/usr/bin/env bash
set -euo pipefail

target_workspace="${AEROSPACE_FOCUSED_WORKSPACE:-}"
if [[ -z "$target_workspace" ]]; then
  target_workspace="$(aerospace list-workspaces --focused 2>/dev/null || true)"
fi

if [[ -z "$target_workspace" ]]; then
  exit 0
fi

aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-name}|%{window-title}' |
while IFS='|' read -r window_id workspace app_name _title; do
  [[ "$app_name" == "Codex" ]] || continue
  [[ -n "$window_id" ]] || continue

  debug="$(aerospace debug-windows --window-id "$window_id" 2>/dev/null || true)"
  [[ "$debug" == *'"AXSubrole" : "AXDialog"'* ]] || continue
  [[ "$debug" == *'"Aero.windowLevel" : "{\"alwaysOnTopWindow\":{}}"'* ]] || continue

  if [[ "$workspace" != "$target_workspace" ]]; then
    aerospace move-node-to-workspace --window-id "$window_id" "$target_workspace" >/dev/null 2>&1 || true
  fi
done
