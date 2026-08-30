# Dotfiles

Personal dotfiles for macOS and Ubuntu environments with modular configurations for development tools, window management, and AI-assisted coding.

## Quick Start (macOS)

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone this repository
git clone https://github.com/<owner>/dot.git $HOME/dot

# 3. Run the macOS setup script (installs all dependencies)
$HOME/dot/bin/setup_macos.sh

# 4. Restart your shell
exec $SHELL -l
```

For Ubuntu, see [Ubuntu Installation](#ubuntu-installation) below.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Tool Installation](#tool-installation)
  - [macOS Installation](#macos-installation)
  - [Ubuntu Installation](#ubuntu-installation)
- [Repository Setup](#repository-setup)
- [ChatGPT + Obsidian MCP Stack](#chatgpt--obsidian-mcp-stack-macos-optional)
- [Configuration Details](#configuration-details)
- [Troubleshooting](#troubleshooting)

---

## Overview

This repository provides a comprehensive development environment setup including:

- **Terminal**: Kaku with tmux integration
- **Shell**: Zsh/Bash with Starship prompt
- **Editor**: Neovim with native vim.pack plugin management, LSP, and AI completions
- **Window Management** (macOS): AeroSpace + SketchyBar + Borders
- **Development Tools**: Git, fzf, ripgrep, fd, Yazi file manager
- **AI Tools**: GitHub Copilot
- **Optional AI Integrations**: private single-writer Obsidian MCP gateway on macOS

All configurations follow the XDG Base Directory specification (`~/.config/`).

---

## Prerequisites

### macOS Requirements

1. **macOS** 12.0 (Monterey) or later
2. **Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```
3. **Homebrew** (package manager):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

### Ubuntu Requirements

- **Ubuntu** 20.04 LTS or later
- **curl** and **git** (usually pre-installed)

---

## Tool Installation

### macOS Installation

#### Core Tools

Install all core dependencies via Homebrew:

```bash
# Add taps for specialized tools
brew tap nikitabobko/tap      # Aerospace window manager
brew tap FelixKratz/formulae  # SketchyBar & Borders
brew tap tw93/tap             # Kaku terminal

# Install all tools at once
brew install --cask tw93/tap/kakuku aerospace
brew install neovim tmux git starship fzf ripgrep fd yazi \
             sketchybar borders node python@3.11

# Start window management services (macOS only)
brew services start sketchybar
open -a AeroSpace
```

#### Tool Sources and Documentation

