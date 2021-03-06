export TERM=xterm-256color
export EDITOR="nvim"

# Basic Aliases
alias la="ls -a"

# Git Aliases
alias gs="git status"
alias gl="git pull"
alias gp="git push"
alias ga="git add ."
alias gcm="git commit -m "
alias glog="git log --graph --abbrev-commit --pretty=oneline"
alias vi="nvim -u $HOME/dot/.config/nvim/init.vim"
alias sb="source $HOME/dot/.config/bash/.bashrc"

# Functions
function jpt {
    jupyter-lab --no-browser --port=$1
}
function watcha {
    watch $(alias "$@" | cut -d\" -f2)
}

PS1=""
if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
    PS1+="($CONDA_DEFAULT_ENV) "
fi
PS1+="[\[\e[36;1m\]\u\[\033[00m\]@\[\e[32;1m\]\h\[\033[00m\]] \[\e[31;1m\]\w\[\033[33m\] \[\e[0m\]\n$ "

source $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; } then
    tmux source $INSTALL_DIR/.tmux.conf
fi
