#!/usr/bin/env bash
# Update the checkout, managed applications, and (optionally) plugins.
#
# The default is read-only. Applying an update requires a clean Git worktree;
# this is deliberate because a dotfiles update must never hide local changes.

set -euo pipefail

DOT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_HOME="$DOT_HOME"
ACTION="check"
UPDATE_PLUGINS=0
START_SERVICES=0

log()   { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: bin/update_environment.sh [options]

Options:
  --check               Report versions and configuration health (default).
  --apply               Fast-forward the dotfiles checkout and update apps.
  --plugins             Also update Yazi and Neovim plugins.
  --with-services       Allow the macOS setup to start/relaunch services.
  -h, --help            Show this help.

The apply path refuses to run with tracked or untracked Git changes. Review,
commit, or safely stash those changes first. It never force-pulls or resets.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --check)
      ACTION="check"
      ;;
    --apply)
      ACTION="apply"
      ;;
    --plugins)
      UPDATE_PLUGINS=1
      ;;
    --with-services)
      START_SERVICES=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
  shift
done

version_line() {
  local label="$1" command_name="$2"
  shift 2
  if exists "$command_name"; then
    printf '%-14s %s\n' "$label" "$("$command_name" "$@" 2>&1 | sed -n '1p')"
  else
    printf '%-14s %s\n' "$label" 'missing'
  fi
}

check_worktree() {
  if [[ ! -d "$DOT_HOME/.git" ]]; then
    error "This checkout has no .git directory: $DOT_HOME"
    error "The archive bootstrap is install-only; use a Git checkout for updates."
    return 1
  fi

  local status
  status="$(git -C "$DOT_HOME" status --porcelain --untracked-files=all)"
  if [[ -n "$status" ]]; then
    error "Refusing to update a dirty checkout: $DOT_HOME"
    printf '%s\n' "$status" >&2
    error "Commit or safely stash these changes, then rerun --apply."
    return 1
  fi
}

check_package_state() {
  case "$(uname -s)" in
    Darwin)
      if exists brew; then
        if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file="$DOT_HOME/Brewfile" >/dev/null 2>&1; then
          log "Homebrew bundle: satisfied"
        else
          warn "Homebrew bundle: missing or mismatched dependencies"
        fi
        log "Homebrew outdated packages:"
        HOMEBREW_NO_AUTO_UPDATE=1 brew outdated || true
      else
        warn "Homebrew is not installed"
      fi
      ;;
    Linux)
      if exists pixi; then
        if [[ -n "${PIXI_HOME:-}" ]]; then
          PIXI_HOME="$PIXI_HOME" pixi global list --environment "${PIXI_ENVIRONMENT:-dot-terminal}" || true
        else
          pixi global list --environment "${PIXI_ENVIRONMENT:-dot-terminal}" || true
        fi
      else
        warn "Pixi is not installed; Linux image-preview tools may be missing"
      fi
      ;;
  esac
}

check_config_state() {
  if exists tmux; then
    local socket="dot-config-check-$$"
    if tmux -L "$socket" -f "$DOT_HOME/config/tmux/.tmux.conf" start-server >/dev/null 2>&1; then
      tmux -L "$socket" kill-server >/dev/null 2>&1 || true
      log "tmux config: OK"
    else
      warn "tmux config: could not start an isolated validation server"
      tmux -L "$socket" kill-server >/dev/null 2>&1 || true
    fi
  fi

  if [[ "$(uname -s)" == "Darwin" ]] && exists wezterm; then
    if wezterm show-keys --lua >/dev/null 2>&1; then
      log "WezTerm config: OK"
    else
      warn "WezTerm config: validation failed"
    fi
  fi

  if exists yazi; then
    version_line "Yazi" yazi --version
  fi
}

print_versions() {
  printf '\nManaged command versions\n'
  version_line "Neovim" nvim --version
  version_line "tmux" tmux -V
  version_line "Starship" starship --version
  version_line "Codex" codex --version
  version_line "Yazi" yazi --version
  version_line "fzf" fzf --version
  version_line "Tree-sitter" tree-sitter --version
  version_line "ripgrep" rg --version
  version_line "fd" fd --version
  version_line "Pixi" pixi --version
}

update_plugins() {
  if [[ "$UPDATE_PLUGINS" -ne 1 ]]; then
    return 0
  fi

  if exists ya && [[ -d "$HOME/.config/yazi" ]]; then
    log "Updating Yazi plugins..."
    if ! (cd "$HOME/.config/yazi" && ya pkg upgrade); then
      warn "Yazi plugin upgrade failed; keeping the existing plugin checkout."
    fi
    if ! (cd "$HOME/.config/yazi" && ya pkg install); then
      warn "Yazi plugin install/lock reconciliation failed."
    fi
  else
    warn "Yazi is unavailable; skipping Yazi plugin update."
  fi

  if exists nvim; then
    log "Updating Neovim plugins via vim.pack..."
    if ! nvim --headless -n -i NONE '+lua vim.pack.update(nil, { force = true })' +qa! </dev/null; then
      warn "Neovim plugin update failed; inspect the next nvim startup output."
    fi
    log "Updating installed Tree-sitter parsers..."
    if ! nvim --headless -n -i NONE '+lua require("nvim-treesitter").update(nil, { summary = true }):wait(300000)' +qa! </dev/null; then
      warn "Tree-sitter parser update failed; run :TSUpdate inside Neovim."
    fi
  else
    warn "Neovim is unavailable; skipping Neovim plugin update."
  fi
}

apply_update() {
  check_worktree

  local branch
  branch="$(git -C "$DOT_HOME" symbolic-ref --quiet --short HEAD || true)"
  if [[ -z "$branch" ]]; then
    error "The checkout is detached; refusing to update it automatically."
    return 1
  fi

  log "Fetching dotfiles updates on branch $branch..."
  git -C "$DOT_HOME" fetch --prune origin
  git -C "$DOT_HOME" pull --ff-only

  export DOT_SETUP_UPGRADE=1
  export DOT_BOOTSTRAP_UPDATE=1
  # Let update_plugins() below own explicit plugin upgrades. The platform
  # installer still reconciles package state, but must not upgrade Yazi once
  # here and then a second time in the wrapper.
  export DOT_BOOTSTRAP_UPDATE_PLUGINS=0
  if [[ "$START_SERVICES" -eq 1 ]]; then
    unset DOT_SETUP_SKIP_SERVICES
  else
    export DOT_SETUP_SKIP_SERVICES=1
  fi

  log "Updating managed applications and relinking configuration..."
  if [[ "$START_SERVICES" -eq 1 ]]; then
    bash "$DOT_HOME/install.sh" --upgrade
  else
    bash "$DOT_HOME/install.sh" --upgrade --no-services
  fi
  update_plugins
  check_config_state

  if [[ -n "$(git -C "$DOT_HOME" status --porcelain --untracked-files=all)" ]]; then
    warn "The update generated Git changes; review them before committing:"
    git -C "$DOT_HOME" status --short
  fi
}

main() {
  if [[ "$ACTION" == "apply" ]]; then
    apply_update
    return 0
  fi

  log "Dotfiles checkout: $DOT_HOME"
  if [[ -d "$DOT_HOME/.git" ]]; then
    git -C "$DOT_HOME" status --short
    git -C "$DOT_HOME" log -1 --oneline
  else
    warn "No Git metadata found; this checkout cannot self-update."
  fi
  check_package_state
  check_config_state
  print_versions
}

main
