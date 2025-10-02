#!/usr/bin/env bash
# Purpose: One-shot bootstrap for Ubuntu dev environment (nvm, Node LTS, fzf, etc.)
# Safety: Idempotent, non-interactive, with clear logging.
# Comments: All comments are in English as requested.

set -euo pipefail

# --------------- helpers ---------------
log()   { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

# Determine the primary shell rc file to modify (bash or zsh)
detect_shell_rc() {
  # If running inside zsh, prefer .zshrc; else .bashrc
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    echo "$HOME/.zshrc"
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    echo "$HOME/.bashrc"
  else
    # Fallback: choose whichever exists, otherwise .bashrc
    [[ -f "$HOME/.zshrc" ]] && echo "$HOME/.zshrc" || echo "$HOME/.bashrc"
  fi
}

append_once() {
  # Append a line to a file only if it's not already present (literal match)
  local line="$1" file="$2"
  grep -Fqs -- "$line" "$file" || echo "$line" >> "$file"
}

backup_if_exists() {
  # If path exists and is not the desired symlink, back it up with timestamp
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -L "$target" ]]; then
      # If it's a symlink, remove it to re-link cleanly
      rm -f "$target"
    else
      local ts
      ts="$(date +%Y%m%d_%H%M%S)"
      mv -v "$target" "${target}.bak_${ts}"
    fi
  fi
}

link_config() {
  # Create symlink from $1 (source) to $2 (destination)
  local src="$1" dst="$2"
  if [[ ! -e "$src" ]]; then
    warn "Source does not exist, skipping link: $src"
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  backup_if_exists "$dst"
  ln -s "$src" "$dst"
  log "Linked: $dst -> $src"
}

APT_UPDATED=0
apt_update_once() {
  if [[ $APT_UPDATED -eq 0 ]]; then
    log "Updating apt package index..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    APT_UPDATED=1
  fi
}

install_base_packages() {
  log "Installing base packages via apt..."
  apt_update_once
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential curl git ca-certificates pkg-config \
    unzip zip tar wget xz-utils \
    python3.10-venv \
    ripgrep fd-find \
    software-properties-common
  # fd on Ubuntu is 'fdfind' binary; create user-friendly alias if missing
  local rc_file
  rc_file="$(detect_shell_rc)"
  if ! exists fd && exists fdfind; then
    log "Adding alias: fd -> fdfind"
    append_once 'alias fd=fdfind' "$rc_file"
  fi
}

