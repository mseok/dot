#!/usr/bin/env bash
# Purpose: Bootstrap an Ubuntu user environment without sudo.
# Safety: Idempotent, non-interactive, and installs only into user-owned paths.

set -euo pipefail

log()   { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
LOCAL_OPT="${LOCAL_OPT:-$HOME/.local/opt}"
LOCAL_SHARE="${LOCAL_SHARE:-$HOME/.local/share}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dot-bootstrap"
NVM_DIR="${NVM_DIR:-$LOCAL_SHARE/nvm}"

mkdir -p $LOCAL_BIN $LOCAL_OPT $LOCAL_SHARE $CACHE_DIR $NVM_DIR

NVM_VERSION="${NVM_VERSION:-v0.40.1}"
RIPGREP_VERSION="${RIPGREP_VERSION:-14.1.1}"
FD_VERSION="${FD_VERSION:-10.2.0}"
NEOVIM_CHANNEL="${NEOVIM_CHANNEL:-stable}"
TMUX_VERSION="${TMUX_VERSION:-3.6a}"
GH_VERSION="${GH_VERSION:-2.89.0}"

export PATH="$LOCAL_BIN:$PATH"

mkdir -p "$LOCAL_BIN" "$LOCAL_OPT" "$LOCAL_SHARE" "$CACHE_DIR" "$HOME/.config"

require_tools() {
  local missing=()
  local tool
  for tool in bash tar uname chmod mktemp find awk readlink cp mv rm; do
    exists "$tool" || missing+=("$tool")
  done

  if ! exists curl && ! exists wget; then
    missing+=("curl-or-wget")
  fi

  if (( ${#missing[@]} > 0 )); then
    error "Missing required bootstrap tools: ${missing[*]}"
    error "Install them with your cluster or system package manager, then rerun this script."
    exit 1
  fi
}

download_to() {
  local url="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"

  if exists curl; then
    curl -fsSL "$url" -o "$dest"
  else
    wget -qO "$dest" "$url"
  fi
}

backup_path() {
  local path="$1"
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  mv "$path" "${path}.bak_${ts}"
  log "Backed up: $path -> ${path}.bak_${ts}"
}

ensure_link() {
  local src="$1" dst="$2"

  if [[ ! -e "$src" ]]; then
    warn "Source missing, skipping: $src"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      log "Link already up to date: $dst"
      return 0
    fi
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    backup_path "$dst"
  fi

  ln -s "$src" "$dst"
  log "Linked: $dst -> $src"
}

upsert_block() {
  local file="$1" marker="$2" content="$3"
  local start="# >>> ${marker} >>>"
  local end="# <<< ${marker} <<<"
  local tmp out

  mkdir -p "$(dirname "$file")"
  touch "$file"

  tmp="$(mktemp)"
  out="$(mktemp)"

  awk -v start="$start" -v end="$end" '
    $0 == start { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$file" > "$tmp"

  {
    cat "$tmp"
    printf '\n%s\n' "$start"
    printf '%s\n' "$content"
    printf '%s\n' "$end"
  } > "$out"

  mv "$out" "$file"
  rm -f "$tmp"
}

shell_bootstrap_block() {
  local shell_name="$1"

  if [[ "$shell_name" == "bash" ]]; then
    cat <<EOF
case ":\$PATH:" in
  *":\$HOME/.local/bin:"*) ;;
  *) export PATH="\$HOME/.local/bin:\$PATH" ;;
esac

export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -f "$HOME/.local/opt/fzf/shell/completion.bash" ] && source "$HOME/.local/opt/fzf/shell/completion.bash"
[ -f "$HOME/.local/opt/fzf/shell/key-bindings.bash" ] && source "$HOME/.local/opt/fzf/shell/key-bindings.bash"
command -v starship >/dev/null 2>&1 && eval "\$(starship init bash)"
[ -f "$REPO_ROOT/config/bash/.bashrc" ] && source "$REPO_ROOT/config/bash/.bashrc"
EOF
  else
    cat <<EOF
case ":\$PATH:" in
  *":\$HOME/.local/bin:"*) ;;
  *) export PATH="\$HOME/.local/bin:\$PATH" ;;
esac

export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -f "$HOME/.local/opt/fzf/shell/completion.zsh" ] && source "$HOME/.local/opt/fzf/shell/completion.zsh"
[ -f "$HOME/.local/opt/fzf/shell/key-bindings.zsh" ] && source "$HOME/.local/opt/fzf/shell/key-bindings.zsh"
command -v starship >/dev/null 2>&1 && eval "\$(starship init zsh)"
[ -f "$REPO_ROOT/config/zsh/.zshrc" ] && source "$REPO_ROOT/config/zsh/.zshrc"
EOF
  fi
}

