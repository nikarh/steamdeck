export EDITOR="vim"
export PATH=$PATH:~/.fzf/bin/:~/.bin

trysource() {
    if [ -f "$1" ]; then source "$1"; fi
}

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias l="ls -lAh"
alias df="df -h"

trysource ~/.fzf/shell/completion.bash
trysource ~/.fzf/shell/key-bindings.bash
trysource ~/.bash-sensible/sensible.bash
shopt -u cdable_vars

export WINE=~/.local/share/Steam/compatibilitytools.d/GE-Proton7-17/files/bin/wine

if [ -f ~/.bin/starship ]; then 
    eval "$(starship init bash)"
fi
