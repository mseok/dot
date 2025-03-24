if [ -n "$TMUX" ]; then
    export TERM=tmux-256color
else
    export TERM=xterm-256color
fi
export EDITOR="nvim"

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
alias ssh="ssh -X -Y"

source $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

# slurm alias
source $HOME/dot/bin/slurm-commands.sh

export PATH=$HOME/dot/bin:$PATH

set -o vi