configure_shell_rcs() {
  local bash_block zsh_block
  bash_block="$(shell_bootstrap_block bash)"
  zsh_block="$(shell_bootstrap_block zsh)"

  upsert_block "$HOME/.bashrc" "dot-bootstrap" "$bash_block"
  upsert_block "$HOME/.zshrc" "dot-bootstrap" "$zsh_block"
  log "Updated shell bootstrap blocks in ~/.bashrc and ~/.zshrc"
}

warn_if_repo_not_in_home_dot() {
  if [[ "$REPO_ROOT" != "$HOME/dot" ]]; then
    warn "This dotfiles repo is currently at $REPO_ROOT"
    warn "Some sourced configs still assume the canonical location is $HOME/dot"
  fi
}

load_nvm() {
  export NVM_DIR
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
  fi
}

install_uv() {
  if exists uv; then
    log "uv already available: $(uv --version)"
    return 0
  fi

  local installer="$CACHE_DIR/uv-install.sh"
  log "Installing uv into the user profile..."
  download_to "https://astral.sh/uv/install.sh" "$installer"
  UV_INSTALL_DIR="$LOCAL_BIN" INSTALLER_NO_MODIFY_PATH=1 sh "$installer"
}

install_nvm_and_node() {
  local has_nvm=0
  local has_node=0

  [[ -s "$NVM_DIR/nvm.sh" ]] && has_nvm=1
  exists node && has_node=1

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    local installer="$CACHE_DIR/nvm-install.sh"
    log "Installing nvm ${NVM_VERSION}..."
    download_to "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" "$installer"
    PROFILE=/dev/null NVM_DIR="$NVM_DIR" bash "$installer"
    has_nvm=1
  else
    log "nvm already installed."
  fi

  if [[ $has_node -eq 1 ]]; then
    log "Node.js already available: $(node -v)"
    return 0
  fi

  load_nvm
  if [[ $has_nvm -eq 0 ]] || ! type nvm >/dev/null 2>&1; then
    error "nvm is unavailable, so Node.js LTS cannot be installed automatically."
    exit 1
  fi

  log "Installing Node.js LTS via nvm..."
  nvm install --lts
  nvm alias default 'lts/*'
}

install_fzf() {
  local dest="$LOCAL_OPT/fzf"

  if exists fzf; then
    log "fzf already available: $(fzf --version | head -n1)"
    return 0
  fi

  log "Installing fzf into $dest..."

  if [[ -e "$dest" ]]; then
    backup_path "$dest"
  fi

  if exists git; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$dest"
  else
    local archive="$CACHE_DIR/fzf.tar.gz"
    local tmpdir
    tmpdir="$(mktemp -d)"
    download_to "https://github.com/junegunn/fzf/archive/refs/heads/master.tar.gz" "$archive"
    tar -xzf "$archive" -C "$tmpdir"
    mv "$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d | head -n1)" "$dest"
    rm -rf "$tmpdir"
  fi

  ln -sfn "$dest/bin/fzf" "$LOCAL_BIN/fzf"
  [[ -f "$dest/bin/fzf-tmux" ]] && ln -sfn "$dest/bin/fzf-tmux" "$LOCAL_BIN/fzf-tmux"
}

install_binary_from_tarball() {
  local name="$1" url="$2" binary_name="$3"
  local archive="$CACHE_DIR/${name}.tar.gz"
  local tmpdir binary_path

  tmpdir="$(mktemp -d)"
  download_to "$url" "$archive"
  tar -xzf "$archive" -C "$tmpdir"

  binary_path="$(find "$tmpdir" -type f -name "$binary_name" -perm -u+x | head -n1)"
  if [[ -z "$binary_path" ]]; then
    rm -rf "$tmpdir"
    error "Could not find ${binary_name} inside ${name} archive."
    exit 1
  fi

  cp "$binary_path" "$LOCAL_BIN/$binary_name"
  chmod +x "$LOCAL_BIN/$binary_name"
  rm -rf "$tmpdir"
  log "Installed $binary_name -> $LOCAL_BIN/$binary_name"
}

