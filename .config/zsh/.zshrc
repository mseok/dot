export PATH="/usr/local/sbin:$PATH"
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

# PATH=$PATH:$HOME/.scripts
bindkey -v  # vi-mode
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Prompt Settings
autoload colors && colors
PROMPT=""
if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
    PROMPT+="($CONDA_DEFAULT_ENV) "
fi
NEWLINE=$'\n'
CYAN=$'\e[36;1m'
# RED=$'\e[31:1m'
WHITE=$'\e[00m'
PROMPT+="[${CYAN}%m${WHITE}] ${CYAN}%F{red}%d%f${NEWLINE}${WHITE}$ "

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
alias sz="source $HOME/dot/.config/zsh/.zshrc"

# SSH Aliases
alias horus="ssh -X -Y wykgroup@horus.kaist.ac.kr"
alias messi="ssh -X -Y mseok@messi.kaist.ac.kr"

# Functions
openlocal() {
    open -a Safari https://localhost:"$1"
}
jpt() {
    ssh -N -f -L localhost:"$1":localhost:"$2" mseok@messi.kaist.ac.kr
}
juptyer-pid() {
    lsof -i tcp:"$1"
}

# Tmux
if { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; } then
    tmux source $INSTALL_DIR/.tmux.conf
fi
