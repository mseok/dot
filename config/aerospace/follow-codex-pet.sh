#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
AEROSPACE_BIN="${AEROSPACE_BIN:-$(command -v aerospace || true)}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

lock_dir="${TMPDIR:-/tmp}/follow-codex-pet.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT

version="$("$AEROSPACE_BIN" --version 2>/dev/null || true)"
if [[ "$version" == *"server version: Unknown"* ]] || [[ "$version" == *"server is not running"* ]]; then
  exit 0
fi

focused_workspace="${AEROSPACE_FOCUSED_WORKSPACE:-}"
if [[ -z "$focused_workspace" ]]; then
  focused_workspace="$("$AEROSPACE_BIN" list-workspaces --focused 2>/dev/null || true)"
fi
if [[ -z "$focused_workspace" ]]; then
  exit 0
fi

target_monitor="$(
  "$AEROSPACE_BIN" list-workspaces --monitor all --visible --format '%{workspace}|%{monitor-name}' 2>/dev/null |
    awk -F'|' -v workspace="$focused_workspace" '$1 == workspace { print $2; exit }'
)"
if [[ -z "$target_monitor" ]]; then
  target_monitor="$("$AEROSPACE_BIN" list-monitors --focused --format '%{monitor-name}' 2>/dev/null || true)"
fi
if [[ -z "$target_monitor" ]]; then
  exit 0
fi

if [[ "${CODEX_PET_DEBUG:-0}" == "1" ]]; then
  AEROSPACE_TARGET_MONITOR="$target_monitor" \
    osascript -l JavaScript "$SCRIPT_DIR/move-codex-pet-to-monitor.js" || true
else
  AEROSPACE_TARGET_MONITOR="$target_monitor" \
    osascript -l JavaScript "$SCRIPT_DIR/move-codex-pet-to-monitor.js" >/dev/null 2>&1 || true
fi
