#!/usr/bin/env bash
# Purpose: One-shot bootstrap for macOS dev environment
# Safety: Idempotent, non-interactive, with clear logging
# Usage: bash $HOME/dot/bin/setup_macos.sh

set -euo pipefail

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

check_homebrew() {
  if ! exists brew; then
    error "Homebrew not found. Please install it first:"
    error '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
  log "Homebrew found: $(brew --version | head -1)"
}

install_homebrew_packages() {
  log "Adding Homebrew taps..."
  brew tap nikitabobko/tap      2>/dev/null || true  # Aerospace
  brew tap FelixKratz/formulae  2>/dev/null || true  # SketchyBar & Borders
  brew tap koekeishiya/formulae 2>/dev/null || true  # SKHD

  log "Installing core packages via Homebrew..."
  brew install --quiet neovim tmux git starship fzf ripgrep fd yazi \
               sketchybar borders node python@3.11 || true

  log "Installing cask applications..."
  brew install --cask --quiet wezterm aerospace || true

  # Optional: SKHD (hotkey daemon)
  # Uncomment if you want to install skhd:
  # brew install koekeishiya/formulae/skhd
}

setup_shell_integration() {
  local rc_file
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ -f "$HOME/.zshrc" ]]; then
    rc_file="$HOME/.zshrc"
  else
    rc_file="$HOME/.bashrc"
  fi

  log "Configuring shell integration in $rc_file..."

  # Backup existing RC file
  if [[ -f "$rc_file" ]]; then
    backup_if_exists "$rc_file"
    touch "$rc_file"
  fi

  # Add dotfiles sourcing
  if [[ "$rc_file" == *".zshrc"* ]]; then
    append_once 'source $HOME/dot/config/zsh/.zshrc' "$rc_file"
  else
    append_once 'source $HOME/dot/config/bash/.bashrc' "$rc_file"
  fi

  log "Shell integration configured"
}

setup_neovim() {
  log "Setting up Neovim configuration..."
  link_config "$HOME/dot/config/nvim" "$HOME/.config/nvim"

  # Neovim plugins will auto-install on first launch via vim.pack
  log "Neovim plugins will install automatically on first launch"
}

setup_tmux() {
  log "Setting up Tmux configuration..."

  # Install TPM (Tmux Plugin Manager)
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log "Installing TPM (Tmux Plugin Manager)..."
    git clone --quiet https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    log "TPM already installed"
  fi

  link_config "$HOME/dot/config/tmux/.tmux.conf" "$HOME/.tmux.conf"
  log "Tmux configured. Press Ctrl+b then Shift+I inside tmux to install plugins"
}

setup_git() {
  log "Setting up Git configuration..."
  link_config "$HOME/dot/config/git/.gitconfig" "$HOME/.gitconfig"

  # Install pre-commit if not present
  if ! exists pre-commit; then
    log "Installing pre-commit framework..."
    pip3 install --quiet --user pre-commit || true
  fi
}

setup_starship() {
  log "Setting up Starship prompt..."
  link_config "$HOME/dot/config/starship/starship.toml" "$HOME/.config/starship.toml"
}

setup_wezterm() {
  log "Setting up WezTerm configuration..."
  link_config "$HOME/dot/config/wezterm" "$HOME/.config/wezterm"
}

setup_yazi() {
  log "Setting up Yazi file manager..."
  link_config "$HOME/dot/config/yazi" "$HOME/.config/yazi"
}

setup_macos_window_management() {
  log "Setting up macOS window management..."

  # Aerospace
  link_config "$HOME/dot/config/aerospace/aerospace.toml" "$HOME/.aerospace.toml"

  # SketchyBar
  link_config "$HOME/dot/config/sketchybar" "$HOME/.config/sketchybar"

  # Start services
  log "Starting window management services..."
  brew services start aerospace 2>/dev/null || warn "Failed to start aerospace"
  brew services start sketchybar 2>/dev/null || warn "Failed to start sketchybar"

  # Optional: Start SKHD if installed
  if exists skhd; then
    brew services start skhd 2>/dev/null || warn "Failed to start skhd"
  fi

  log "Window management services started"
}

setup_ai_tools() {
  log "Setting up AI tools (optional)..."

  # Aider configuration
  link_config "$HOME/dot/config/aider/.aider.conf.yml" "$HOME/.aider.conf.yml"
  link_config "$HOME/dot/config/aider/.aider.model.settings.yml" "$HOME/.aider.model.settings.yml"

  # Claude CLI configuration
  if [[ -d "$HOME/dot/config/claude" ]]; then
    link_config "$HOME/dot/config/claude" "$HOME/.claude"
  fi

  log "AI tools configured"
}

setup_vscode() {
  log "Setting up VS Code configuration (optional)..."
  local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"

  if [[ -f "$HOME/dot/config/vscode/settings.json" ]]; then
    link_config "$HOME/dot/config/vscode/settings.json" "$vscode_settings"
  else
    log "VS Code config not found, skipping"
  fi
}

print_post_install() {
  cat <<'EOS'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ macOS Setup Complete!

What was installed:
• Core tools: Neovim, Tmux, Git, Starship, fzf, ripgrep, fd, Yazi
• Terminal: WezTerm
• Window Management: Aerospace, SketchyBar, Borders
• Languages: Node.js, Python 3.11
• AI Tools: Aider, Claude CLI configurations

What was configured:
• Shell integration (zsh/bash)
• Neovim → ~/.config/nvim
• Tmux → ~/.tmux.conf
• Git → ~/.gitconfig
• Starship → ~/.config/starship.toml
• WezTerm → ~/.config/wezterm
• Yazi → ~/.config/yazi
• Aerospace → ~/.aerospace.toml
• SketchyBar → ~/.config/sketchybar

Next steps:
1. Restart your shell:
   exec $SHELL -l

2. Verify installations:
   nvim --version
   tmux -V
   starship --version
   aerospace --version

3. Install Tmux plugins:
   - Start tmux
   - Press: Ctrl+b then Shift+I

4. (Optional) Set up GitHub Copilot in Neovim:
   nvim
   :Copilot setup

5. (Optional) Install AI tools:
   pip3 install aider-chat
   npm install -g @anthropic-ai/claude-code

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
  setup_macos_window_management
  setup_ai_tools
  setup_vscode

  print_post_install

  log "Setup complete! Restart your shell to apply changes."
}

main "$@"
