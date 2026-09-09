#!/usr/bin/env bash

set -u

day_start=7
night_start=19

theme_for_time() {
  local hour
  hour="$(date +%H)"
  hour=$((10#$hour))

  if (( hour >= day_start && hour < night_start )); then
    printf '%s\n' latte
  else
    printf '%s\n' mocha
  fi
}

apply_theme() {
  local flavour current plugin_root plugin
  tmux list-sessions >/dev/null 2>&1 || return 0

  flavour="$(theme_for_time)"
  plugin_root="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}"
  plugin="${plugin_root%/}/tmux/catppuccin.tmux"

  [[ -r "$plugin" ]] || return 0

  current="$(tmux show-option -gqv @catppuccin_flavour 2>/dev/null || true)"
  [[ "$current" == "$flavour" ]] && return 0

  tmux set-option -g @catppuccin_flavour "$flavour"
  tmux source-file "$plugin"
}

watch_theme() {
  local watcher
  watcher="$(tmux show-option -gqv @dot_time_theme_watcher 2>/dev/null || true)"
  [[ "$watcher" == 1 ]] && return 0

  tmux set-option -g @dot_time_theme_watcher 1
  trap 'tmux set-option -gu @dot_time_theme_watcher 2>/dev/null || true' EXIT

  while tmux list-sessions >/dev/null 2>&1; do
    apply_theme >/dev/null 2>&1 || true
    sleep 60
  done
}

if ! command -v tmux >/dev/null 2>&1; then
  exit 0
fi

if [[ "${1:-}" == "--watch" ]]; then
  watch_theme
else
  apply_theme
fi
