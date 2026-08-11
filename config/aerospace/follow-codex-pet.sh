#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
AEROSPACE_BIN="${AEROSPACE_BIN:-$(command -v aerospace || true)}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

lock_dir="${TMPDIR:-/tmp}/follow-codex-pet.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

version="$("$AEROSPACE_BIN" --version 2>/dev/null || true)"
if [[ "$version" == *"server version: Unknown"* ]] || [[ "$version" == *"server is not running"* ]]; then
  exit 0
fi

# Stable AeroSpace has no sticky windows. Never emulate sticky by moving Pet's
# individual composition layers: that breaks their native parent relationship.
if ! "$AEROSPACE_BIN" layout --help 2>/dev/null | grep -q 'sticky'; then
  exit 0
fi

windows="$("$AEROSPACE_BIN" list-windows --all --format '%{window-id}|%{workspace}|%{app-name}|%{window-title}' 2>/dev/null || true)"
if [[ -z "$windows" ]]; then
  exit 0
fi

is_codex_pet_window() {
  local debug="$1"

  # ChatGPT 26.803+ renders Pet as one root dialog plus several composition
  # surfaces. Mark every layer sticky so their native relationship is kept.
  if [[ "$debug" == *'"AXSubrole" : "AXDialog"'* ]] &&
     { [[ "$debug" == *'"AXTitle" : "Codex"'* ]] ||
       [[ "$debug" == *'"AXTitle" : "Codex Pet Composition Surface"'* ]]; }; then
    return 0
  fi

  # Current Codex builds expose the pet overlay as a small AXStandardWindow
  # titled "Codex". The main Codex window has the same title, so size is the
  # discriminant here. The observed overlay is 356x320; keep the range loose
  # for UI scale and future padding changes.
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

while IFS='|' read -r window_id workspace app_name _title; do
  [[ "$app_name" == "Codex" || "$app_name" == "ChatGPT" ]] || continue
  [[ -n "$window_id" ]] || continue

  debug="$("$AEROSPACE_BIN" debug-windows --window-id "$window_id" 2>/dev/null || true)"
  is_codex_pet_window "$debug" || continue

  "$AEROSPACE_BIN" layout --window-id "$window_id" sticky >/dev/null 2>&1 || true
done <<< "$windows"
