# Dotfiles

Personal dotfiles for macOS, Linux, and sudo-less HPC environments with modular configurations for development tools, window management, and AI-assisted coding.

## Quick Start (macOS/Linux)

After reviewing the bootstrap script, a fresh machine can be installed with:

```bash
curl -fsSL https://raw.githubusercontent.com/mseok/dot/main/bootstrap.sh | bash
```

This clones the repository into `$HOME/dot` and dispatches to the correct
platform installer. On macOS, Homebrew is the only step that may still need
the normal administrator/password confirmation:

```bash
curl -fsSL https://raw.githubusercontent.com/mseok/dot/main/bootstrap.sh | bash -s -- --install-homebrew
```

The safer reviewed form is equivalent but keeps the repository visible:

```bash
git clone https://github.com/mseok/dot.git $HOME/dot
$HOME/dot/install.sh
exec $SHELL -l
```

The installer is idempotent. Existing regular config files are backed up before
links are created, while an existing non-empty directory is never overwritten.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Tool Installation](#tool-installation)
  - [macOS Installation](#macos-installation)
  - [Linux/HPC Installation](#linuxhpc-installation)
- [Updates and version compatibility](#updates-and-version-compatibility)
- [Codex and HPC policy](#codex-and-hpc-policy)
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
- **Window Management** (macOS): AeroSpace + SketchyBar + Borders
- **Development Tools**: Git, eza, fzf, ripgrep, fd, Yazi file manager
- **AI Tools**: GitHub Copilot
- **Codex**: portable AGENTS policy, HPC rules, and repository-owned skills
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
3. Network access for Homebrew and the package downloads. The installer can
   install Homebrew itself with `--install-homebrew`.

### Linux/HPC Requirements

- A POSIX Linux account with Bash, `curl` or `wget`, `tar`, and a writable home
  or user-owned application directory.
- `sudo` and `apt` are not required. The bootstrap installs Pixi, terminal
  tools, and configuration under user-owned paths.
- For an HPC login node, set `LOCAL_BIN`, `LOCAL_OPT`, `LOCAL_SHARE`, and/or
  `PIXI_HOME` to persistent parallel storage if the home quota is small.

---

## Tool Installation

### macOS Installation

#### Core Tools

The checked-in [`Brewfile`](Brewfile) is the macOS desired state. The setup
script runs:

```bash
brew bundle install --file=$HOME/dot/Brewfile --no-upgrade
```

It includes WezTerm, Neovim, tmux, Yazi plus the image-preview dependencies
(ImageMagick, chafa, ffmpeg, poppler, resvg), and the terminal workflow tools.
The normal macOS window-management services are started on a fresh install;
use `$HOME/dot/install.sh --no-services` when setting up without launching them.

#### Tool Sources and Documentation

| Tool | Installation | Documentation |
|------|-------------|---------------|
| **WezTerm** | `brew install --cask wezterm` | [wezfurlong.org/wezterm](https://wezfurlong.org/wezterm/) |
| **Codex CLI** | `brew install --cask codex` | [github.com/openai/codex](https://github.com/openai/codex) |
| **Aerospace** | `brew install --cask nikitabobko/tap/aerospace` | [nikitabobko.github.io/AeroSpace](https://nikitabobko.github.io/AeroSpace/) |
| **SketchyBar** | `brew install sketchybar` | [felixkratz.github.io/SketchyBar](https://felixkratz.github.io/SketchyBar/) |
| **Borders** | `brew install FelixKratz/formulae/borders` | [github.com/FelixKratz/JankyBorders](https://github.com/FelixKratz/JankyBorders) |
| **Neovim** | `brew install neovim` | [neovim.io](https://neovim.io/) |
| **Tmux** | `brew install tmux` | [github.com/tmux/tmux](https://github.com/tmux/tmux) |
| **GitHub CLI** | `brew install gh` | [cli.github.com](https://cli.github.com/) |
| **Starship** | `brew install starship` | [starship.rs](https://starship.rs/) |
| **eza** | `brew install eza` | [github.com/eza-community/eza](https://github.com/eza-community/eza) |
| **fzf** | `brew install fzf` | [github.com/junegunn/fzf](https://github.com/junegunn/fzf) |
| **ripgrep** | `brew install ripgrep` | [github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep) |
| **fd** | `brew install fd` | [github.com/sharkdp/fd](https://github.com/sharkdp/fd) |
| **Yazi** | `brew install yazi` | [yazi-rs.github.io](https://yazi-rs.github.io/) |
| **Node.js** | `brew install node` | [nodejs.org](https://nodejs.org/) |
| **Python** | `brew install python@3.11` | [python.org](https://www.python.org/) |
| **uv** | `brew install uv` | [docs.astral.sh/uv](https://docs.astral.sh/uv/) |

### Linux/HPC Installation

Run the comprehensive bootstrap script:

```bash
# Clone the repository first
git clone https://github.com/mseok/dot.git $HOME/dot

# Run automated setup (user-local install, no sudo required)
$HOME/dot/install.sh
```

This script installs:
- User-local tools under `~/.local/bin` / `~/.local/opt` (overridable)
- nvm + Node.js LTS
- Pixi + a global `dot-terminal` environment for Git, Yazi, and image previews
- fzf (with shell integration)
- Starship prompt
- tmux
- GitHub CLI (`gh`)
- Neovim (latest AppImage)
- UV (universal version manager)
- ripgrep + fd
- Symlinks configurations to `~/.config/`
- User terminfo entries for WezTerm and tmux when `tic` is available

For manual installation details and environment overrides, see
`bin/initialize_ubuntu.sh`.

---

## Updates and version compatibility

Check the current machine without changing anything:

```bash
$HOME/dot/bin/update_environment.sh --check
```

Apply a fast-forward-only repository update and then reconcile the platform
packages/configuration:

```bash
$HOME/dot/bin/update_environment.sh --apply
```

Optional plugin updates are explicit because plugin APIs can change more
quickly than the base applications:

```bash
$HOME/dot/bin/update_environment.sh --apply --plugins
```

The update command refuses tracked or untracked Git changes, never resets or
force-pulls, and does not restart the existing macOS window-management apps by
default. It validates tmux and WezTerm configuration after the update. If an
application release requires a config migration, the repository change should
be reviewed as a normal Git diff; arbitrary upstream version changes cannot be
made safely by a generic script.

Package policy:

- macOS: `Brewfile` is the desired package set. Homebrew resolves current
  compatible versions, including the Codex CLI cask; `--apply` uses `brew
  bundle ... --upgrade`.
- Linux/HPC: `config/tools/pixi-terminal-packages.txt` is the user-local
  terminal/image package set. Pixi keeps the global `dot-terminal` environment
  and `--apply` runs `pixi global update dot-terminal`.
- Linux/HPC Codex CLI is installed through the user-local nvm/npm toolchain and
  refreshed to `@openai/codex@latest` during `--apply`.
- Neovim and Yazi plugin lock/state are not silently rewritten during a normal
  update. Pass `--plugins` when you explicitly want those updates.

No background updater is installed by default: unattended upgrades can change
an active terminal or invalidate a plugin while an HPC job is running. If you
want fully unattended updates, schedule `bin/update_environment.sh --apply`
with a user-level launchd/systemd/cron mechanism appropriate to that machine.

For a smaller home quota on HPC, keep the repository and package cache on
parallel storage, for example:

```bash
LOCAL_BIN=/mnt/parallel_storage/$USER/appl/bin \
LOCAL_OPT=/mnt/parallel_storage/$USER/appl/opt \
PIXI_HOME=/mnt/parallel_storage/$USER/appl/pixi \
$HOME/dot/install.sh
```

## Codex and HPC policy

The installer also configures the portable part of Codex. On Linux/HPC it
installs or refreshes:

- `$CODEX_HOME/AGENTS.md` as a link to `ai/codex/AGENTS.md`;
- `$CODEX_HOME/rules/hpc.rules` as a link to the repository policy; and
- each repository-owned skill as an individual link below
  `$CODEX_HOME/skills/`.

Individual skill links are intentional. Codex-managed system skills stay in
`$CODEX_HOME/skills/.system` rather than turning the source checkout into an
application-data directory. A legacy whole-directory `~/.codex/skills` link is
migrated automatically on the next install, with existing `.system` skills
preserved.

The installer does not copy `$CODEX_HOME/config.toml`, authentication, MCP
registrations, project trust, databases, or other host-local state. Those files
contain machine-specific paths and permissions and should not be shared
between macOS and an HPC login node.

`AGENTS.override.md` is different from the portable base: it may contain
cluster-specific storage and scheduler facts. Existing overrides are preserved.
For a reviewed override that has already been generated or audited, install it
explicitly:

```bash
$HOME/dot/bin/install_codex.sh \
  --override-from /path/to/AGENTS.override.md
```

On a new Slurm cluster, invoke the installed `init-slurm-environment` skill for
the explicit topology audit before creating an override. The installer does
not guess partitions, node capabilities, or `/home`/scratch paths. This keeps a
fresh bare-Linux install useful without embedding facts from one cluster into
another.

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

# Yazi file manager configuration files
mkdir -p ~/.config/yazi
ln -s $HOME/dot/config/yazi/yazi.toml ~/.config/yazi/yazi.toml
ln -s $HOME/dot/config/yazi/keymap.toml ~/.config/yazi/keymap.toml
ln -s $HOME/dot/config/yazi/package.toml ~/.config/yazi/package.toml
# Keep mutable plugin checkouts in ~/.config/yazi/plugins, outside Git.

# WezTerm terminal
ln -s $HOME/dot/config/wezterm $HOME/.config/wezterm

# VS Code (optional)
ln -s $HOME/dot/config/vscode/settings.json "$HOME/Library/Application Support/Code/User/settings.json"
```

WezTerm follows the macOS appearance automatically: Catppuccin Latte in Light
mode and Catppuccin Mocha in Dark mode. macOS's automatic appearance schedule
therefore controls the terminal transition as well. Neovim switches between its
TokyoNight day/night variants on its own schedule while running; ANSI-based
applications such as Starship and Yazi follow the terminal palette.

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
├── Brewfile              # macOS desired package state
├── bootstrap.sh          # clone-then-install entrypoint
├── install.sh            # platform dispatcher
├── config/              # All tool configurations
│   ├── nvim/           # Neovim (XDG)
│   ├── tmux/           # Tmux
│   ├── zsh/            # Zsh shell
│   ├── bash/           # Bash shell
│   ├── git/            # Git config
│   ├── starship/       # Starship prompt (XDG)
│   ├── wezterm/        # WezTerm terminal (XDG)
│   ├── yazi/           # Yazi file manager (XDG)
│   ├── aerospace/      # Aerospace WM (macOS)
│   ├── sketchybar/     # SketchyBar (macOS)
│   ├── vscode/         # VS Code settings
│   └── tools/          # Linux/Pixi package manifest
└── bin/                # Utility scripts
    ├── initialize_ubuntu.sh     # Linux/HPC bootstrap
    ├── setup_macos.sh            # macOS bootstrap
    ├── install_codex.sh          # Codex base/rules/skills installer
    ├── update_environment.sh     # safe update/check entrypoint
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

Then inspect the managed environment:

```bash
$HOME/dot/bin/update_environment.sh --check
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
