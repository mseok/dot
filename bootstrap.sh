#!/usr/bin/env bash
# Bootstrap the repository itself, then dispatch to the platform installer.
# This script is safe to use from `curl ... | bash`; it never overwrites a
# non-empty directory that is not already a dotfiles checkout.

set -euo pipefail

log()   { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

REPO_URL="${DOT_REPO_URL:-https://github.com/mseok/dot.git}"
DOT_BRANCH="${DOT_BRANCH:-main}"
DOT_HOME="${DOT_HOME:-$HOME/dot}"
DOT_ARCHIVE_URL="${DOT_ARCHIVE_URL:-https://github.com/mseok/dot/archive/refs/heads/${DOT_BRANCH}.tar.gz}"

download_to() {
  local url="$1" dest="$2"
  local tmp="${dest}.tmp.$$"
  if exists curl; then
    if ! curl -fsSL "$url" -o "$tmp"; then
      rm -f "$tmp"
      return 1
    fi
  elif exists wget; then
    if ! wget -qO "$tmp" "$url"; then
      rm -f "$tmp"
      return 1
    fi
  else
    error "Neither curl nor wget is available. Install one and rerun."
    exit 1
  fi
  mv -f "$tmp" "$dest"
}

if [[ -e "$DOT_HOME" ]]; then
  if [[ -d "$DOT_HOME/.git" ]]; then
    log "Using existing dotfiles checkout: $DOT_HOME"
  elif [[ -n "$(find "$DOT_HOME" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    error "Refusing to overwrite a non-empty non-repository directory: $DOT_HOME"
    error "Choose another location with DOT_HOME=/path/to/dot and rerun."
    exit 1
  else
    rmdir "$DOT_HOME"
  fi
fi

if [[ ! -d "$DOT_HOME/.git" ]]; then
  mkdir -p "$(dirname "$DOT_HOME")"
  if exists git; then
    log "Cloning $REPO_URL into $DOT_HOME..."
    git clone --depth 1 --branch "$DOT_BRANCH" "$REPO_URL" "$DOT_HOME"
  else
    if ! exists tar; then
      error "git and tar are both unavailable; cannot bootstrap the repository."
      exit 1
    fi
    local_tmp="$(mktemp -d "${TMPDIR:-/tmp}/dot-bootstrap.XXXXXX")"
    trap 'rm -rf "$local_tmp"' EXIT
    log "git is unavailable; downloading the repository archive..."
    download_to "$DOT_ARCHIVE_URL" "$local_tmp/dot.tar.gz"
    tar -xzf "$local_tmp/dot.tar.gz" -C "$local_tmp"
    source_dir="$(find "$local_tmp" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    if [[ -z "$source_dir" ]]; then
      error "The repository archive did not contain a top-level directory."
      exit 1
    fi
    mv "$source_dir" "$DOT_HOME"
    log "Repository archive extracted into $DOT_HOME"
  fi
fi

if [[ ! -f "$DOT_HOME/install.sh" ]]; then
  error "The checkout does not contain install.sh: $DOT_HOME"
  exit 1
fi

exec bash "$DOT_HOME/install.sh" "$@"
