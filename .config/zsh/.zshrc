export PATH="/usr/local/sbin:$PATH"
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

# PATH=$PATH:$HOME/.scripts
bindkey -v  # vi-mode
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Prompt Settings
PROMPT=""
if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
    PROMPT+="($CONDA_DEFAULT_ENV) "
fi
PROMPT+="[\[\e[36;1m\]\u\[\033[00m\]@\[\e[32;1m\]\h\[\033[00m\]] \[\e[31;1m\]\w\[\033[33m\] \[\e[0m\]\n$ "

# Git Settings
autoload -Uz vcs_info
precmd_vcs_info() { vcs_info }
precmd_functions+=( precmd_vcs_info )
setopt prompt_subst
RPROMPT=\$vcs_info_msg_0_
zstyle ':vcs_info:git:*' formats '%F{yellow}(%b)%r%f'
zstyle ':vcs_info:*' enable git

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

