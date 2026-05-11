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
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

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

# Git Aliases
alias gs="git status"
alias gl="git pull"
alias gp="git push"
alias ga="git add ."
alias gcm="git commit -m "
alias glog="git log --graph --abbrev-commit --pretty=oneline"

alias grep="grep --color=auto"

zstyle ':completion:*:*:git:*' script $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
fpath=(~/.zsh $fpath)
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if command -v tmux &> /dev/null
then
    tmux set-environment -g _HOME $_HOME &> /dev/null
    tmux source $_HOME/dot/config/tmux/.tmux.conf &> /dev/null
fi

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

# slurm alias
source $HOME/dot/bin/slurm-commands.sh
source $HOME/dot/bin/utilities.sh

export PATH=$HOME/dot/bin:$PATH

if [[ -o interactive ]] && [[ -t 0 ]] && command -v codex >/dev/null 2>&1; then
    eval "$(codex completion zsh)"
fi

set -o vi

if [[ -o interactive && -t 1 ]]; then
    _dot_vi_cursor_set() {
        case "${KEYMAP:-}" in
            vicmd)
                printf '\e[2 q'  # steady block
                ;;
            *)
                printf '\e[6 q'  # steady bar
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
        printf '\e[6 q'
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
