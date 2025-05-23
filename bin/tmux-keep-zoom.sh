#!/bin/bash
is_zoomed=$(tmux list-panes -F '#F' | grep Z | wc -l)

if [ "$1" == 'L' ]; then
  tmux select-pane -L
elif [ "$1" == 'D' ]; then
  tmux select-pane -D
elif [ "$1" == 'U' ]; then
  tmux select-pane -U
elif [ "$1" == 'R' ]; then
  tmux select-pane -R
fi

cmd="$(tmux display -p '#{pane_current_command}')"
cmd="$(basename "${cmd,,*}")"

if [ $is_zoomed -gt 0 ]; then
  tmux resize-pane -Z
  if [[ "${cmd%m}" == *"vi"* ]]; then
    sleep 0.05
    tmux send-keys Escape
    tmux send-keys C-w =
  fi
fi
