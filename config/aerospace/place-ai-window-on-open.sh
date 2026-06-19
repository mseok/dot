#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
AEROSPACE_BIN="${AEROSPACE_BIN:-$(command -v aerospace || true)}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

target_workspace="${AI_APPS_WORKSPACE:-5}"
window_id="${AEROSPACE_WINDOW_ID:-}"

if [[ -z "$target_workspace" || -z "$window_id" ]]; then
  exit 0
fi

version="$("$AEROSPACE_BIN" --version 2>/dev/null || true)"
if [[ "$version" == *"server version: Unknown"* ]] || [[ "$version" == *"server is not running"* ]]; then
  exit 0
fi

is_codex_pet_window() {
  local debug="$1"

  if [[ "$debug" == *'"AXSubrole" : "AXDialog"'* ]] &&
     { [[ "$debug" == *'"Aero.windowLevel" : "{\"alwaysOnTopWindow\":{}}"'* ]] ||
       [[ "$debug" == *'"Aero.windowLevel" : "alwaysOnTopWindow"'* ]]; }; then
    return 0
  fi

  [[ "$debug" == *'"AXSubrole" : "AXStandardWindow"'* ]] || return 1
  [[ "$debug" == *'"AXTitle" : "Codex"'* ]] || return 1

  local width="" height=""
  if [[ "$debug" =~ w[[:space:]]*[:=][[:space:]]*([0-9]+)(\.[0-9]+)?[[:space:]]+h[[:space:]]*[:=][[:space:]]*([0-9]+)(\.[0-9]+)? ]]; then
    width="${BASH_REMATCH[1]}"
    height="${BASH_REMATCH[3]}"
  elif [[ "$debug" =~ width[[:space:]]*=[[:space:]]*([0-9]+)(\.[0-9]+)?[^0-9]+height[[:space:]]*=[[:space:]]*([0-9]+)(\.[0-9]+)? ]]; then
    width="${BASH_REMATCH[1]}"
    height="${BASH_REMATCH[3]}"
  fi

  [[ -n "$width" && -n "$height" ]] || return 1
  (( width >= 280 && width <= 520 && height >= 240 && height <= 440 ))
}

debug="$("$AEROSPACE_BIN" debug-windows --window-id "$window_id" 2>/dev/null || true)"
if is_codex_pet_window "$debug"; then
  focused_workspace="${AEROSPACE_FOCUSED_WORKSPACE:-}"
  if [[ -z "$focused_workspace" ]]; then
    focused_workspace="$("$AEROSPACE_BIN" list-workspaces --focused 2>/dev/null || true)"
  fi

  if [[ -n "$focused_workspace" && "${AEROSPACE_WORKSPACE:-}" != "$focused_workspace" ]]; then
    "$AEROSPACE_BIN" move-node-to-workspace --window-id "$window_id" "$focused_workspace" >/dev/null 2>&1 || true
  fi
  exit 0
fi

"$AEROSPACE_BIN" move-node-to-workspace --window-id "$window_id" "$target_workspace" >/dev/null 2>&1 || true
