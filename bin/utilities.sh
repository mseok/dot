#!/bin/bash

# Universal local/remote copy-to-clipboard (works even without base64/tr)
_copy_to_local_clipboard() {
  local text="$1"

  # 1) Prefer local clipboard commands
  for cmd in pbcopy wl-copy xclip xsel; do
    if command -v "$cmd" >/dev/null 2>&1; then
      case $cmd in
        pbcopy) printf "%s" "$text" | pbcopy ;;
        wl-copy) printf "%s" "$text" | wl-copy ;;
        xclip) printf "%s" "$text" | xclip -selection clipboard ;;
        xsel) printf "%s" "$text" | xsel --clipboard --input ;;
      esac
      return 0
    fi
  done

  # 2) If we're in a terminal that supports OSC52 (VSCode, iTerm2, WezTerm)
  # Try to generate base64 safely without depending on external tools
  local encoded
  if command -v base64 >/dev/null 2>&1; then
    encoded="$(printf "%s" "$text" | base64 | tr -d '\n' 2>/dev/null)"
  elif python3 -c "import base64" 2>/dev/null; then
    encoded="$(python3 -c "import base64,sys;print(base64.b64encode(sys.argv[1].encode()).decode(), end='')" "$text")"
  else
    encoded="$text"
  fi

  local osc52=$'\033]52;c;'"$encoded"$'\a'
  if [ -n "${TMUX:-}" ]; then
    osc52=$'\033Ptmux;\033'"$osc52"$'\033\\'
  fi
  printf "%s" "$osc52"
  return 0
}

copycwd() {
  if _copy_to_local_clipboard "$(echo $PWD)"; then
    echo "📋 Copied to clipboard: $(echo $PWD)"
  else
    printf "%s\n" "$(echo $PWD)"
  fi
}
