export TERM=xterm-256color
export EDITOR="nvim"

export CONDA_CHANGEPS1=false
# $CONDA_DEFAULT_ENV
smiley() {
  if [ "$?" == "0" ]; then
    echo -e '\033[0;32m:) \033[0m'
  else
    echo -e '\033[0;31m:( \033[0m'
  fi
}
PS1=""
PS1+="\[\033[38;5;244m${CONDA_DEFAULT_ENV}\[\033[0m "
PS1+="\[\033[38;5;218m\w\[\033[0m\n"
PS1+='$(smiley)'

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim -u $HOME/dot/.config/nvim/init.lua"
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

source $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if { [ -n "$TMUX" ]; } then
    tmux source $HOME/dot/.config/tmux/.tmux.conf
fi

export PATH=$HOME/dot/bin:$PATH
