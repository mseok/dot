#!/usr/bin/env bash
# Purpose: Bootstrap a Linux user environment without sudo.
# Safety: Idempotent, user-owned paths, and safe to rerun for updates.

set -euo pipefail

log()   { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
error() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
exists(){ command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
export DOTFILES_HOME="${DOTFILES_HOME:-$REPO_ROOT}"

LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
LOCAL_OPT="${LOCAL_OPT:-$HOME/.local/opt}"
LOCAL_SHARE="${LOCAL_SHARE:-$HOME/.local/share}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dot-bootstrap"
NVM_DIR="${NVM_DIR:-$LOCAL_SHARE/nvm}"
PIXI_HOME="${PIXI_HOME:-$HOME/.pixi}"
PIXI_ENVIRONMENT="${PIXI_ENVIRONMENT:-dot-terminal}"
PIXI_MANIFEST="$REPO_ROOT/config/tools/pixi-terminal-packages.txt"
DOT_BOOTSTRAP_UPDATE="${DOT_BOOTSTRAP_UPDATE:-0}"

mkdir -p "$LOCAL_BIN" "$LOCAL_OPT" "$LOCAL_SHARE" "$CACHE_DIR" "$NVM_DIR"

if command -v git >/dev/null 2>&1; then
  HAVE_SYSTEM_GIT=1
else
  HAVE_SYSTEM_GIT=0
fi

NVM_VERSION="${NVM_VERSION:-v0.40.1}"
FZF_VERSION="${FZF_VERSION:-0.74.1}"
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
  for tool in bash tar uname chmod mktemp find awk sed readlink cp mv rm; do
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

latest_github_version() {
  local repository="$1"
  local payload tag

  if exists curl; then
    payload="$(curl -fsSL -H 'Accept: application/vnd.github+json' \
      "https://api.github.com/repos/$repository/releases/latest")" || return 0
  elif exists wget; then
    payload="$(wget -qO- --header='Accept: application/vnd.github+json' \
      "https://api.github.com/repos/$repository/releases/latest")" || return 0
  else
    return 0
  fi

  tag="$(printf '%s\n' "$payload" |
    awk -F '"' '/"tag_name"[[:space:]]*:/ { print $4; exit }')"
  tag="$(printf '%s' "$tag" | sed 's/^v//')"
  [[ -n "$tag" ]] && printf '%s\n' "$tag"
}

refresh_fallback_versions() {
  if [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
    return 0
  fi

  local latest refreshed=0
  latest="$(latest_github_version BurntSushi/ripgrep)"
  if [[ -n "$latest" ]]; then RIPGREP_VERSION="$latest"; refreshed=1; fi
  latest="$(latest_github_version sharkdp/fd)"
  if [[ -n "$latest" ]]; then FD_VERSION="$latest"; refreshed=1; fi
  latest="$(latest_github_version junegunn/fzf)"
  if [[ -n "$latest" ]]; then FZF_VERSION="$latest"; refreshed=1; fi
  latest="$(latest_github_version tmux/tmux-builds)"
  if [[ -n "$latest" ]]; then TMUX_VERSION="$latest"; refreshed=1; fi
  latest="$(latest_github_version cli/cli)"
  if [[ -n "$latest" ]]; then GH_VERSION="$latest"; refreshed=1; fi

  if [[ "$refreshed" -eq 1 ]]; then
    log "Refreshed fallback release versions from GitHub."
  else
    warn "Could not refresh fallback release versions; using configured defaults."
  fi
}

download_to() {
  local url="$1" dest="$2"
  local tmp="${dest}.tmp.$$"
  mkdir -p "$(dirname "$dest")"

  if exists curl; then
    if ! curl -fsSL "$url" -o "$tmp"; then
      rm -f "$tmp"
      return 1
    fi
  else
    if ! wget -qO "$tmp" "$url"; then
      rm -f "$tmp"
      return 1
    fi
  fi

  mv -f "$tmp" "$dest"
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
  *":${LOCAL_BIN}:"*) ;;
  *) export PATH="${LOCAL_BIN}:\$PATH" ;;
esac

export DOTFILES_HOME="$REPO_ROOT"
export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -f "${LOCAL_OPT}/fzf/shell/completion.bash" ] && source "${LOCAL_OPT}/fzf/shell/completion.bash"
[ -f "${LOCAL_OPT}/fzf/shell/key-bindings.bash" ] && source "${LOCAL_OPT}/fzf/shell/key-bindings.bash"
command -v starship >/dev/null 2>&1 && eval "\$(starship init bash)"
[ -f "$REPO_ROOT/config/bash/.bashrc" ] && source "$REPO_ROOT/config/bash/.bashrc"
EOF
  else
    cat <<EOF
