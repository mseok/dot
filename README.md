# Dotfiles

Personal dotfiles for macOS and Ubuntu environments with modular configurations for development tools, window management, and AI-assisted coding.

## Quick Start (macOS)

```bash
# 1. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone this repository
git clone https://github.com/mseok/dot.git $HOME/dot

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

- **Terminal**: WezTerm with tmux integration
- **Shell**: Zsh/Bash with Starship prompt
- **Editor**: Neovim with native vim.pack plugin management, LSP, and AI completions
- **Window Management** (macOS): Aerospace + SketchyBar + SKHD + Borders
- **Development Tools**: Git, fzf, ripgrep, fd, Yazi file manager
- **AI Tools**: GitHub Copilot
- **Optional AI Integrations**: launchd-managed ChatGPT <-> Obsidian MCP bridge on macOS

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
brew tap koekeishiya/formulae # SKHD hotkey daemon

# Install all tools at once
brew install --cask wezterm aerospace
brew install neovim tmux git starship fzf ripgrep fd yazi \
             sketchybar borders skhd node python@3.11

# Start window management services (macOS only)
brew services start sketchybar
brew services start skhd
```

#### Tool Sources and Documentation

| Tool | Installation | Documentation |
|------|-------------|---------------|
| **WezTerm** | `brew install --cask wezterm` | [wezfurlong.org/wezterm](https://wezfurlong.org/wezterm/) |
| **Aerospace** | `brew install --cask nikitabobko/tap/aerospace` | [nikitabobko.github.io/AeroSpace](https://nikitabobko.github.io/AeroSpace/) |
| **SketchyBar** | `brew install sketchybar` | [felixkratz.github.io/SketchyBar](https://felixkratz.github.io/SketchyBar/) |
| **SKHD** | `brew install koekeishiya/formulae/skhd` | [github.com/koekeishiya/skhd](https://github.com/koekeishiya/skhd) |
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

#### Optional Integration Tools

```bash
# GitHub Copilot (requires subscription)
# Installed automatically via Neovim plugin

# Optional: public HTTPS tunnel for the ChatGPT <-> Obsidian MCP bridge
brew install ngrok
```

### Ubuntu Installation

Run the comprehensive bootstrap script:

```bash
# Clone the repository first
git clone https://github.com/mseok/dot.git $HOME/dot

# Run automated setup (installs all dependencies)
bash $HOME/dot/bin/initialize_ubuntu.sh
```

This script installs:
- Base packages (build-essential, curl, git, etc.)
- nvm + Node.js LTS
- fzf (with shell integration)
- Starship prompt
- Neovim (latest AppImage)
- UV (universal version manager)
- Symlinks configurations to `~/.config/`

For manual installation details, see `bin/initialize_ubuntu.sh`.

---

## Repository Setup

### 1. Clone the Repository

```bash
git clone https://github.com/mseok/dot.git $HOME/dot
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

# WezTerm terminal
ln -s $HOME/dot/config/wezterm $HOME/.config/wezterm

# VS Code (optional)
ln -s $HOME/dot/config/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
```

### 6. macOS Window Management

```bash
# Aerospace
ln -s $HOME/dot/config/aerospace/aerospace.toml $HOME/.aerospace.toml

# SketchyBar
ln -s $HOME/dot/config/sketchybar $HOME/.config/sketchybar

# SKHD (if you have it)
# Note: skhd config was removed in recent commits, but can be re-added
# ln -s $HOME/dot/config/skhd/skhdrc $HOME/.config/skhd/skhdrc

# Start services
brew services start aerospace
brew services start sketchybar
# brew services start skhd  # if you install skhd
```

---

## ChatGPT + Obsidian MCP Stack (macOS, optional)

This repository includes templates and an installer for a launchd-managed stack that keeps the following chain alive on macOS:

1. `Obsidian.app`
2. The `obsidian-local-rest-api` community plugin
3. `obsidian-mcp-server@2.0.7`
4. An `ngrok` HTTPS tunnel
5. A stable public MCP URL you can register in ChatGPT Developer mode

The generic `bin/setup_macos.sh` bootstrap does **not** enable this automatically because it depends on:

- a real Obsidian vault path
- a local Obsidian plugin API key
- an `ngrok` account and authtoken
- a user decision about which public MCP URL should be exposed

### Files in this Repository

The reusable source of truth lives in:

- `bin/install_chatgpt_obsidian_mcp.sh`
- `config/chatgpt-obsidian-mcp/settings.env.example`
- `config/chatgpt-obsidian-mcp/supervisor.zsh`
- `config/chatgpt-obsidian-mcp/status.zsh`
- `config/chatgpt-obsidian-mcp/sync-local-rest-config.zsh`
- `config/chatgpt-obsidian-mcp/chatgpt-obsidian-mcp.plist.template`

After installation, the live files are placed under:

- `~/Library/Application Support/chatgpt-obsidian-mcp/`
- `~/Library/LaunchAgents/local.chatgpt-obsidian-mcp.plist`

### New Machine Setup

If you want a new macOS machine to reproduce the same setup, use this order exactly.

#### 1. Run the normal macOS bootstrap first

```bash
git clone https://github.com/mseok/dot.git $HOME/dot
bash $HOME/dot/bin/setup_macos.sh
exec $SHELL -l
```

That gives you the base shell, Node.js, Homebrew, and the rest of the dotfiles environment.

#### 2. Install and open Obsidian

Install Obsidian in `/Applications/Obsidian.app`, then open the vault you want ChatGPT to access.

If you are using iCloud-synced vaults, make sure the vault is fully available on disk before continuing.

#### 3. Enable the Local REST API plugin inside the target vault

Inside Obsidian:

1. Install the community plugin `obsidian-local-rest-api`
2. Enable the plugin
3. Turn on the insecure HTTP server for simplicity
4. Note the vault path you want this machine to expose

The expected default local endpoint is:

```text
http://127.0.0.1:27123
```

#### 4. Install and authenticate ngrok

```bash
brew install ngrok
ngrok config add-authtoken <YOUR_NGROK_AUTHTOKEN>
```

Use the same `ngrok` account if you want the same dev domain behavior across machines.

#### 5. Install the dot-managed MCP stack

```bash
bash $HOME/dot/bin/install_chatgpt_obsidian_mcp.sh
```

This script does the following:

- creates `~/Library/Application Support/chatgpt-obsidian-mcp/`
- copies the supervisor/status/sync scripts into that directory
- installs `obsidian-mcp-server@2.0.7` into the same directory
- renders the LaunchAgent plist into `~/Library/LaunchAgents/`
- creates `settings.env` from the committed example if it does not already exist

#### 6. Edit the installed settings file

Edit:

```bash
$EDITOR "$HOME/Library/Application Support/chatgpt-obsidian-mcp/settings.env"
```

At minimum, set:

- `VAULT_PATH`
- `OBSIDIAN_APP`
- `NGROK_URL`

Example:

```bash
VAULT_PATH="$HOME/path/to/your/obsidian-vault"
OBSIDIAN_APP="/Applications/Obsidian.app"
REST_HOST="127.0.0.1"
MCP_HTTP_HOST="127.0.0.1"
MCP_HTTP_PORT="3010"
NGROK_URL="https://your-ngrok-domain.ngrok-free.dev"
```

`NGROK_URL` should be the public HTTPS endpoint you want ChatGPT to keep using. The MCP URL registered in ChatGPT will be:

```text
${NGROK_URL}/mcp
```

#### 7. Sync the Obsidian Local REST API key into the launchd-readable state file

The Local REST API plugin stores its own key inside the vault. The launchd process should not read the iCloud vault directly on every restart, so this setup copies the current plugin key/port into a separate local file.

Run:

```bash
$HOME/Library/Application Support/chatgpt-obsidian-mcp/bin/sync-local-rest-config.zsh
```

This generates:

```text
~/Library/Application Support/chatgpt-obsidian-mcp/local-rest.env
```

That file contains the Obsidian plugin API key and should stay local to the machine.

#### 8. Load the LaunchAgent

```bash
launchctl unload "$HOME/Library/LaunchAgents/local.chatgpt-obsidian-mcp.plist" >/dev/null 2>&1 || true
launchctl load -w "$HOME/Library/LaunchAgents/local.chatgpt-obsidian-mcp.plist"
```

This enables automatic startup on login.

#### 9. Verify the stack

```bash
$HOME/Library/Application Support/chatgpt-obsidian-mcp/bin/status.zsh
```

Healthy output should show:

- Obsidian running
- REST API listening on `127.0.0.1:27123` (or your configured port)
- MCP HTTP listening on `127.0.0.1:3010`
- a loaded LaunchAgent entry

#### 10. Register the MCP URL in ChatGPT

In ChatGPT Developer mode, register:

```text
https://your-ngrok-domain.ngrok-free.dev/mcp
```

The server itself is local, but ChatGPT requires an HTTPS MCP endpoint, so the `ngrok` tunnel is the external entrypoint.

### Operational Notes

#### What auto-recovers after login

The supervisor process waits for dependencies in the correct order:

1. Obsidian is opened if it is not already running
2. The Local REST API port is polled until available
3. `obsidian-mcp-server` is started
4. `ngrok` is started with the configured public URL

If one of those processes dies later, the supervisor restarts the stack.

#### What you must rerun manually

If any of the following change, rerun the sync script:

- the Obsidian Local REST API plugin API key
- the plugin port
- whether the plugin uses HTTP or HTTPS

Command:

```bash
$HOME/Library/Application Support/chatgpt-obsidian-mcp/bin/sync-local-rest-config.zsh
```

If `settings.env` changes, reload the LaunchAgent:

```bash
launchctl unload "$HOME/Library/LaunchAgents/local.chatgpt-obsidian-mcp.plist" >/dev/null 2>&1 || true
launchctl load -w "$HOME/Library/LaunchAgents/local.chatgpt-obsidian-mcp.plist"
```

#### Secret handling

Do **not** commit these machine-local files:

- `~/Library/Application Support/chatgpt-obsidian-mcp/local-rest.env`
- `~/Library/Application Support/ngrok/ngrok.yml`

They contain the Obsidian API key and the ngrok authtoken.

#### Debugging

Check:

- `~/Library/Application Support/chatgpt-obsidian-mcp/logs/launchd.out.log`
- `~/Library/Application Support/chatgpt-obsidian-mcp/logs/launchd.err.log`
- `~/Library/Application Support/chatgpt-obsidian-mcp/logs/mcp-server.log`
- `~/Library/Application Support/chatgpt-obsidian-mcp/logs/ngrok.log`

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
│   ├── chatgpt-obsidian-mcp/ # Templates for the launchd-managed MCP bridge
│   ├── starship/       # Starship prompt (XDG)
│   ├── wezterm/        # WezTerm terminal (XDG)
│   ├── yazi/           # Yazi file manager (XDG)
│   ├── aerospace/      # Aerospace WM (macOS)
│   ├── sketchybar/     # SketchyBar (macOS)
│   └── vscode/         # VS Code settings
└── bin/                # Utility scripts
    ├── install_chatgpt_obsidian_mcp.sh # Install launchd-managed Obsidian MCP stack
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
- **SKHD**: Hotkey daemon (`Alt+hjkl` navigation)
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
# Check service status
brew services list | grep -E 'aerospace|sketchybar|skhd'

# Restart services
brew services restart aerospace
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
