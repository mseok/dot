#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
AEROSPACE_BIN="${AEROSPACE_BIN:-$(command -v aerospace || true)}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex-window.sh
source "$SCRIPT_DIR/codex-window.sh"

target_workspace="${AI_APPS_WORKSPACE:-5}"
window_id="${AEROSPACE_WINDOW_ID:-}"

if [[ -z "$target_workspace" || -z "$window_id" ]]; then
  exit 0
fi

version="$("$AEROSPACE_BIN" --version 2>/dev/null || true)"
if [[ "$version" == *"server version: Unknown"* ]] || [[ "$version" == *"server is not running"* ]]; then
  exit 0
fi

debug="$("$AEROSPACE_BIN" debug-windows --window-id "$window_id" 2>/dev/null || true)"
if is_codex_pet_window_debug "$debug"; then
  # Pet is a native popup rather than an AeroSpace-managed window. Move all of
  # its layers together through Accessibility instead of touching this one
  # layer with `layout` or `move-node-to-workspace`.
  "$SCRIPT_DIR/follow-codex-pet.sh" >/dev/null 2>&1 || true
  exit 0
fi

"$AEROSPACE_BIN" move-node-to-workspace --window-id "$window_id" "$target_workspace" >/dev/null 2>&1 || true
