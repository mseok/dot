#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/aerospace_helpers.sh"

# Events are queued in PENDING_FILE and drained by a single lock holder, so a
# burst of events or a slow AeroSpace server runs at most one query at a time.
LOCK_DIR="${TMPDIR:-/tmp}/sketchybar-space-windows.lock"
PENDING_FILE="${LOCK_DIR}.pending"

refresh_workspace() {
  local sid="$1"

  [ -n "$sid" ] || return 0
  sketchybar_item_exists "space.$sid" || return 0
  sync_space_item "$sid"
}

drain_requests() {
  local work="$LOCK_DIR/work"
  local token
  local focused

  while [ -s "$PENDING_FILE" ]; do
    mv "$PENDING_FILE" "$work" 2>/dev/null || return 0
    if ! aerospace_ready; then
      rm -f "$work"
      continue
    fi

    if grep -qx all "$work"; then
      sync_all_spaces
    else
      for token in $(sort -u "$work"); do
        if [ "$token" = focused ]; then
          focused="$(aerospace_cmd list-workspaces --focused 2>/dev/null)" || continue
          refresh_workspace "$focused"
        else
          refresh_workspace "$token"
        fi
      done
    fi
    rm -f "$work"
  done
}

lock_is_stale() {
  local pid

  pid="$(cat "$LOCK_DIR/pid" 2>/dev/null)"
  if [ -n "$pid" ]; then
    ! kill -0 "$pid" 2>/dev/null
  else
    # A holder killed before writing its pid leaves an empty lock behind.
    [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin +1 2>/dev/null)" ]
  fi
}

case "$SENDER" in
  aerospace_monitor_change)
    printf 'all\n' >> "$PENDING_FILE"
    ;;
  aerospace_workspace_change)
    {
      [ -z "$PREV_WORKSPACE" ] || printf '%s\n' "$PREV_WORKSPACE"
      [ -z "$FOCUSED_WORKSPACE" ] || printf '%s\n' "$FOCUSED_WORKSPACE"
    } >> "$PENDING_FILE"
    ;;
  *)
    printf 'focused\n' >> "$PENDING_FILE"
    ;;
esac

while :; do
  if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    if lock_is_stale; then
      rm -rf "$LOCK_DIR"
      continue
    fi
    # The running holder will pick up the request appended above.
    exit 0
  fi

  trap 'rm -rf "$LOCK_DIR"' EXIT
  printf '%s\n' "$$" > "$LOCK_DIR/pid"
  drain_requests
  rm -rf "$LOCK_DIR"
  trap - EXIT

  # Re-check for a request that arrived after the last drain but before unlock.
  [ -s "$PENDING_FILE" ] || break
done
