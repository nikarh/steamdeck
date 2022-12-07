export EDITOR="vim"
export PATH=$PATH:~/.fzf/bin/:~/.bin

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


trysource() {
    if [ -f "$1" ]; then source "$1"; fi
}

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias l="ls -lAh"
alias df="df -h"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
trysource ~/.bash-sensible/sensible.bash
shopt -u cdable_vars

if [ -f ~/.bin/starship ]; then 
    eval "$(starship init bash)"
fi

