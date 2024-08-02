export PATH="/usr/local/sbin:$PATH"
export TERM="xterm-256color"
export HISFILE=~/.config/zsh/.zsh_hitstory
export EDITOR="nvim"

if [[ -d "$HOME/mseok" ]]; then
    export _HOME=$HOME/mseok
else
    export _HOME=$HOME
fi

autoload -Uz compinit && compinit
_comp_options+=(globdots)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Basic Aliases
alias la="ls -a"
alias ll="ls -l"
alias vi="nvim"
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
if command -v tmux &> /dev/null
then
    tmux set-environment -g _HOME $_HOME &> /dev/null
    tmux source $_HOME/dot/config/tmux/.tmux.conf &> /dev/null
fi

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line

export PATH=$HOME/dot/bin:$PATH

set -o vi
