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

version="$("$AEROSPACE_BIN" --version 2>/dev/null || true)"
if [[ "$version" == *"server version: Unknown"* ]] || [[ "$version" == *"server is not running"* ]]; then
  exit 0
fi

windows="$("$AEROSPACE_BIN" list-windows --all --format '%{window-id}|%{workspace}|%{app-name}|%{window-title}' 2>/dev/null || true)"
if [[ -z "$windows" ]]; then
  exit 0
fi

while IFS='|' read -r window_id workspace app_name _title; do
  case "$app_name" in
    Codex|Claude) ;;
    *) continue ;;
  esac

  [[ -n "$window_id" ]] || continue
  [[ "$workspace" == "$target_workspace" ]] && continue

  "$AEROSPACE_BIN" move-node-to-workspace --window-id "$window_id" "$target_workspace" >/dev/null 2>&1 || true
done <<< "$windows"
