# Preserve the terminal-provided TERM. Only repair an absent/dumb TERM in an
# interactive shell; Yazi uses TERM/TERM_PROGRAM to select image protocols.
if [ -z "${TERM:-}" ] || [ "$TERM" = "dumb" ]; then
    if [ -n "${TMUX:-}" ]; then
        export TERM=tmux-256color
    else
        export TERM=xterm-256color
    fi
fi

case ":${PATH:-}:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:${PATH:-}" ;;
esac
export EDITOR="nvim"
export VISUAL="$EDITOR"

if command -v micromamba &>/dev/null; then
    micromamba config set changeps1 False
elif command -v conda &>/dev/null; then
    conda config --set changeps1 False
fi

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim"
alias sb="source $HOME/.bashrc"
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

alias top="top -d 1"
alias Wc="wc"
alias grep="grep --color=auto"
alias Grep="grep"
alias sshx="command ssh -X -Y"

source $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

# slurm alias
source $HOME/dot/bin/slurm-commands.sh

export PATH=$HOME/dot/bin:$PATH

set -o vi

if command -v fzf >/dev/null 2>&1 && fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

y() {
    if ! command -v yazi >/dev/null 2>&1; then
        echo "yazi is not installed or not on PATH" >&2
        return 127
    fi

    local tmp cwd yazi_status
    tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return 1

    if [ "${YAZI_FORCE_WEZTERM:-0}" = 1 ]; then
        TERM_PROGRAM=WezTerm command yazi "$@" --cwd-file="$tmp"
    else
        command yazi "$@" --cwd-file="$tmp"
    fi
    yazi_status=$?

    if [ -r "$tmp" ]; then
        cwd="$(<"$tmp")"
        if [ -n "$cwd" ] && [ -d "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
    fi
    rm -f "$tmp"
    return "$yazi_status"
}

yw() {
    YAZI_FORCE_WEZTERM=1 y "$@"
}

agy() {
    local agy_bin=$(find ~/.antigravity-server/bin -name "agy" -path "*/remote-cli/agy" 2>/dev/null | head -n 1)
    if [ -n "$agy_bin" ]; then
        VSCODE_IPC_HOOK_CLI=$(ls -tr /run/user/$UID/vscode-ipc-* | tail -n 1) "$agy_bin" "$@"
    else
        echo "Error: agy executable not found"
        return 1
    fi
}

uv() {
    if [[ "$1" == "add" || "$1" == "remove" || "$1" == "sync" ]]; then
        export VIRTUAL_ENV=$CONDA_PREFIX
        command uv "$@" --active
    else
        command uv "$@"
    fi
}
