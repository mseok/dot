#!/usr/bin/env bash
# English comments as requested.
set -euo pipefail

# Read hook JSON from stdin to get transcript_path (provided by Stop hook).
INPUT="$(cat)"
TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path')"

# Collect all edited Python files in this turn, uniq, then run pre-commit once.
# (Select only Write/Edit/MultiEdit entries; walk for nested .file_path)
mapfile -t FILES < <(
  jq -r '
    select(.tool_name|test("^(Write|Edit|MultiEdit)$"))      # only file-changing tools
    | .tool_input
    | .. | .file_path?                                       # any nested .file_path
    | select(. != null and test("\\.py$"))
  ' "$TRANSCRIPT_PATH" | sort -u
)

# If nothing to lint, exit quietly.
((${#FILES[@]})) || exit 0

# Run your pre-commit one time for all files.
uvx pre-commit run \
  -c "$HOME/.config/git/template/hooks/.pre-commit-config.yaml" \
  --files "${FILES[@]}"
