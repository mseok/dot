#!/bin/zsh

# Focus change hook for app-specific input source switching.
# No-op unless macism is installed.

set -u

macism_bin=""
for candidate in /opt/homebrew/bin/macism /usr/local/bin/macism; do
  if [[ -x "$candidate" ]]; then
    macism_bin="$candidate"
    break
  fi
done

[[ -n "$macism_bin" ]] || exit 0

frontmost_app_id="$(
  /usr/bin/osascript \
    -e 'tell application "System Events" to get bundle identifier of first application process whose frontmost is true' \
    2>/dev/null
)"

[[ -n "$frontmost_app_id" ]] || exit 0

case "$frontmost_app_id" in
  com.apple.Terminal|com.googlecode.iterm2|com.github.wez.wezterm|com.mitchellh.ghostty)
    "$macism_bin" com.apple.keylayout.ABC >/dev/null 2>&1
    ;;
  com.openai.codex|com.openai.atlas)
    "$macism_bin" com.apple.inputmethod.Korean.2SetKorean >/dev/null 2>&1 || \
      "$macism_bin" com.apple.keylayout.2SetHangul >/dev/null 2>&1
    ;;
esac
