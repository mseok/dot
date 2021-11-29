export TERM=xterm-256color
export EDITOR="nvim"

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
# alias vi="nvim -u $HOME/dot/.config/nvim/init.vim"
alias vi="nvim -u $HOME/dot/.config/nvim/init.lua"
alias sb="source $HOME/dot/.config/bash/.bashrc"
alias ta="tmux a -t"
alias tn="tmux new -s"
alias tl="tmux ls"
if [ ! -x "$(command -v foo)" ]; then
    if [ ! -d "$HOME/.config/alacrity" ]; then
        alias reload="cp $HOME/dot/.config/alacritty/alacritty.yml $HOME/.config/alacritty"
    fi
fi

# Git Aliases
alias gs="git status"
alias gl="git pull"
alias gp="git push"
alias ga="git add ."
alias gcm="git commit -m "
alias glog="git log --graph --abbrev-commit --pretty=oneline"

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
if { [ -n "$TMUX" ]; } then
    tmux source $HOME/dot/.config/tmux/.tmux.conf
fi

export PATH=$HOME/dot/bin:$PATH