| Tool | Installation | Documentation |
|------|-------------|---------------|
| **Kaku** | `brew install --cask tw93/tap/kakuku` | [github.com/tw93/Kaku](https://github.com/tw93/Kaku) |
| **Aerospace** | `brew install --cask nikitabobko/tap/aerospace` | [nikitabobko.github.io/AeroSpace](https://nikitabobko.github.io/AeroSpace/) |
| **SketchyBar** | `brew install sketchybar` | [felixkratz.github.io/SketchyBar](https://felixkratz.github.io/SketchyBar/) |
| **Borders** | `brew install FelixKratz/formulae/borders` | [github.com/FelixKratz/JankyBorders](https://github.com/FelixKratz/JankyBorders) |
| **Neovim** | `brew install neovim` | [neovim.io](https://neovim.io/) |
| **Tmux** | `brew install tmux` | [github.com/tmux/tmux](https://github.com/tmux/tmux) |
| **Starship** | `brew install starship` | [starship.rs](https://starship.rs/) |
| **fzf** | `brew install fzf` | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **ripgrep** | `brew install ripgrep` | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **fd** | `brew install fd` | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| **Yazi** | `brew install yazi` | [yazi-rs.github.io](https://yazi-rs.github.io/) |
| **Node.js** | `brew install node` | [nodejs.org](https://nodejs.org/) |
| **Python** | `brew install python@3.11` | [python.org](https://www.python.org/) |

### Ubuntu Installation

Run the comprehensive bootstrap script:

```bash
# Clone the repository first
git clone https://github.com/<owner>/dot.git $HOME/dot

# Run automated setup (user-local install, no sudo required)
bash $HOME/dot/bin/initialize_ubuntu.sh
```

This script installs:
- User-local tools under `~/.local/bin` / `~/.local/opt`
- nvm + Node.js LTS
- fzf (with shell integration)
- Starship prompt
- tmux
- GitHub CLI (`gh`)
- Neovim (latest AppImage)
- UV (universal version manager)
- ripgrep + fd
- Symlinks configurations to `~/.config/`

For manual installation details, see `bin/initialize_ubuntu.sh`.

---

## Repository Setup

### 1. Clone the Repository

```bash
git clone https://github.com/<owner>/dot.git $HOME/dot
```

### 2. Shell Configuration

#### Zsh (recommended)

```bash
# Backup existing config
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

# Source dotfiles
echo 'source $HOME/dot/config/zsh/.zshrc' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

#### Bash

```bash
# Backup existing config
cp ~/.bashrc ~/.bashrc.backup 2>/dev/null || true

# Source dotfiles
echo 'source $HOME/dot/config/bash/.bashrc' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

### 3. Neovim Configuration

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.backup 2>/dev/null || true

# Create symlink using XDG_CONFIG_HOME pattern
ln -s $HOME/dot/config/nvim $HOME/.config/nvim

# Install Neovim plugins (will auto-install on first launch)
nvim +qa
```

### 4. Tmux Configuration

```bash
# Install TPM (Tmux Plugin Manager)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Link tmux config
ln -s $HOME/dot/config/tmux/.tmux.conf $HOME/.tmux.conf

# Install plugins (inside tmux)
# Press: Ctrl+b then Shift+I
```

### 5. Other Tool Configurations (XDG Pattern)

The following configurations are automatically detected when tools use `XDG_CONFIG_HOME`:

```bash
# Git config
ln -s $HOME/dot/config/git/.gitconfig $HOME/.gitconfig

# Starship prompt
ln -s $HOME/dot/config/starship/starship.toml $HOME/.config/starship.toml

# Yazi file manager
ln -s $HOME/dot/config/yazi $HOME/.config/yazi

# Kaku terminal
mkdir -p $HOME/.config/kaku
ln -s $HOME/dot/config/kaku/kaku.lua $HOME/.config/kaku/kaku.lua
ln -s $HOME/dot/config/kaku/assistant.toml $HOME/.config/kaku/assistant.toml

# VS Code (optional)
ln -s $HOME/dot/config/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
```

### 6. macOS Window Management

```bash
# AeroSpace
ln -s $HOME/dot/config/aerospace $HOME/.config/aerospace

# SketchyBar
ln -s $HOME/dot/config/sketchybar $HOME/.config/sketchybar

# Start AeroSpace as an application and SketchyBar as a service
open -a AeroSpace
brew services start sketchybar
```

---

## Obsidian MCP (macOS, optional)

This dotfiles repository does not install an Obsidian REST API, ngrok tunnel, or a public MCP endpoint. The retired `local.chatgpt-obsidian-mcp` stack has been removed.

The current system uses the private `obsidian-mcp-gateway` and `obsidian-main-plugin` projects. It runs as the local `local.obsidian-mcp-gateway` LaunchAgent on `127.0.0.1:39123`; Codex connects through `obsidian_main`.

- The iCloud vault is canonical. `Notes/` is human-owned and read-only for agents.
- Agent-created records belong under `Inbox/Agents/<authenticated-host>/` through the gateway.
- Check local availability with `curl -fsS http://127.0.0.1:39123/healthz` and Codex registration with `codex mcp list`.
- Do not restore the retired REST/ngrok scripts from older revisions of this repository.

---

## Configuration Details

### XDG Base Directory Specification

This repository follows the [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) specification:

- **`XDG_CONFIG_HOME`**: `~/.config` (default) - User-specific configuration files
- **`XDG_DATA_HOME`**: `~/.local/share` (default) - User-specific data files
- **`XDG_CACHE_HOME`**: `~/.cache` (default) - User-specific cache files

Most modern CLI tools automatically check `~/.config/<tool-name>/` for configurations. By symlinking from `$HOME/dot/config/<tool>/` to `~/.config/<tool>/`, you ensure:
1. Clean home directory (no dot-file clutter)
2. Easy backup and version control
3. Portable configurations across machines

### Directory Structure

```
dot/
├── config/              # All tool configurations
│   ├── nvim/           # Neovim (XDG)
│   ├── tmux/           # Tmux
│   ├── zsh/            # Zsh shell
│   ├── bash/           # Bash shell
│   ├── git/            # Git config
│   ├── starship/       # Starship prompt (XDG)
│   ├── kaku/           # Kaku terminal (XDG)
│   ├── yazi/           # Yazi file manager (XDG)
│   ├── aerospace/      # Aerospace WM (macOS)
│   ├── sketchybar/     # SketchyBar (macOS)
│   └── vscode/         # VS Code settings
└── bin/                # Utility scripts
    ├── initialize_ubuntu.sh     # Ubuntu bootstrap
    ├── tmux-*.sh               # Tmux utilities
    └── utilities.sh            # Cross-platform helpers
```

### Key Features

#### Neovim
- **Plugin Manager**: Native `vim.pack` (no external managers)
- **LSP**: Mason for language server installation (Pyright, Ruff, Lua LS, Bash LS)
- **Completion**: Blink.cmp with Vim-style navigation
- **AI**: GitHub Copilot with Claude Haiku 4.5
- **File Explorer**: Oil.nvim (press `-`)
- **Fuzzy Finder**: Telescope (`<leader>ff`, `<leader>fg`)

#### macOS Window Management
- **Aerospace**: i3-like tiling window manager
- **SketchyBar**: Custom menu bar with workspace indicators
- **Borders**: Window focus visualization

#### Shell Environment
- **Cross-platform clipboard**: pbcopy (macOS) → xclip → OSC52 fallbacks
- **Git integration**: Branch display, custom aliases
- **Tmux helpers**: Session management, pane navigation with zoom

---

## Troubleshooting

### Common Issues

#### "command not found" after installation

```bash
# Reload shell configuration
exec $SHELL -l

# Or manually source
source ~/.zshrc  # or ~/.bashrc
```

#### Neovim plugins not loading

```bash
# Check health
nvim
:checkhealth

# Manually install plugins (plugins are in vim.pack)
# They should auto-install on first launch
# Check: ~/.local/share/nvim/site/pack/
```

#### Tmux plugins not working

```bash
# Install TPM if missing
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux, press: Ctrl+b then Shift+I
# This installs all plugins listed in .tmux.conf
```

#### macOS window management not starting

```bash
# Check app/service status
pgrep -fl '/Applications/AeroSpace.app'
brew services list | grep sketchybar

# Restart AeroSpace and SketchyBar
osascript -e 'tell application "AeroSpace" to quit'
open -a AeroSpace
brew services restart sketchybar

# Check logs
tail -f /usr/local/var/log/sketchybar.log
```

#### LSP servers not working in Neovim

```bash
# Open Neovim and install LSP servers
nvim
:Mason

# Install required servers:
# - pyright (Python)
# - ruff (Python linting)
# - lua_ls (Lua)
# - bashls (Bash)
```

### Performance Issues

If Neovim feels slow:

```bash
# Check startup time
nvim --startuptime startup.log
tail startup.log

# Disable Copilot temporarily
# In Neovim: :Copilot disable
```

---

## Additional Resources

- **Neovim Docs**: `:help` inside Neovim
- **Tmux Docs**: `man tmux`
- **Aerospace Guide**: https://nikitabobko.github.io/AeroSpace/guide
- **SketchyBar Config**: https://felixkratz.github.io/SketchyBar/config/
- **Starship Config**: https://starship.rs/config/
