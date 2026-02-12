#!/usr/bin/env bash
set -euo pipefail

default_target="sections/02_1_overview.tex"
input="${1:-}"

if ! command -v pbcopy >/dev/null 2>&1; then
  echo "Error: pbcopy is not available. This command requires macOS." >&2
  exit 1
fi

if [[ "$input" == "-" ]]; then
  pbcopy
  echo "Copied stdin to clipboard."
  exit 0
fi

target="${input:-$default_target}"

if [[ ! -f "$target" ]]; then
  echo "Error: file not found: $target" >&2
  exit 1
fi

pbcopy < "$target"
echo "Copied to clipboard: $target"
