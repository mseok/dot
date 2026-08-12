#!/usr/bin/env bash

# Keep Codex/ChatGPT window matching independent of the app's display name.
# The July 2026 desktop update renamed Codex.app to ChatGPT.app while retaining
# the com.openai.codex bundle identifier.
CODEX_APP_BUNDLE_ID="${CODEX_APP_BUNDLE_ID:-com.openai.codex}"

is_codex_app_bundle_id() {
  [[ "${1:-}" == "$CODEX_APP_BUNDLE_ID" ]]
}

is_codex_pet_window_debug() {
  local debug="${1:-}"
  local width="" height=""

  [[ -n "$debug" ]] || return 1

  # ChatGPT 26.803+ exposes Pet as a root dialog plus composition/effect
  # popups. The title check remains narrow so the main ChatGPT window is never
  # reclassified as Pet.
  if { [[ "$debug" == *'"AXSubrole" : "AXDialog"'* ]] ||
       [[ "$debug" == *'"AXSubrole" : "AXSystemDialog"'* ]]; } &&
     { [[ "$debug" == *'"AXTitle" : "Codex"'* ]] ||
       [[ "$debug" == *'"AXTitle" : "Codex Pet '* ]]; }; then
    return 0
  fi

  # Other builds expose Pet as a small always-on-top standard window. The main
  # ChatGPT window is normalWindow, so retain the size and dialog heuristics as
  # a conservative fallback for that representation.
  { [[ "$debug" == *'"Aero.windowLevel" : "{\"alwaysOnTopWindow\":{}}"'* ]] ||
    [[ "$debug" == *'"Aero.windowLevel" : "alwaysOnTopWindow"'* ]]; } || return 1

  if [[ "$debug" =~ w[[:space:]]*[:=][[:space:]]*([0-9]+)(\.[0-9]+)?[[:space:]]+h[[:space:]]*[:=][[:space:]]*([0-9]+)(\.[0-9]+)? ]]; then
    width="${BASH_REMATCH[1]}"
    height="${BASH_REMATCH[3]}"
  elif [[ "$debug" =~ width[[:space:]]*=[[:space:]]*([0-9]+)(\.[0-9]+)?[^0-9]+height[[:space:]]*=[[:space:]]*([0-9]+)(\.[0-9]+)? ]]; then
    width="${BASH_REMATCH[1]}"
    height="${BASH_REMATCH[3]}"
  fi

  [[ -n "$width" && -n "$height" ]] || return 1
  (( width >= 280 && width <= 520 && height >= 240 && height <= 440 )) || return 1

  # Old builds exposed AXDialog. Current build 5440 exposes a chromeless
  # AXStandardWindow that AeroSpace identifies with its dialog heuristic.
  [[ "$debug" == *'"AXSubrole" : "AXDialog"'* ]] ||
    [[ "$debug" == *'"Aero.AxUiElementWindowType_isDialogHeuristic" : true'* ]] ||
    { [[ "$debug" == *'"AXCloseButton" : null'* ]] &&
      [[ "$debug" == *'"AXMinimizeButton" : null'* ]] &&
      [[ "$debug" == *'"AXFullScreenButton" : null'* ]]; }
}
