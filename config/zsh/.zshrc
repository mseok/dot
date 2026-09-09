export DOTFILES_HOME="${DOTFILES_HOME:-$HOME/dot}"

if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

PATH="${PATH//\$HOME\/.codex\/bin/}"
PATH="${PATH//::/:}"
PATH="${PATH#:}"
PATH="${PATH%:}"

if [[ -d "$HOME/.bun/bin" ]]; then
    case ":$PATH:" in
        *":$HOME/.bun/bin:"*) ;;
        *) export PATH="$HOME/.bun/bin:$PATH" ;;
    esac
fi

if [[ -d "$HOME/.codex/bin" ]]; then
    case ":$PATH:" in
        *":$HOME/.codex/bin:"*) ;;
        *) export PATH="$HOME/.codex/bin:$PATH" ;;
    esac
fi

export PATH="/usr/local/sbin:$PATH"
if [[ -z "${TERM:-}" || "$TERM" == "dumb" ]]; then
    if [[ -n "${TMUX:-}" ]]; then
        export TERM="tmux-256color"
    else
        export TERM="xterm-256color"
    fi
fi
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"
export VISUAL="$EDITOR"

_personal_tag="${PERSONAL_TAG:-${USER:-}}"
if [[ -n "$_personal_tag" && -d "$HOME/$_personal_tag" ]]; then
    export _HOME="$HOME/$_personal_tag"
else
    export _HOME=$HOME
fi

autoload -Uz compinit && compinit
_comp_options+=(globdots)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim"
alias sz="source $HOME/.zshrc"
alias ta="tmux a -t"
alias tn="tmux new -s"
alias tl="tmux ls"

if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first"
    alias ll="eza -lah --group-directories-first"
    alias la="eza -a --group-directories-first"
    alias l="eza -l --group-directories-first"
fi

# Git Aliases
alias gs="git status"
alias gl="git pull"
alias gp="git push"
alias ga="git add ."
alias gcm="git commit -m "
alias glog="git log --graph --abbrev-commit --pretty=oneline"

alias grep="grep --color=auto"

zstyle ':completion:*:*:git:*' script "$DOTFILES_HOME/completion/git-completion.bash"
source "$DOTFILES_HOME/completion/git-prompt.sh"
fpath=(~/.zsh $fpath)
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if command -v tmux &> /dev/null
then
    tmux set-environment -g _HOME $_HOME &> /dev/null
    tmux source "$DOTFILES_HOME/config/tmux/.tmux.conf" &> /dev/null
fi

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# slurm alias
source "$DOTFILES_HOME/bin/slurm-commands.sh"
source "$DOTFILES_HOME/bin/utilities.sh"

export PATH="$DOTFILES_HOME/bin:$PATH"

if [[ -o interactive ]] && [[ -t 0 ]] && command -v codex >/dev/null 2>&1; then
    eval "$(codex completion zsh)"
fi

set -o vi

if command -v fzf >/dev/null 2>&1 && fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

y() {
    if ! command -v yazi >/dev/null 2>&1; then
        print -u2 "yazi is not installed or not on PATH"
        return 127
    fi

    local tmp cwd yazi_status
    tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return 1

    if [[ "${YAZI_FORCE_WEZTERM:-0}" == 1 ]]; then
        TERM_PROGRAM=WezTerm command yazi "$@" --cwd-file="$tmp"
    else
        command yazi "$@" --cwd-file="$tmp"
    fi
    yazi_status=$?

    if [[ -r "$tmp" ]]; then
        cwd="$(<"$tmp")"
        if [[ -n "$cwd" && -d "$cwd" && "$cwd" != "$PWD" ]]; then
            builtin cd -- "$cwd"
        fi
    fi
    rm -f "$tmp"
    return "$yazi_status"
}

yw() {
    YAZI_FORCE_WEZTERM=1 y "$@"
}

if [[ -o interactive && -t 1 ]]; then
    _dot_vi_cursor_set() {
        case "${KEYMAP:-}" in
            vicmd)
                printf '\e[2 q'  # steady block
                ;;
            *)
                printf '\e[5 q'  # blinking bar
                ;;
        esac
    }

    _dot_vi_cursor_keymap_select() {
        _dot_vi_cursor_set
    }

    _dot_vi_cursor_line_init() {
        _dot_vi_cursor_set
    }

    _dot_vi_cursor_line_finish() {
        printf '\e[5 q'
    }

    if [[ -z "${_DOT_VI_CURSOR_HOOKS_INSTALLED:-}" ]]; then
        autoload -Uz add-zle-hook-widget
        zle -N _dot_vi_cursor_keymap_select
        zle -N _dot_vi_cursor_line_init
        zle -N _dot_vi_cursor_line_finish
        add-zle-hook-widget keymap-select _dot_vi_cursor_keymap_select
        add-zle-hook-widget line-init _dot_vi_cursor_line_init
        add-zle-hook-widget line-finish _dot_vi_cursor_line_finish
        typeset -g _DOT_VI_CURSOR_HOOKS_INSTALLED=1
    fi
fi

if [[ -o interactive && -t 0 && -n "${TMUX:-}" && -x "$DOTFILES_HOME/bin/tmux-time-theme.sh" ]]; then
    "$DOTFILES_HOME/bin/tmux-time-theme.sh" >/dev/null 2>&1
    tmux run-shell -b "$DOTFILES_HOME/bin/tmux-time-theme.sh --watch" >/dev/null 2>&1
fi