case ":\$PATH:" in
  *":${LOCAL_BIN}:"*) ;;
  *) export PATH="${LOCAL_BIN}:\$PATH" ;;
esac

export DOTFILES_HOME="$REPO_ROOT"
export NVM_DIR="$NVM_DIR"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -f "${LOCAL_OPT}/fzf/shell/completion.zsh" ] && source "${LOCAL_OPT}/fzf/shell/completion.zsh"
[ -f "${LOCAL_OPT}/fzf/shell/key-bindings.zsh" ] && source "${LOCAL_OPT}/fzf/shell/key-bindings.zsh"
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
    warn "DOTFILES_HOME will be exported so shell integrations use this path"
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
    if [[ "$DOT_BOOTSTRAP_UPDATE" == "1" ]]; then
      log "Updating uv..."
      uv self update || warn "uv self-update failed; keeping the current uv."
    else
      log "uv already available: $(uv --version)"
    fi
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

  if [[ $has_node -eq 1 && "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
    log "Node.js already available: $(node -v)"
    return 0
  fi

  load_nvm
  if [[ "$DOT_BOOTSTRAP_UPDATE" == "1" && $has_nvm -eq 1 ]] && type nvm >/dev/null 2>&1; then
    log "Updating Node.js LTS via nvm..."
    nvm install --lts
    nvm alias default 'lts/*'
    return 0
  fi

  if [[ $has_nvm -eq 0 ]] || ! type nvm >/dev/null 2>&1; then
    if [[ $has_node -eq 1 ]]; then
      log "System Node.js is present; leaving it unchanged because nvm is unavailable."
      return 0
    fi
    error "nvm is unavailable, so Node.js LTS cannot be installed automatically."
    exit 1
  fi

  log "Installing Node.js LTS via nvm..."
  nvm install --lts
  nvm alias default 'lts/*'
}

install_pixi() {
  if [[ "${DOT_BOOTSTRAP_SKIP_PIXI:-0}" == "1" ]]; then
    log "Skipping Pixi installation (DOT_BOOTSTRAP_SKIP_PIXI=1)."
    return 0
  fi

  local pixi_bin="$PIXI_HOME/bin/pixi"
  if [[ -x "$pixi_bin" ]]; then
    ln -sfn "$pixi_bin" "$LOCAL_BIN/pixi"
    # Keep LOCAL_BIN as the stable public PATH surface. Individual tools are
    # mirrored below, so Pixi's private bin directory need not override a
    # cluster-provided Git or other system command.
    export PATH="$LOCAL_BIN:$PATH"
    if [[ "$DOT_BOOTSTRAP_UPDATE" == "1" ]]; then
      log "Updating Pixi..."
      "$pixi_bin" self-update || warn "Pixi self-update failed; keeping the current Pixi."
    else
      log "Pixi already available: $("$pixi_bin" --version)"
    fi
    return 0
  fi

  if exists pixi; then
    log "Using existing Pixi: $(command -v pixi)"
    return 0
  fi

  local installer="$CACHE_DIR/pixi-install.sh"
  log "Installing Pixi into $PIXI_HOME..."
  download_to "https://pixi.sh/install.sh" "$installer"
  PIXI_HOME="$PIXI_HOME" PIXI_NO_PATH_UPDATE=1 sh "$installer"

  if [[ ! -x "$pixi_bin" ]]; then
    warn "Pixi installer did not create $pixi_bin; optional image tools will be skipped."
    return 0
  fi

  ln -sfn "$pixi_bin" "$LOCAL_BIN/pixi"
  export PATH="$LOCAL_BIN:$PATH"
}

install_fzf() {
  local dest="$LOCAL_OPT/fzf"

  if exists fzf && [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
    log "fzf already available: $(fzf --version | head -n1)"
    return 0
  fi

  if exists pixi; then
    log "pixi is available; fzf will be installed with the optional terminal tools."
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

  # The fzf source checkout contains shell integration but not a built
  # executable. Fetch the official release binary when no package manager is
  # available to provide it.
  if [[ ! -x "$dest/bin/fzf" ]]; then
    local fzf_arch archive binary_tmp binary_path
    case "$(uname -m)" in
      x86_64|amd64) fzf_arch="amd64" ;;
      aarch64|arm64) fzf_arch="arm64" ;;
      *)
        warn "Unsupported architecture for bundled fzf: $(uname -m)"
        return 0
        ;;
    esac

    archive="$CACHE_DIR/fzf-${FZF_VERSION}.tar.gz"
    binary_tmp="$(mktemp -d)"
    download_to "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_${fzf_arch}.tar.gz" "$archive"
    tar -xzf "$archive" -C "$binary_tmp"
    binary_path="$(find "$binary_tmp" -type f -name fzf -perm -u+x | head -n1)"
    if [[ -n "$binary_path" ]]; then
      cp "$binary_path" "$dest/bin/fzf"
      chmod +x "$dest/bin/fzf"
    fi
    rm -rf "$binary_tmp"
  fi

  [[ -x "$dest/bin/fzf" ]] && ln -sfn "$dest/bin/fzf" "$LOCAL_BIN/fzf"
  [[ -f "$dest/bin/fzf-tmux" ]] && ln -sfn "$dest/bin/fzf-tmux" "$LOCAL_BIN/fzf-tmux"
}

