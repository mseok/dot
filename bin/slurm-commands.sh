#!/bin/bash

qq() {
  local width TAB=$'\t'

  # Calculate width based on filtered jobs by passing arguments ($@) here too
  # Added quoting "$@" which is good practice
  # Added handling for case where no jobs match the filter
  width=$(squeue -h -o "%j" "$@" | awk 'length>m{m=length} END{print m}')
  if [[ -z "$width" ]]; then
    width=10 # Default width if no jobs found
  fi

  # Pass function arguments "$@" to the main squeue command
  # Place "$@" before your fixed options like --sort and -o
  squeue "$@" --sort=i -o "%i${TAB}%${width}j${TAB}%u${TAB}%T${TAB}%M${TAB}%D${TAB}%R${TAB}%P${TAB}%Q" | column -s $'\t' -t
}

__scancel() {
  [[ -z $1 ]] && { echo "Usage: scancel_name <phrase>"; return 1; }
  squeue -h -o "%i %j" \
    | grep -F "$1" \
    | awk '{print $1}' \
    | xargs --no-run-if-empty scancel
}
