#!/usr/bin/env bash
# Portable entrypoint for a fresh or existing installation.

set -euo pipefail

DOT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --upgrade             Upgrade managed applications while installing.
  --install-homebrew    Install Homebrew if it is missing on macOS.
  --yes                 Non-interactive Homebrew install attempt on macOS.
  --no-services         Do not start/relaunch macOS window-management apps.
  --skip-pixi           Skip Pixi and optional Yazi/image tools on Linux.
  --skip-npm            Skip global npm CLIs on Linux.
  --skip-shell          Do not edit ~/.bashrc or ~/.zshrc.
  --skip-codex          Do not install repository-managed Codex files.
  --codex-home PATH     Install Codex files under PATH instead of ~/.codex.
  --codex-override PATH Copy PATH to $CODEX_HOME/AGENTS.override.md.
  -h, --help            Show this help.

The installer only writes user-owned paths. Homebrew's initial installation
may still require the normal macOS administrator/password step.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --upgrade)
      export DOT_SETUP_UPGRADE=1 DOT_BOOTSTRAP_UPDATE=1
      ;;
    --install-homebrew)
      export DOT_SETUP_INSTALL_HOMEBREW=1
      ;;
    --yes)
      export DOT_ASSUME_YES=1 DOT_SETUP_INSTALL_HOMEBREW=1
      ;;
    --no-services)
      export DOT_SETUP_SKIP_SERVICES=1
      ;;
    --skip-pixi)
      export DOT_BOOTSTRAP_SKIP_PIXI=1
      ;;
    --skip-npm)
      export DOT_BOOTSTRAP_SKIP_NPM=1
      ;;
    --skip-shell)
      export DOT_BOOTSTRAP_SKIP_SHELL_RC=1
      ;;
    --skip-codex)
      export DOT_SKIP_CODEX=1
      ;;
    --codex-home)
      shift
      if (( $# == 0 )); then
        printf '%s\n' '--codex-home requires a path.' >&2
        exit 2
      fi
      export CODEX_HOME="$1"
      ;;
    --codex-override)
      shift
      if (( $# == 0 )); then
        printf '%s\n' '--codex-override requires a path.' >&2
        exit 2
      fi
      export DOT_CODEX_OVERRIDE_SOURCE="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

export DOTFILES_HOME="$DOT_HOME"

case "$(uname -s)" in
  Darwin)
    bash "$DOT_HOME/bin/setup_macos.sh"
    ;;
  Linux)
    bash "$DOT_HOME/bin/initialize_ubuntu.sh"
    ;;
  *)
    printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac

if [[ "${DOT_SKIP_CODEX:-0}" == "1" ]]; then
  printf '\033[1;33m[WARN]\033[0m Skipping repository-managed Codex files.\n'
else
  codex_args=()
  if [[ "$(uname -s)" == "Linux" ]]; then
    codex_args+=(--hpc)
  fi
  bash "$DOT_HOME/bin/install_codex.sh" "${codex_args[@]}"
fi
