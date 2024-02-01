export TERM=xterm-256color
export EDITOR="nvim"

if [[ -z $_HOME ]]; then
	export _HOME=$HOME
fi

if command -v micromamba &> /dev/null 
then
  micromamba config set changeps1 False
elif command -v conda &> /dev/null
then
  conda config --set changeps1 False
fi

precmd_conda_info() {
  if [[ -n $CONDA_PREFIX ]]; then
    if [[ $(basename $CONDA_PREFIX) == ".mamba" ]]; then
      local CONDA_ENV="base "
    else
      local CONDA_ENV="$(basename $CONDA_PREFIX) "
    fi
  else
    local CONDA_ENV=""
  fi

  local NEWLINE=$'\n'
  RET=$?
}

PROMPT_COMMAND=__prompt_command    # Function to generate PS1 after CMDs

__prompt_command() {
  local EXIT="$?"                # This needs to be first

  # Color
  local BLUE='\[\033[38;5;111m\]'
  local PINK='\[\033[38;5;218m\]'
  local GRAY='\[\033[38;5;244m\]'

  local GREEN='\[\033[0;32m\]'
  local RED='\[\033[0;31m\]'
  local NORMAL='\[\033[0m\]'

  PS1=""

  if [[ -n $CONDA_PREFIX ]]; then
    if [[ $(basename $CONDA_PREFIX) == ".mamba" ]]; then
      local CONDA_ENV="base "
    else
      local CONDA_ENV="$(basename $CONDA_PREFIX) "
    fi
  else
    local CONDA_ENV=""
  fi

  PS1+="${BLUE}\h${NORMAL} ${PINK}\w${NORMAL}\n"
  PS1+="${GRAY}${CONDA_ENV}${NORMAL}"

  if [ $EXIT != 0 ]; then
    PS1+="${RED}:( ${NORMAL}"
  else
    PS1+="${GREEN}:) ${NORMAL}"
  fi
}

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim"
alias sb="source $_HOME/.bashrc"
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

source $_HOME/dot/completion/git-completion.bash
source $_HOME/dot/completion/git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if { [ -n "$TMUX" ]; } then
    tmux source $_HOME/dot/config/tmux/.tmux.conf
fi

export PATH=$_HOME/dot/bin:$PATH

set -o vi
