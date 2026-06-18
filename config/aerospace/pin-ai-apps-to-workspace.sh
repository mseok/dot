#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
AEROSPACE_BIN="${AEROSPACE_BIN:-$(command -v aerospace || true)}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

lock_dir="${TMPDIR:-/tmp}/pin-ai-apps-to-workspace.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

target_workspace="${AI_APPS_WORKSPACE:-5}"
if [[ -z "$target_workspace" ]]; then
  exit 0
fi

focused_workspace="${AEROSPACE_FOCUSED_WORKSPACE:-}"
if [[ -z "$focused_workspace" ]]; then
  focused_workspace="$("$AEROSPACE_BIN" list-workspaces --focused 2>/dev/null || true)"
fi

version="$("$AEROSPACE_BIN" --version 2>/dev/null || true)"
if [[ "$version" == *"server version: Unknown"* ]] || [[ "$version" == *"server is not running"* ]]; then
  exit 0
fi

windows="$("$AEROSPACE_BIN" list-windows --all --format '%{window-id}|%{workspace}|%{app-name}|%{window-title}' 2>/dev/null || true)"
if [[ -z "$windows" ]]; then
  exit 0
fi

is_codex_pet_window() {
  local debug="$1"
  local width="" height=""

  [[ "$debug" == *'"Aero.windowLevel" : "alwaysOnTopWindow"'* ]] || return 1

  if [[ "$debug" =~ w[[:space:]]*[:=][[:space:]]*([0-9]+)(\.[0-9]+)?[[:space:]]+h[[:space:]]*[:=][[:space:]]*([0-9]+)(\.[0-9]+)? ]]; then
    width="${BASH_REMATCH[1]}"
    height="${BASH_REMATCH[3]}"
  fi

  [[ -n "$width" && -n "$height" ]] || return 1
  (( width >= 280 && width <= 520 && height >= 240 && height <= 440 ))
}

while IFS='|' read -r window_id workspace app_name _title; do
  case "$app_name" in
    Codex|Claude) ;;
    *) continue ;;
  esac

  [[ -n "$window_id" ]] || continue

  destination="$target_workspace"
  if [[ "$app_name" == "Codex" ]]; then
    debug="$("$AEROSPACE_BIN" debug-windows --window-id "$window_id" 2>/dev/null || true)"
    if [[ -n "$focused_workspace" ]] && is_codex_pet_window "$debug"; then
      destination="$focused_workspace"
    fi
  fi

  [[ "$workspace" == "$destination" ]] && continue

  "$AEROSPACE_BIN" move-node-to-workspace --window-id "$window_id" "$destination" >/dev/null 2>&1 || true
done <<< "$windows"
