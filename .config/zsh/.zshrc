export PATH="/usr/local/sbin:$PATH"
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

autoload -Uz compinit && compinit
_comp_options+=(globdots)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Prompt Settings
autoload colors && colors
export CONDA_CHANGEPS1=false
NEWLINE=$'\n'

act() {
  if [[ ! -z $(type mamba) || ! -z $(type micromamba) ]]; then
    mamba activate $1
    PROMPT=""
    PROMPT+="%b%F{244}${CONDA_DEFAULT_ENV} %f"
    PROMPT+="%b%F{218}%~%f ${NEWLINE}"
    PROMPT+="%(?.%B%F{green}:).%B%F{red}:() %f%b"
  elif [[ ! -z $(type conda) ]]; then
    conda activate $1
    PROMPT=""
    PROMPT+="%b%F{244}${CONDA_DEFAULT_ENV} %f"
    PROMPT+="%b%F{218}%~%f ${NEWLINE}"
    PROMPT+="%(?.%B%F{green}:).%B%F{red}:() %f%b"
  else
    >&2 echo ERROR! 'conda' or 'mamba' not found!
    exit -1
  fi
}
act ${CONDA_DEFAULT_ENV}

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