install_ripgrep() {
  if exists rg; then
    log "ripgrep already available: $(rg --version | head -n1)"
    return 0
  fi

  local arch url
  case "$(uname -m)" in
    x86_64|amd64)
      arch="x86_64-unknown-linux-musl"
      ;;
    aarch64|arm64)
      arch="aarch64-unknown-linux-gnu"
      ;;
    *)
      warn "Unsupported architecture for bundled ripgrep: $(uname -m)"
      return 0
      ;;
  esac

  url="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${arch}.tar.gz"
  log "Installing ripgrep ${RIPGREP_VERSION}..."
  install_binary_from_tarball "ripgrep-${RIPGREP_VERSION}" "$url" "rg"
}

install_fd() {
  if exists fd; then
    log "fd already available: $(fd --version | head -n1)"
    return 0
  fi

  local arch url
  case "$(uname -m)" in
    x86_64|amd64)
      arch="x86_64-unknown-linux-musl"
      ;;
    aarch64|arm64)
      arch="aarch64-unknown-linux-gnu"
      ;;
    *)
      warn "Unsupported architecture for bundled fd: $(uname -m)"
      return 0
      ;;
  esac

  url="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${arch}.tar.gz"
  log "Installing fd ${FD_VERSION}..."
  install_binary_from_tarball "fd-${FD_VERSION}" "$url" "fd"
  ln -sfn "$LOCAL_BIN/fd" "$LOCAL_BIN/fdfind"
}

install_starship() {
  if exists starship; then
    log "starship already available: $(starship --version)"
    return 0
  fi

  local installer="$CACHE_DIR/starship-install.sh"
  log "Installing starship into $LOCAL_BIN..."
  download_to "https://starship.rs/install.sh" "$installer"
  sh "$installer" -y -b "$LOCAL_BIN"
}

install_tmux() {
  if exists tmux; then
    log "tmux already available: $(tmux -V)"
    return 0
  fi

  local asset url
  case "$(uname -m)" in
    x86_64|amd64)
      asset="tmux-${TMUX_VERSION}-linux-x86_64.tar.gz"
      ;;
    aarch64|arm64)
      asset="tmux-${TMUX_VERSION}-linux-arm64.tar.gz"
      ;;
    *)
      warn "Unsupported architecture for bundled tmux: $(uname -m)"
      return 0
      ;;
  esac

  url="https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VERSION}/${asset}"
  log "Installing tmux ${TMUX_VERSION} from tmux-builds..."
  install_binary_from_tarball "tmux-${TMUX_VERSION}" "$url" "tmux"
}

install_gh() {
  if exists gh; then
    log "gh already available: $(gh --version | head -n1)"
    return 0
  fi

  local asset url
  case "$(uname -m)" in
    x86_64|amd64)
      asset="gh_${GH_VERSION}_linux_amd64.tar.gz"
      ;;
    aarch64|arm64)
      asset="gh_${GH_VERSION}_linux_arm64.tar.gz"
      ;;
    *)
      warn "Unsupported architecture for bundled gh: $(uname -m)"
      return 0
      ;;
  esac

  url="https://github.com/cli/cli/releases/download/v${GH_VERSION}/${asset}"
  log "Installing GitHub CLI ${GH_VERSION}..."
  install_binary_from_tarball "gh-${GH_VERSION}" "$url" "gh"
}

install_neovim() {
  if exists nvim; then
    log "Neovim already available: $(nvim --version | head -n1)"
    return 0
  fi

  local asset url appimage_path nvim_root
  case "$(uname -m)" in
    x86_64|amd64)
      asset="nvim-linux-x86_64.appimage"
      ;;
    aarch64|arm64)
      asset="nvim-linux-arm64.appimage"
      ;;
    *)
      warn "Unsupported architecture for bundled Neovim: $(uname -m)"
      return 0
      ;;
  esac

  if [[ "$NEOVIM_CHANNEL" == "nightly" ]]; then
    url="https://github.com/neovim/neovim-releases/releases/download/nightly/${asset}"
  else
    url="https://github.com/neovim/neovim-releases/releases/latest/download/${asset}"
  fi

  nvim_root="$LOCAL_OPT/nvim"
  appimage_path="$nvim_root/${asset}"
  mkdir -p "$nvim_root"

  log "Installing Neovim (${NEOVIM_CHANNEL}) into $nvim_root..."
  download_to "$url" "$appimage_path"
  chmod +x "$appimage_path"

  if "$appimage_path" --version >/dev/null 2>&1; then
    ln -sfn "$appimage_path" "$LOCAL_BIN/nvim"
    log "Neovim AppImage is executable directly."
    return 0
  fi

  log "FUSE is unavailable. Extracting the AppImage instead..."
  rm -rf "$nvim_root/squashfs-root"
  (
    cd "$nvim_root"
    "./${asset}" --appimage-extract >/dev/null
  )

  if [[ ! -x "$nvim_root/squashfs-root/usr/bin/nvim" ]]; then
    error "Failed to extract Neovim AppImage."
    exit 1
  fi

  ln -sfn "$nvim_root/squashfs-root/usr/bin/nvim" "$LOCAL_BIN/nvim"
}

