export TERM=xterm-256color
export EDITOR="nvim"

export CONDA_CHANGEPS1=false

act() {
  if [[ ! -z $(type micromamba) ]]; then
    micromamba activate $1
    PS1=""
    PS1+="\[\033[38;5;111m\]\h\[\033[0m\] \[\033[38;5;218m\]\w\[\033[0m\]\n"
    PS1+="\[\033[38;5;244m\]${CONDA_DEFAULT_ENV}\[\033[0m\] "
    PS1+="\$(x=\$?;[[ \"\$x\" == '0' ]] && echo \"\[\033[0;32m\]:) \[\033[0m\]\" || echo \"\[\033[0;31m\]:( \[\033[0m\]\")"
    export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib64:${LD_LIBRARY_PATH}
  elif [[ ! -z $(type mamba) ]]; then
    mamba activate $1
    PS1=""
    PS1+="\[\033[38;5;111m\]\h\[\033[0m\] \[\033[38;5;218m\]\w\[\033[0m\]\n"
    PS1+="\[\033[38;5;244m\]${CONDA_DEFAULT_ENV}\[\033[0m\] "
    PS1+="\$(x=\$?;[[ \"\$x\" == '0' ]] && echo \"\[\033[0;32m\]:) \[\033[0m\]\" || echo \"\[\033[0;31m\]:( \[\033[0m\]\")"
    export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib64:${LD_LIBRARY_PATH}
  elif [[ ! -z $(type conda) ]]; then
    conda activate $1
    PS1=""
    PS1+="\[\033[38;5;111m\]\h\[\033[0m\] \[\033[38;5;218m\]\w\[\033[0m\]\n"
    PS1+="\[\033[38;5;244m\]${CONDA_DEFAULT_ENV}\[\033[0m\] "
    PS1+="\$(x=\$?;[[ \"\$x\" == '0' ]] && echo \"\[\033[0;32m\]:) \[\033[0m\]\" || echo \"\[\033[0;31m\]:( \[\033[0m\]\")"
    export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib:${LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH=${CONDA_PREFIX}/lib64:${LD_LIBRARY_PATH}
  else
    >&2 echo ERROR! Command 'reduce' not found!
    exit -1
  fi
}
act ${CONDA_DEFAULT_ENV}

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

alias top="top -d 1"
alias Wc="wc"
alias Grep="grep"
alias ssh="ssh -X -Y"

source $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if { [ -n "$TMUX" ]; } then
    tmux source $HOME/dot/.config/tmux/.tmux.conf
fi

export PATH=$HOME/dot/bin:$PATH

set -o vi
