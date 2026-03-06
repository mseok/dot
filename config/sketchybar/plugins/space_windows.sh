#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/aerospace_helpers.sh"

refresh_workspace() {
  local sid="$1"

  [ -n "$sid" ] || return 0
  sketchybar_item_exists "space.$sid" || return 0
  sync_space_item "$sid"
}

aerospace_ready || exit 0

if [ "$SENDER" = "aerospace_monitor_change" ]; then
  sync_all_spaces
  exit 0
fi

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  refresh_workspace "$PREV_WORKSPACE"
  refresh_workspace "$FOCUSED_WORKSPACE"
  exit 0
fi

FOCUSED_WORKSPACE="$("$AEROSPACE_BIN" list-workspaces --focused 2>/dev/null)"
refresh_workspace "$FOCUSED_WORKSPACE"
