#!/bin/bash

qq() {
  local width TAB=$'\t'
  width=$(squeue -h -o "%j" | awk 'length>m{m=length} END{print m}')
  squeue --sort=i -o "%i${TAB}%${width}j${TAB}%u${TAB}%T${TAB}%M${TAB}%D${TAB}%R" | column -s $'\t' -t
}

__scancel() {
  [[ -z $1 ]] && { echo "Usage: scancel_name <phrase>"; return 1; }
  squeue -h -o "%i %j" \
    | grep -F "$1" \
    | awk '{print $1}' \
    | xargs --no-run-if-empty scancel
}
