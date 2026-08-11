#!/usr/bin/env bash
# Install the pinned AeroSpace fork required by the Codex Pet overlay config.

set -euo pipefail

readonly AEROSPACE_FORK_VERSION="0.20.3-Beta-fork.8"
readonly AEROSPACE_FORK_URL="https://github.com/vitorebatista/AeroSpace/releases/download/v${AEROSPACE_FORK_VERSION}/AeroSpace-v${AEROSPACE_FORK_VERSION}.zip"
readonly AEROSPACE_FORK_SHA256="c19ecce7641f299f3cb56d5d53fa2725ed7efbc932fcf5929d404660b4c4360c"

if [[ -n "${HOMEBREW_PREFIX:-}" ]]; then
  brew_prefix="$HOMEBREW_PREFIX"
elif command -v brew >/dev/null 2>&1; then
  brew_prefix="$(brew --prefix)"
else
  brew_prefix="/opt/homebrew"
fi

app_path="${AEROSPACE_APP_PATH:-/Applications/AeroSpace.app}"
cli_path="${AEROSPACE_CLI_PATH:-$brew_prefix/bin/aerospace-fork.8}"
cli_link="${AEROSPACE_CLI_LINK:-$brew_prefix/bin/aerospace}"
archive_override="${AEROSPACE_FORK_ARCHIVE:-}"

log() {
  printf '[aerospace-fork] %s\n' "$*"
}

die() {
  printf '[aerospace-fork] error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

installed_app_version() {
  plutil -extract CFBundleShortVersionString raw -o - \
    "$app_path/Contents/Info.plist" 2>/dev/null || true
}

has_expected_install() {
  [[ -x "$cli_path" ]] || return 1
  [[ "$(installed_app_version)" == "$AEROSPACE_FORK_VERSION" ]] || return 1
  [[ "$("$cli_path" --version 2>/dev/null || true)" == *"$AEROSPACE_FORK_VERSION"* ]] || return 1
  [[ "$("$cli_path" layout --help 2>/dev/null || true)" == *"sticky"* ]] || return 1
  [[ -L "$cli_link" && "$(readlink "$cli_link" 2>/dev/null || true)" == "$cli_path" ]] || return 1
}

backup_existing() {
  local target="$1"
  local timestamp
  local backup

  [[ -e "$target" || -L "$target" ]] || return 0

  timestamp="$(date +%Y%m%d_%H%M%S)"
  backup="${target}.backup_${timestamp}"
  mv "$target" "$backup"
  log "backed up $target -> $backup"
}

require_command curl
require_command ditto
require_command find
require_command install
require_command plutil
require_command shasum
require_command unzip

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "this installer supports macOS only"
fi

if has_expected_install; then
  log "AeroSpace $AEROSPACE_FORK_VERSION with sticky support is already installed"
  exit 0
fi

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/aerospace-pet-fork.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

archive_path="$work_dir/AeroSpace.zip"
if [[ -n "$archive_override" ]]; then
  [[ -f "$archive_override" ]] || die "archive not found: $archive_override"
  cp "$archive_override" "$archive_path"
else
  log "downloading AeroSpace $AEROSPACE_FORK_VERSION"
  curl --fail --location --retry 3 --silent --show-error \
    "$AEROSPACE_FORK_URL" -o "$archive_path"
fi

actual_sha256="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
[[ "$actual_sha256" == "$AEROSPACE_FORK_SHA256" ]] || \
  die "SHA-256 mismatch: expected $AEROSPACE_FORK_SHA256, got $actual_sha256"

extract_dir="$work_dir/extracted"
mkdir -p "$extract_dir"
unzip -q "$archive_path" -d "$extract_dir"

app_source="$(find "$extract_dir" -type d -name 'AeroSpace.app' -print -quit)"
cli_source="$(find "$extract_dir" -type f -path '*/bin/aerospace' -print -quit)"
[[ -n "$app_source" ]] || die "AeroSpace.app was not found in the release archive"
[[ -n "$cli_source" ]] || die "aerospace CLI was not found in the release archive"

mkdir -p "$(dirname "$app_path")" "$(dirname "$cli_path")" "$(dirname "$cli_link")"
backup_existing "$app_path"
ditto "$app_source" "$app_path"

backup_existing "$cli_path"
install -m 755 "$cli_source" "$cli_path"

if [[ -L "$cli_link" && "$(readlink "$cli_link" 2>/dev/null || true)" == "$cli_path" ]]; then
  :
else
  backup_existing "$cli_link"
  ln -s "$cli_path" "$cli_link"
fi

has_expected_install || die "AeroSpace fork installation verification failed"

log "installed AeroSpace $AEROSPACE_FORK_VERSION"
log "re-enable AeroSpace under System Settings > Privacy & Security > Accessibility if macOS requests it"
