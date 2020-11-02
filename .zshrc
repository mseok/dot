export ZSH="/Users/mseok/.oh-my-zsh"
ZSH_THEME="robbyrussell"

export UPDATE_ZSH_DAYS=30
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git)

source $ZSH/oh-my-zsh.sh
if [[ -f ~/.zsh_profile ]]; then
    . ~/.zsh_profile
fi

# Aliases
# Basic
alias vi='nvim -u ~/.init.vim'
alias la='ls -a'
alias sz='source ~/.zsh_profile'

# Git
alias gs='git status'
alias gl='git pull'
alias gp='git push'
alias ga='git add .'
alias gcm='git commit -m '
alias glog='git log --graph --abbrev-commit --pretty=oneline'

# SSH
alias horus='ssh -X -Y wykgroup@horus.kaist.ac.kr'
alias messi='ssh -X -Y mseok@messi.kaist.ac.kr'

openlocal() {
    open -a Safari https://localhost:"$1"
}

jpt() {
    ssh -N -f -L localhost:"$1":localhost:"$2" mseok@messi.kaist.ac.kr
}

juptyer-pid() {
    lsof -i tcp:"$1"
}

# User configuration
export MANPATH="/usr/local/man:$MANPATH"
export PATH="/usr/local/sbin:$PATH"