install_uv() {
  # Install uv (universal version manager) for managing multiple runtimes
  if exists uv; then
    log "uv already installed: $(uv --version)"
    return 0
  fi
  log "Installing uv (universal version manager)..."
  # Official install script
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_nvm_and_node() {
  # Install nvm if not present
  if ! exists nvm; then
    log "Installing nvm..."
    # Official install script; pinned to latest release URL
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    # Source nvm for current session
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    # Add sourcing to shell rc
    local rc_file
    rc_file="$(detect_shell_rc)"
    append_once 'export NVM_DIR="$HOME/.nvm"' "$rc_file"
    append_once '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' "$rc_file"
  else
    log "nvm already installed."
    # shellcheck disable=SC1091
    . "$HOME/.nvm/nvm.sh"
  fi

  # Install latest LTS Node if not installed
  if ! exists node; then
    log "Installing latest LTS Node via nvm..."
    nvm install --lts
    nvm alias default 'lts/*'
  else
    log "Node is present: $(node -v). Ensuring nvm default is LTS..."
    nvm install --lts >/dev/null 2>&1 || true
    nvm alias default 'lts/*' >/dev/null 2>&1 || true
  fi
}

install_fzf() {
  # Prefer upstream git install for the latest fzf (includes keybindings + completion)
  if ! exists fzf; then
    log "Installing fzf from upstream (git)..."
    if [[ ! -d "$HOME/.fzf" ]]; then
      git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    fi
    $HOME/.fzf/install --all
    # Enable for bash/zsh explicitly (fzf installs snippets under ~/.fzf)
    local rc_file
    rc_file="$(detect_shell_rc)"
    append_once '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' "$rc_file"
  else
    log "fzf already installed: $(fzf --version | head -n1)"
  fi
}

install_starship() {
  if ! exists starship; then
    log "Installing starship..."
    # Non-interactive install (-y). Installs to /usr/local/bin by default.
    curl -fsSL https://starship.rs/install.sh | sudo sh -s -- -y
  else
    log "starship present: $(starship --version)"
  fi

  # Ensure starship init line (bash). This can live in your dot repo, but we add a safe default.
  append_once 'eval "$(starship init bash)"' "$HOME/.bashrc"
}

clone_dot_repo() {
  local repo_url="https://github.com/mseok/dot.git"
  local dest="$HOME/dot"
  if [[ -d "$dest/.git" ]]; then
    log "Updating existing dot repo at $dest"
    git -C "$dest" pull --ff-only || warn "git pull failed; check your local changes."
  else
    log "Cloning dot repo -> $dest"
    git clone "$repo_url" "$dest"
  fi
}

link_dot_configs() {
  # Ensure ~/.config exists
  mkdir -p "$HOME/.config"

  # Link nvim, tmux, starship configs (directory-based)
  link_config "$HOME/dot/config/nvim"                   "$HOME/.config/nvim"
  link_config "$HOME/dot/config/tmux/.tmux.conf"        "$HOME/.tmux.conf"
  link_config "$HOME/dot/config/starship/starship.toml" "$HOME/.config/starship.toml"
  link_config "$HOME/dot/config/git/.gitconfig"         "$HOME/.gitconfig"

  # Some setups also keep a top-level ~/.tmux.conf — link if provided
  if [[ -f "$HOME/dot/config/tmux/tmux.conf" ]]; then
    link_config "$HOME/dot/config/tmux/tmux.conf" "$HOME/.tmux.conf"
  fi
}

copy_dot_configs() {
    # Copy (not link) dot configs if they don't exist
    local src_dir="$HOME/dot/config"
    local dest_dir="$HOME/.config"
    mkdir -p "$dest_dir"

    # Copy git config
    if [[ ! -d "$HOME/.config/git" ]]; then
      cp -r "$src_dir/git" "$HOME/.config/git"
      log "Copied $src_dir/git to $HOME/.config/git"
    fi

    # Copy claude code
    if [[ ! -d "$HOME/.config/claude" ]]; then
      cp -r "$src_dir/claude" "$HOME/.claude"
      log "Copied $src_dir/claude to $HOME/.claude"
    fi
}

install_neovim_appimage() {
  # Install latest Neovim AppImage to $HOME/appl/bin/nvim (FUSE-safe)
  set -euo pipefail
  local bindir="$HOME/appl/bin" cachedir="$HOME/.cache/nvim-appimage"
  local url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage"
  mkdir -p "$bindir" "$cachedir"
  log "Downloading Neovim AppImage (latest)..."
  curl -fsSL -o "$cachedir/nvim.appimage" "$url"
  chmod +x "$cachedir/nvim.appimage"

  if "$cachedir/nvim.appimage" --version >/dev/null 2>&1; then
    log "AppImage runs directly; copying to $bindir/nvim"
    backup_if_exists "$bindir/nvim"
    cp "$cachedir/nvim.appimage" "$bindir/nvim"
    chmod +x "$bindir/nvim"
  else
    warn "Direct exec failed (FUSE). Extracting..."
    ( cd "$cachedir" && ./nvim.appimage --appimage-extract >/dev/null )
    [[ -x "$cachedir/squashfs-root/usr/bin/nvim" ]] || { error "Extraction failed"; exit 1; }
    backup_if_exists "$bindir/nvim"
    ln -s "$cachedir/squashfs-root/usr/bin/nvim" "$bindir/nvim"
    log "Linked $bindir/nvim -> extracted binary"
  fi

  append_once 'export PATH="$HOME/appl/bin:$PATH"' "$HOME/.bashrc"
}

ensure_bashrc_source() {
  # Append requested sourcing line exactly once
  append_once 'source "$HOME/dot/config/bash/.bashrc"' "$HOME/.bashrc"
}

install_global_npm_clis() {
  log "Installing global npm CLIs..."
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
  npm install -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex task-master-ai
}

post_instructions() {
  cat <<'EOS'

------------------------------------------------------------
✅ Setup complete.

What changed:
• Installed/updated: base packages, nvm+Node LTS, fzf, starship, tmux, neovim.
• Cloned/updated: $HOME/dot (from github.com/mseok/dot).
• Symlinked:
    ~/.config/nvim     	    -> $HOME/dot/config/nvim
    ~/.config/starship.toml -> $HOME/dot/config/starship.toml
    ~/.tmux.conf       	    -> $HOME/dot/config/tmux/.tmux.conf   
• Neovim installed to: $HOME/appl/bin/nvim
• npm global CLIs: claude-code, gemini-cli, codex-cli, task-master-ai
• Appended to ~/.bashrc (idempotent):
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -f ~/.fzf.bash ] && source ~/.fzf.bash
    eval "$(starship init bash)"
    source "$HOME/dot/config/bash/.bashrc"

Next steps:
• Open a new terminal, or run:  exec $SHELL -l
• Verify:
    starship --version
    tmux -V
    nvim --version | head -n 1
    node -v
• If starship style doesn’t load, ensure your theme is configured under ~/.config/starship/.
------------------------------------------------------------
EOS
}

main() {
  install_base_packages
  install_nvm_and_node
  install_fzf
  install_starship
  install_uv
  clone_dot_repo
  link_dot_configs
  ensure_bashrc_source
  install_neovim_appimage
  install_global_npm_clis
  post_instructions
}

main "$@"
