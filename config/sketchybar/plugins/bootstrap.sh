#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/aerospace_helpers.sh"

LOCK_DIR="${TMPDIR:-/tmp}/sketchybar-aerospace-bootstrap.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$LOCK_DIR"' EXIT

if wait_for_aerospace 30 1; then
  sleep 2
  "$SKETCHYBAR_BIN" --reload
fi
