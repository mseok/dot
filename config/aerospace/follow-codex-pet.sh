#!/usr/bin/env bash
set -euo pipefail

# Codex Pet is rendered as a native ChatGPT popup outside AeroSpace's managed
# workspace tree. Its Accessibility coordinates do not control the rendered
# overlay, so leave it untouched until ChatGPT exposes a supported placement API.
#
# The workspace-change callback intentionally remains a no-op. Keeping it avoids
# changing any unrelated workspace hooks while preventing stray popup movement.
exit 0
