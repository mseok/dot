alias vi='TERM=screen-256color $MPATH/programs/nvim -u $MPATH/.init.vim'

# Job submit alias
alias qa='qstat -a'
alias qm='watch "qstat -a | grep msh | grep -v C"'
alias qq='$MPATH/template/qst'

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

alias sb='source $MPATH/.bashrc'

function watcha {
    watch $(alias "$@" | cut -d\' -f2)
}

# export PYTHONPATH=~/jaechang/work/programs/plip:$PYTHONPATH
# export PYTHONPATH=/appl/anaconda3/bin/python
export PATH=MPATH/programs:$PATH

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
    export TERM=xterm-256color
fi