install_optional_tmux_plugins() {
  if [[ -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
    log "TPM already installed."
    return 0
  fi

  if ! exists tmux; then
    warn "tmux is unavailable, skipping TPM install."
    return 0
  fi

  if ! exists git; then
    warn "git is unavailable, skipping TPM install."
    return 0
  fi

  log "Installing tmux plugin manager (TPM)..."
  mkdir -p "$HOME/.tmux/plugins"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

install_color_profile() {
  tic -x -o $HOME/.terminfo "$REPO_ROOT/config/terminal/wezterm.src"
  tic -x -o $HOME/.terminfo "$REPO_ROOT/config/terminal/tmux-256color.src"
}

link_dot_configs() {
  ensure_link "$REPO_ROOT/config/nvim" "$HOME/.config/nvim"
  ensure_link "$REPO_ROOT/config/tmux/.tmux.conf" "$HOME/.tmux.conf"
  ensure_link "$REPO_ROOT/config/starship/starship.toml" "$HOME/.config/starship.toml"
  ensure_link "$REPO_ROOT/config/git/.gitconfig" "$HOME/.gitconfig"
  ensure_link "$REPO_ROOT/config/yazi" "$HOME/.config/yazi"
}

install_global_npm_clis() {
  local package_specs=(
    "@openai/codex:codex"
  )
  local spec pkg bin_name

  load_nvm
  if ! exists npm; then
    warn "npm is unavailable, skipping global npm CLI installation."
    return 0
  fi

  for spec in "${package_specs[@]}"; do
    pkg="${spec%%:*}"
    bin_name="${spec##*:}"

    if exists "$bin_name"; then
      log "npm CLI already available: $bin_name"
      continue
    fi

    log "Installing npm CLI: $pkg"
    npm install -g "$pkg" >/dev/null 2>&1 || warn "Failed to install $pkg"
  done
}

post_instructions() {
  cat <<'EOF'

------------------------------------------------------------
✅ User-local Ubuntu bootstrap complete.

Installed or configured:
• Node.js LTS via nvm
• uv, fzf, starship, ripgrep, fd, tmux, gh, Neovim
• tmux plugin manager (TPM), if git was available
• Symlinks:
    ~/.config/nvim          -> <repo>/config/nvim
    ~/.config/starship.toml -> <repo>/config/starship/starship.toml
    ~/.tmux.conf            -> <repo>/config/tmux/.tmux.conf
    ~/.gitconfig            -> <repo>/config/git/.gitconfig
    ~/.config/yazi          -> <repo>/config/yazi
• Shell bootstrap blocks were added to ~/.bashrc and ~/.zshrc

Notes:
• No sudo or apt-get was used.
• All binaries were installed under ~/.local/bin or ~/.local/opt.
• Existing regular files were backed up before symlinks were created.

Next steps:
• Restart the shell: exec $SHELL -l
• Verify:
    node -v
    npm -v
    uv --version
    gh --version | head -n 1
    tmux -V
    nvim --version | head -n 1
    rg --version | head -n 1
    fd --version | head -n 1
    starship --version

If tmux is already installed on the system:
• Start tmux, then press Ctrl+b followed by Shift+I to install plugins.
------------------------------------------------------------
EOF
}

main() {
  log "Starting Ubuntu bootstrap without sudo..."
  log "Using repository: $REPO_ROOT"

  require_tools
  warn_if_repo_not_in_home_dot
  install_uv
  install_nvm_and_node
  install_fzf
  install_ripgrep
  install_fd
  install_starship
  install_tmux
  install_gh
  install_neovim
  install_optional_tmux_plugins
  link_dot_configs
  configure_shell_rcs
  install_global_npm_clis
  post_instructions
}

main "$@"
