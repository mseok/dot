#!/usr/bin/env bash
# Purpose: One-shot bootstrap for the macOS dev environment.
# Safety: Idempotent, user-owned config links, and explicit service control.
# Usage: bash $HOME/dot/bin/setup_macos.sh

set -euo pipefail

DOT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_HOME="${DOTFILES_HOME:-$DOT_HOME}"

# --------------- helpers ---------------
log()   { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

append_once() {
  # Append a line to a file only if it's not already present
  local line="$1" file="$2"
  grep -Fqs -- "$line" "$file" || echo "$line" >> "$file"
}

backup_if_exists() {
  # Back up existing file/directory with timestamp
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local ts
    ts="$(date +%Y%m%d_%H%M%S)"
    mv -v "$target" "${target}.backup_${ts}"
    log "Backed up: $target -> ${target}.backup_${ts}"
  elif [[ -L "$target" ]]; then
    # Remove existing symlink
    rm -f "$target"
  fi
}

link_config() {
  # Create symlink from source to destination
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    warn "Source does not exist, skipping: $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
  log "Linked: $dst -> $src"
}

# --------------- installation functions ---------------

load_homebrew() {
  local brew_path

  if exists brew; then
    return 0
  fi

  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      return 0
    fi
  done

  return 1
}

check_homebrew() {
  if load_homebrew; then
    log "Homebrew found: $(brew --version | head -1)"
    return 0
  fi

  if [[ "${DOT_SETUP_INSTALL_HOMEBREW:-0}" != "1" ]]; then
    error "Homebrew not found. Rerun with --install-homebrew, or install it first:"
    error '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi

  if ! exists curl; then
    error "curl is required to install Homebrew."
    exit 1
  fi

  local installer brew_path
  installer="$(mktemp "${TMPDIR:-/tmp}/dot-homebrew.XXXXXX")"
  log "Installing Homebrew using the official installer..."
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  if [[ "${DOT_ASSUME_YES:-0}" == "1" ]]; then
    NONINTERACTIVE=1 /bin/bash "$installer"
  else
    /bin/bash "$installer"
  fi
  rm -f "$installer"

  load_homebrew || true

  if ! exists brew; then
    error "Homebrew installation finished without a usable brew command."
    exit 1
  fi
  log "Homebrew found: $(brew --version | head -1)"
}

install_homebrew_packages() {
  if [[ -f "$DOT_HOME/Brewfile" ]] && brew bundle --help >/dev/null 2>&1; then
    log "Reconciling Homebrew packages from Brewfile..."
    if [[ "${DOT_SETUP_UPGRADE:-0}" == "1" ]]; then
      brew bundle install --file="$DOT_HOME/Brewfile" --upgrade
    else
      brew bundle install --file="$DOT_HOME/Brewfile" --no-upgrade
    fi
    return 0
  fi

  warn "brew bundle is unavailable; using the legacy package list."
  brew tap nikitabobko/tap
  brew tap FelixKratz/formulae
  brew install neovim tmux git gh pre-commit starship eza fzf ripgrep fd yazi \
               chafa imagemagick ffmpeg poppler resvg sevenzip jq zoxide bat \
               lazygit uv pixi node python@3.11 sketchybar borders
  brew install --cask wezterm aerospace codex
}

setup_shell_integration() {
  local rc_file
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL##*/}" == "zsh" ]] || [[ -f "$HOME/.zshrc" ]]; then
    rc_file="$HOME/.zshrc"
  else
    rc_file="$HOME/.bashrc"
  fi

  log "Configuring shell integration in $rc_file..."

  touch "$rc_file"

  # Export the checkout path so the same shell configuration works when the
  # repository is installed somewhere other than $HOME/dot.
  if [[ "$rc_file" == *".zshrc"* ]]; then
    append_once "export DOTFILES_HOME=\"$DOT_HOME\"" "$rc_file"
    append_once "source \"$DOT_HOME/config/zsh/.zshrc\"" "$rc_file"
  else
    append_once "export DOTFILES_HOME=\"$DOT_HOME\"" "$rc_file"
    append_once "source \"$DOT_HOME/config/bash/.bashrc\"" "$rc_file"
  fi

  log "Shell integration configured"
}

setup_neovim() {
  log "Setting up Neovim configuration..."
  link_config "$DOT_HOME/config/nvim" "$HOME/.config/nvim"

  # Neovim plugins will auto-install on first launch via vim.pack
  log "Neovim plugins will install automatically on first launch"
}

setup_tmux() {
  log "Setting up Tmux configuration..."

  # Install TPM (Tmux Plugin Manager)
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log "Installing TPM (Tmux Plugin Manager)..."
    git clone --quiet https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  elif [[ "${DOT_SETUP_UPGRADE:-0}" == "1" && -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
    log "Updating TPM..."
    git -C "$HOME/.tmux/plugins/tpm" pull --ff-only || warn "Failed to update TPM"
  else
    log "TPM already installed"
  fi

  link_config "$DOT_HOME/config/tmux/.tmux.conf" "$HOME/.tmux.conf"
  log "Tmux configured. Press Ctrl+b then Shift+I inside tmux to install plugins"
}

setup_git() {
  log "Setting up Git configuration..."
  link_config "$DOT_HOME/config/git/.gitconfig" "$HOME/.gitconfig"

  if ! exists pre-commit; then
    warn "pre-commit is unavailable; install it with Homebrew or your Python environment."
  fi
}

setup_starship() {
  log "Setting up Starship prompt..."
  link_config "$DOT_HOME/config/starship/starship.toml" "$HOME/.config/starship.toml"
}

setup_wezterm() {
  log "Setting up WezTerm configuration..."
  link_config "$DOT_HOME/config/wezterm" "$HOME/.config/wezterm"
}

setup_yazi() {
  log "Setting up Yazi file manager..."
  local config_dir="$HOME/.config/yazi"

  if [[ -L "$config_dir" ]]; then
    local current_target staging
    current_target="$(readlink "$config_dir")"
    if [[ "$current_target" != "$DOT_HOME/config/yazi" ]]; then
      warn "Leaving unrelated Yazi config symlink untouched: $config_dir -> $current_target"
      return 0
    fi

    # Older versions linked the whole directory, which made ya pkg write
    # mutable plugin checkouts into the Git repository.
    staging="$HOME/.config/yazi.plugins.staging"
    if [[ -e "$staging" ]]; then
      backup_if_exists "$staging"
    fi
    if [[ -d "$DOT_HOME/config/yazi/plugins" ]]; then
      mv "$DOT_HOME/config/yazi/plugins" "$staging"
    fi
    rm -f "$config_dir"
  elif [[ -e "$config_dir" && ! -d "$config_dir" ]]; then
    backup_if_exists "$config_dir"
  fi

  mkdir -p "$config_dir"
  link_config "$DOT_HOME/config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"
  link_config "$DOT_HOME/config/yazi/keymap.toml" "$HOME/.config/yazi/keymap.toml"
  link_config "$DOT_HOME/config/yazi/package.toml" "$HOME/.config/yazi/package.toml"

  if [[ -d "$HOME/.config/yazi.plugins.staging" ]]; then
    mv "$HOME/.config/yazi.plugins.staging" "$config_dir/plugins"
  fi
}

setup_yazi_plugins() {
  if [[ "${DOT_SETUP_SKIP_PLUGINS:-0}" == "1" ]]; then
    log "Skipping Yazi plugins (DOT_SETUP_SKIP_PLUGINS=1)."
    return 0
  fi
  if ! exists ya; then
    warn "ya is unavailable; skipping Yazi plugin installation."
    return 0
  fi
  if [[ ! -f "$HOME/.config/yazi/package.toml" ]]; then
    warn "Yazi package.toml is unavailable; skipping plugin installation."
    return 0
  fi

  if [[ "${DOT_BOOTSTRAP_UPDATE_PLUGINS:-0}" == "1" ]]; then
    log "Updating Yazi plugins..."
    (cd "$HOME/.config/yazi" && ya pkg upgrade) || warn "Failed to upgrade Yazi plugins"
  fi
  (cd "$HOME/.config/yazi" && ya pkg install) || warn "Failed to install Yazi plugins"
}

setup_macos_window_management() {
  log "Setting up macOS window management..."

  link_config "$DOT_HOME/config/aerospace" "$HOME/.config/aerospace"

  # SketchyBar
  link_config "$DOT_HOME/config/sketchybar" "$HOME/.config/sketchybar"

  if [[ "${DOT_SETUP_SKIP_SERVICES:-0}" == "1" ]]; then
    log "Skipping window-management service startup (DOT_SETUP_SKIP_SERVICES=1)."
    return 0
  fi

  log "Starting window management services..."
  brew services start sketchybar 2>/dev/null || warn "Failed to start sketchybar"

  if [[ -d "/Applications/AeroSpace.app" ]]; then
    open -a AeroSpace || warn "Failed to launch AeroSpace"
  else
    warn "AeroSpace.app not found after installation"
  fi

  log "Window management services started"
}

setup_vscode() {
  log "Setting up VS Code configuration (optional)..."
  local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"

  if [[ -f "$DOT_HOME/config/vscode/settings.json" ]]; then
    link_config "$DOT_HOME/config/vscode/settings.json" "$vscode_settings"
  else
    log "VS Code config not found, skipping"
  fi
}

print_post_install() {
  cat <<'EOS'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ macOS Setup Complete!

What was installed:
• Core tools: Neovim, Tmux, Git, Starship, eza, fzf, ripgrep, fd, Yazi, Codex CLI
• Terminal: WezTerm
• Window Management: Aerospace, SketchyBar, Borders
• Languages: Node.js, Python 3.11

What was configured:
• Shell integration (zsh/bash)
• Neovim → ~/.config/nvim
• Tmux → ~/.tmux.conf
• Git → ~/.gitconfig
• Starship → ~/.config/starship.toml
• WezTerm → ~/.config/wezterm
• Yazi → ~/.config/yazi
• Aerospace → ~/.config/aerospace
• SketchyBar → ~/.config/sketchybar

Next steps:
1. Restart your shell:
   exec $SHELL -l

2. Verify installations:
   nvim --version
   tmux -V
   starship --version
   codex --version
   aerospace --version

3. Install Tmux plugins:
   - Start tmux
   - Press: Ctrl+b then Shift+I

4. (Optional) Set up GitHub Copilot in Neovim:
   nvim
   :Copilot setup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOS
}

# --------------- main ---------------

main() {
  log "Starting macOS dotfiles setup..."

  check_homebrew
  install_homebrew_packages
  setup_shell_integration
  setup_neovim
  setup_tmux
  setup_git
  setup_starship
  setup_wezterm
  setup_yazi
  setup_yazi_plugins
  setup_macos_window_management
  setup_vscode

  print_post_install

  log "Setup complete! Restart your shell to apply changes."
}

main "$@"
