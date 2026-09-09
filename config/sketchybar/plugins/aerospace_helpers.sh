#!/usr/bin/env bash

if command -v brew >/dev/null 2>&1; then
  HOMEBREW_PREFIX="$(brew --prefix 2>/dev/null || printf '%s' /opt/homebrew)"
else
  HOMEBREW_PREFIX="/opt/homebrew"
fi
export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:/usr/bin:/bin:/usr/sbin:/sbin"

HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-${HELPER_DIR%/plugins}}"
PLUGIN_DIR="${PLUGIN_DIR:-$HELPER_DIR}"
SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-$HOMEBREW_PREFIX/bin/sketchybar}"

if [ -x "$HOMEBREW_PREFIX/bin/aerospace" ]; then
  AEROSPACE_BIN="${AEROSPACE_BIN:-$HOMEBREW_PREFIX/bin/aerospace}"
elif [ -x /Applications/AeroSpace.app/Contents/MacOS/AeroSpace ]; then
  AEROSPACE_BIN="${AEROSPACE_BIN:-/Applications/AeroSpace.app/Contents/MacOS/AeroSpace}"
else
  AEROSPACE_BIN="${AEROSPACE_BIN:-aerospace}"
fi

export CONFIG_DIR
export PLUGIN_DIR
export SKETCHYBAR_BIN
export AEROSPACE_BIN

aerospace_ready() {
  [ -x "$AEROSPACE_BIN" ] && "$AEROSPACE_BIN" list-workspaces --focused >/dev/null 2>&1
}

wait_for_aerospace() {
  local retries="${1:-20}"
  local delay="${2:-1}"
  local attempt

  attempt=1
  while [ "$attempt" -le "$retries" ]; do
    if aerospace_ready; then
      return 0
    fi
    sleep "$delay"
    attempt=$((attempt + 1))
  done

  return 1
}

sketchybar_item_exists() {
  "$SKETCHYBAR_BIN" --query "$1" >/dev/null 2>&1
}

workspace_ids() {
  "$AEROSPACE_BIN" list-workspaces --all 2>/dev/null
}

monitor_ids() {
  "$AEROSPACE_BIN" list-monitors 2>/dev/null | awk 'NF { print $1 }'
}

all_display_ids() {
  local ids

  ids="$(monitor_ids | paste -sd, -)"
  printf '%s\n' "${ids:-1}"
}

workspaces_for_monitor() {
  "$AEROSPACE_BIN" list-workspaces --monitor "$1" 2>/dev/null
}

workspace_apps() {
  local sid="$1"
  local app_name

  "$AEROSPACE_BIN" list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null |
    while IFS= read -r app_name; do
      app_name="$(trim_spaces "$app_name")"
      [ -n "$app_name" ] || continue
      printf '%s\n' "$app_name"
    done
}

trim_spaces() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

build_icon_strip() {
  local apps="$1"
  local icon_strip=""
  local app
  local icon

  if [ -z "$apps" ]; then
    printf '\n'
    return 0
  fi

  while IFS= read -r app; do
    [ -n "$app" ] || continue
    icon="$(trim_spaces "$("${CONFIG_DIR}/plugins/icon_map_fn.sh" "$app")")"
    [ -n "$icon" ] || continue
    icon_strip="${icon_strip} $icon"
  done <<< "$apps"

  printf '%s\n' "${icon_strip# }"
}

sync_space_item() {
  local sid="$1"
  local apps
  local icon_strip
  local display_target

  sketchybar_item_exists "space.$sid" || return 0
  display_target="$(all_display_ids)"

  apps="$(workspace_apps "$sid")"
  if [ -n "$apps" ]; then
    icon_strip="$(build_icon_strip "$apps")"
    "$SKETCHYBAR_BIN" --set "space.$sid" display="$display_target" drawing=on label="$icon_strip"
  else
    "$SKETCHYBAR_BIN" --set "space.$sid" display="$display_target" drawing=off label=""
  fi
}

sync_all_spaces() {
  local sid

  for sid in $(workspace_ids); do
    sketchybar_item_exists "space.$sid" || continue
    "$SKETCHYBAR_BIN" --set "space.$sid" drawing=off label=""
  done

  for sid in $(workspace_ids); do
    sync_space_item "$sid"
  done
}
