export ZSH="/Users/mseok/.oh-my-zsh"
ZSH_THEME="robbyrussell"

export UPDATE_ZSH_DAYS=30
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Aliases
# Basic
alias vi='nvim -u ~/.config/nvim/init.vim'
alias la='ls -a'
alias sz='source ~/.zshrc'

# Git
alias gs='git status'
alias gl='git pull'
alias gp='git push'
alias ga='git add .'
alias gcm='git commit -m '
alias glog='git log --graph --abbrev-commit --pretty=oneline'

# SSH
alias horus='ssh -X wykgroup@horus.kaist.ac.kr'
alias messi='ssh -X messi@kaist.ac.kr'
alias os='ssh team1@192.249.19.115'

# User configuration
export MANPATH="/usr/local/man:$MANPATH"
