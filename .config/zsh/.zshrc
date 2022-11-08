export PATH="/usr/local/sbin:$PATH"
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

autoload -Uz compinit && compinit
_comp_options+=(globdots)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Prompt Settings
autoload colors && colors
if [[ ! -z $(type micromamba) ]]; then
  micromamba config set changeps1 False
elif [[ ! -z $(type conda) ]]; then
  conda config --set changeps1 False
fi

setopt prompt_subst

function precmd_conda_info() {
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
  local PROMPT=""
  PROMPT+="%b%F{244}${CONDA_ENV}"
  PROMPT+="%f%b%F{218}%~%f ${NEWLINE}"
  PROMPT+="%(?.%B%F{green}:).%B%F{red}:() %f%b"
  echo "$PROMPT"
}

PROMPT='$(precmd_conda_info)'

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim -u $HOME/dot/.config/nvim/init.lua"
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

zstyle ':completion:*:*:git:*' script $HOME/dot/completion/git-completion.bash
source $HOME/dot/completion/git-prompt.sh
fpath=(~/.zsh $fpath)
export GIT_PS1_SHOWDIRTYSTATE=1

# Tmux
if { [ -n "$TMUX" ]; } then
    tmux source $HOME/dot/.config/tmux/.tmux.conf
fi

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

export PATH=$HOME/dot/bin:$PATH

set -o vi
