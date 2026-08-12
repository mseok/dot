#!/usr/bin/env bash
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
AEROSPACE_BIN="${AEROSPACE_BIN:-$(command -v aerospace || true)}"
if [[ -z "$AEROSPACE_BIN" ]]; then
  exit 0
fi

workspace="${AEROSPACE_TARGET_WORKSPACE:-7}"
monitor="${AEROSPACE_TARGET_MONITOR:-LG UltraFine}"

if "$AEROSPACE_BIN" list-monitors --format "%{monitor-name}" | grep -Fxq "$monitor"; then
  "$AEROSPACE_BIN" workspace "$workspace" >/dev/null 2>&1 || true
  "$AEROSPACE_BIN" focus-monitor "$monitor" >/dev/null 2>&1 || true
else
  "$AEROSPACE_BIN" summon-workspace "$workspace" >/dev/null 2>&1 || \
    "$AEROSPACE_BIN" workspace "$workspace" >/dev/null 2>&1 || true
fi
