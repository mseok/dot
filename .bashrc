# Job submit alias
alias qa='qstat -a'
alias qm='watch "qstat -a | grep msh | grep -v C"'
alias qq='/appl/bin/qq'

# current status
alias nnn='nn | grep "horus" | sed "s/\x1b\[[0-9;]*m//g"'

# Git alias
alias gs='git status'
alias gl='git pull'
alias gp='git push'
alias ga='git add .'
alias gcm='git commit -m '
alias glog='git log --graph --abbrev-commit --pretty=oneline'

# Other alias
alias la='ls -a'
alias rmo='rm *.o*'
alias rme='rm *.e*'
alias rma='rm *.o* *.e*'
alias watch='watch '

alias qq='/appl/bin/qq'

function jpt {
    jupyter-lab --no-browser --port=$1
}

function watcha {
    watch $(alias "$@" | cut -d\' -f2)
}

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
    export TERM=xterm-256color
fi

if [[ "$pwd" == "$INSTALL_DIR" ]]; then
    cd $INSTALL_DIR
fi

if { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; } then
    tmux source $INSTALL_DIR/.tmux.conf
fi

alias vi='TERM=screen-256color $DOT_PATH/programs/nvim -u $INSTALL_DIR/.init.vim'
alias sb='source $INSTALL_DIR/.bashrc'
. $DOT_PATH/.git-completion.bash
. $DOT_PATH/.git-prompt.sh
export GIT_PS1_SHOWDIRTYSTATE=1
PS1=""
if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
    PS1+="($CONDA_DEFAULT_ENV) "
fi
# PS1+='[\[\e[36;1m\]\u\[\033[00m\]@\[\e[32;1m\]\h\[\033[00m\]] \[\e[31;1m\]\w\[\033[33m\]$(__git_ps1 " (%s)") \[\e[0m\]\n$ '
PS1+='[\[\e[36;1m\]\u\[\033[00m\]@\[\e[32;1m\]\h\[\033[00m\]] \[\e[31;1m\]\w\[\033[33m\] \[\e[0m\]\n$ '
unset CONDA_SHLVL