install_binary_from_tarball() {
  local name="$1" url="$2" binary_name="$3"
  local archive="$CACHE_DIR/${name}.tar.gz"
  local tmpdir binary_path staged_binary

  tmpdir="$(mktemp -d)"
  download_to "$url" "$archive"
  tar -xzf "$archive" -C "$tmpdir"

  binary_path="$(find "$tmpdir" -type f -name "$binary_name" -perm -u+x | head -n1)"
  if [[ -z "$binary_path" ]]; then
    rm -rf "$tmpdir"
    error "Could not find ${binary_name} inside ${name} archive."
    exit 1
  fi

  # Replace the destination itself, rather than following a pre-existing
  # symlink to some unrelated user file.
  staged_binary="$LOCAL_BIN/.${binary_name}.tmp.$$"
  cp "$binary_path" "$staged_binary"
  chmod +x "$staged_binary"
  mv -f "$staged_binary" "$LOCAL_BIN/$binary_name"
  rm -rf "$tmpdir"
  log "Installed $binary_name -> $LOCAL_BIN/$binary_name"
}

install_ripgrep() {
  if exists rg && [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
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
  if exists fd && [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
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
  if exists starship && [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
    log "starship already available: $(starship --version)"
    return 0
  fi

  local installer="$CACHE_DIR/starship-install.sh"
  log "Installing starship into $LOCAL_BIN..."
  download_to "https://starship.rs/install.sh" "$installer"
  sh "$installer" -y -b "$LOCAL_BIN"
}

install_tmux() {
  if [[ -x "$LOCAL_BIN/tmux" && "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
    log "User-local tmux already available: $($LOCAL_BIN/tmux -V)"
    return 0
  fi

  if exists tmux; then
    if [[ "${DOT_BOOTSTRAP_FORCE_USER_TMUX:-0}" != "1" && "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
      log "tmux already available: $(tmux -V)"
      return 0
    fi
    log "Forcing user-local tmux despite the system tmux: ${TMUX_VERSION}"
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
  if exists gh && [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
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
  if exists nvim && [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
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

install_pixi_terminal_tools() {
  if [[ "${DOT_BOOTSTRAP_SKIP_PIXI:-0}" == "1" ]]; then
    log "Skipping optional Pixi terminal tools (DOT_BOOTSTRAP_SKIP_PIXI=1)."
    return 0
  fi

  if ! exists pixi && [[ ! -x "$PIXI_HOME/bin/pixi" ]]; then
    warn "pixi is unavailable; skipping optional Yazi/image tools."
    warn "Install pixi or set DOT_BOOTSTRAP_SKIP_PIXI=1, then rerun this script."
    return 0
  fi

  local package_args
  if [[ ! -f "$PIXI_MANIFEST" ]]; then
    warn "Pixi package manifest is missing: $PIXI_MANIFEST"
    return 0
  fi
  package_args="$(awk '!/^[[:space:]]*#/ && NF { printf "%s ", $1 }' "$PIXI_MANIFEST")"
  if [[ -z "$package_args" ]]; then
    warn "Pixi package manifest is empty: $PIXI_MANIFEST"
    return 0
  fi

  log "Installing optional terminal/image tools into Pixi environment '$PIXI_ENVIRONMENT'..."
  if ! PIXI_HOME="$PIXI_HOME" pixi global install \
      --environment "$PIXI_ENVIRONMENT" \
      --no-progress \
      $package_args; then
    warn "Pixi terminal/image tools failed to install; core bootstrap will continue."
    return 0
  fi

  if [[ "$DOT_BOOTSTRAP_UPDATE" == "1" ]]; then
    log "Updating the Pixi terminal environment..."
    PIXI_HOME="$PIXI_HOME" pixi global update "$PIXI_ENVIRONMENT" \
      || warn "Pixi global environment update failed; keeping installed packages."
  fi

  # Pixi exposes global applications from PIXI_HOME/bin. Mirror only the
  # user-facing executables into LOCAL_BIN so LOCAL_BIN remains the sole
  # PATH entry required by the shell bootstrap block.
  for tool in git yazi ya chafa magick convert ffmpeg pdftoppm pdftocairo resvg 7zz jq zoxide eza bat lazygit fzf; do
    if [[ "$tool" == "git" && "$HAVE_SYSTEM_GIT" -eq 1 ]]; then
      continue
    fi
    if [[ -x "$PIXI_HOME/bin/$tool" ]]; then
      ln -sfn "$PIXI_HOME/bin/$tool" "$LOCAL_BIN/$tool"
    fi
  done
}

install_optional_tmux_plugins() {
  if [[ -d "$HOME/.tmux/plugins/tpm/.git" ]]; then
    if [[ "$DOT_BOOTSTRAP_UPDATE" == "1" ]]; then
      log "Updating TPM..."
      git -C "$HOME/.tmux/plugins/tpm" pull --ff-only \
        || warn "Failed to update TPM; keeping the existing checkout."
    else
      log "TPM already installed."
    fi
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
  if ! exists tic; then
    warn "tic is unavailable; skipping user terminfo installation."
    warn "Basic xterm-256color still works, but advanced terminal capabilities may be limited."
    return 0
  fi

  mkdir -p "$HOME/.terminfo"
  tic -x -o "$HOME/.terminfo" "$REPO_ROOT/config/terminal/wezterm.src"
  tic -x -o "$HOME/.terminfo" "$REPO_ROOT/config/terminal/tmux-256color.src"
}

link_yazi_configs() {
  local config_dir="$HOME/.config/yazi"

  if [[ -L "$config_dir" ]]; then
    local current_target staging
    current_target="$(readlink "$config_dir")"
    if [[ "$current_target" != "$REPO_ROOT/config/yazi" ]]; then
      warn "Leaving unrelated Yazi config symlink untouched: $config_dir -> $current_target"
      return 0
    fi

    # Older bootstrap versions linked the whole directory, causing `ya pkg`
    # to write mutable plugin checkouts into the Git repository. Move those
    # checkouts aside before replacing the directory symlink with file links.
    staging="$HOME/.config/yazi.plugins.staging"
    if [[ -e "$staging" ]]; then
      backup_path "$staging"
    fi
    if [[ -d "$REPO_ROOT/config/yazi/plugins" ]]; then
      mv "$REPO_ROOT/config/yazi/plugins" "$staging"
    fi
    rm -f "$config_dir"
  elif [[ -e "$config_dir" && ! -d "$config_dir" ]]; then
    backup_path "$config_dir"
  fi

  mkdir -p "$config_dir"
  ensure_link "$REPO_ROOT/config/yazi/yazi.toml" "$config_dir/yazi.toml"
  ensure_link "$REPO_ROOT/config/yazi/keymap.toml" "$config_dir/keymap.toml"
  ensure_link "$REPO_ROOT/config/yazi/package.toml" "$config_dir/package.toml"

  if [[ -d "$HOME/.config/yazi.plugins.staging" ]]; then
    mv "$HOME/.config/yazi.plugins.staging" "$config_dir/plugins"
  fi
}

install_yazi_plugins() {
  if [[ "${DOT_BOOTSTRAP_SKIP_PLUGINS:-0}" == "1" ]]; then
    log "Skipping Yazi plugins (DOT_BOOTSTRAP_SKIP_PLUGINS=1)."
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

link_dot_configs() {
  ensure_link "$REPO_ROOT/config/nvim" "$HOME/.config/nvim"
  ensure_link "$REPO_ROOT/config/tmux/.tmux.conf" "$HOME/.tmux.conf"
  ensure_link "$REPO_ROOT/config/starship/starship.toml" "$HOME/.config/starship.toml"
  ensure_link "$REPO_ROOT/config/git/.gitconfig" "$HOME/.gitconfig"
  link_yazi_configs
}

install_global_npm_clis() {
  if [[ "${DOT_BOOTSTRAP_SKIP_NPM:-0}" == "1" ]]; then
    log "Skipping global npm CLIs (DOT_BOOTSTRAP_SKIP_NPM=1)."
    return 0
  fi

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
      if [[ "$DOT_BOOTSTRAP_UPDATE" != "1" ]]; then
        log "npm CLI already available: $bin_name"
        continue
      fi
      if ! npm list -g --depth=0 "$pkg" >/dev/null 2>&1; then
        log "CLI already available outside npm; leaving it unchanged: $bin_name"
        continue
      fi
      log "Updating npm CLI: $pkg"
    else
      log "Installing npm CLI: $pkg"
    fi
    npm install -g "${pkg}@latest" >/dev/null 2>&1 || warn "Failed to install/update $pkg"
  done
}

post_instructions() {
  cat <<'EOF'

------------------------------------------------------------
✅ User-local Linux bootstrap complete.

Installed or configured:
• Node.js LTS via nvm
• uv, fzf, starship, ripgrep, fd, tmux, gh, Neovim, Codex CLI
• Optional Pixi terminal tools: Git, Yazi, chafa, ImageMagick, ffmpeg, poppler,
  resvg, 7zip, jq, zoxide, eza, bat, lazygit
• tmux plugin manager (TPM), if git was available
• Symlinks:
    ~/.config/nvim          -> <repo>/config/nvim
    ~/.config/starship.toml -> <repo>/config/starship/starship.toml
    ~/.tmux.conf            -> <repo>/config/tmux/.tmux.conf
    ~/.gitconfig            -> <repo>/config/git/.gitconfig
    ~/.config/yazi/*.toml   -> <repo>/config/yazi/*.toml
• Shell bootstrap blocks were added to ~/.bashrc and ~/.zshrc

Notes:
• No sudo or apt-get was used.
• All binaries were installed under the configured user-owned bin/opt paths.
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

For image previews in WezTerm over SSH:
• Run: TERM_PROGRAM=WezTerm yazi (or use the `y`/`yw` shell helpers).
• In Yazi, press T to maximize the preview pane, + / - to zoom.
• Run `ya env` and check that the adapter is `Iip`.

If tmux is already installed on the system:
• Start tmux, then press Ctrl+b followed by Shift+I to install plugins.
------------------------------------------------------------
EOF
}

main() {
  log "Starting Linux bootstrap without sudo..."
  log "Using repository: $REPO_ROOT"

  require_tools
  refresh_fallback_versions
  warn_if_repo_not_in_home_dot
  install_pixi
  # Install Pixi's user-local tool set early. In particular, this can provide
  # Git on a truly minimal Linux image before TPM or any later Git operation.
  install_pixi_terminal_tools
  install_uv
  install_nvm_and_node
  install_fzf
  install_ripgrep
  install_fd
  install_starship
  install_tmux
  install_gh
  install_neovim
  install_color_profile
  install_optional_tmux_plugins
  link_dot_configs
  install_yazi_plugins
  if [[ "${DOT_BOOTSTRAP_SKIP_SHELL_RC:-0}" == "1" ]]; then
    log "Skipping shell rc changes (DOT_BOOTSTRAP_SKIP_SHELL_RC=1)."
  else
    configure_shell_rcs
  fi
  install_global_npm_clis
  post_instructions
}

main "$@"
