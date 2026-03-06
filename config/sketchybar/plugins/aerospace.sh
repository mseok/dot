#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/aerospace_helpers.sh"

sketchybar_item_exists "$NAME" || exit 0

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  "$SKETCHYBAR_BIN" --set "$NAME" background.color=0x88FF00FF label.shadow.drawing=on icon.shadow.drawing=on background.border_width=2
else
  "$SKETCHYBAR_BIN" --set "$NAME" background.color=0x44FFFFFF label.shadow.drawing=off icon.shadow.drawing=off background.border_width=0
fi
