export PATH="/usr/local/sbin:$PATH"
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

autoload -Uz compinit && compinit
_comp_options+=(globdots)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Prompt Settings
autoload colors && colors
PROMPT=""
if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
    PROMPT+="($CONDA_DEFAULT_ENV) "
fi
NEWLINE=$'\n'
PROMPT+="[%B%F{cyan}%n%b%F{white}@%B%F{green}%m%F{231}%b] %B%F{red}%d%b%f${NEWLINE}%F{231}$ "

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim -u $HOME/dot/.config/nvim/init.lua"
alias sz="source $HOME/dot/.config/zsh/.zshrc"
alias ta="tmux a -t"
alias tn="tmux new -s"
alias tl="tmux ls"
if [ ! -x "$(command -v foo)" ]; then
    if [ ! -d "$HOME/.config/alacrity" ]; then
        alias reload="cp $HOME/dot/.config/alacritty/alacritty.yml $HOME/.config/alacritty"
    fi
fi

# Git Aliases
alias gs="git status"
alias gl="git pull"
alias gp="git push"
alias ga="git add ."
alias gcm="git commit -m "
alias glog="git log --graph --abbrev-commit --pretty=oneline"

# SSH Aliases
alias horus="ssh -X -Y wykgroup@horus.kaist.ac.kr"
alias messi="ssh -X -Y mseok@messi.kaist.ac.kr"
alias saraswati="ssh -X -Y wykgroup@saraswati1.kaist.ac.kr"

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
if { [ -n "$TMUX" ]; } then
    tmux source $HOME/dot/.config/tmux/.tmux.conf
fi

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

export PATH=$HOME/dot/bin:$PATH
