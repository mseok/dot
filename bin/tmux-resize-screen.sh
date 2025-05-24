#!/bin/bash
cmd="$(tmux display -p '#{pane_current_command}')"

tmux resize-pane -Z
if [[ "${cmd%m}" == *"vi"* ]]; then
  sleep 0.05
  tmux send-keys Escape
  tmux send-keys C-w =
fi
