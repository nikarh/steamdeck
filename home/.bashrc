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

export WINE=/home/deck/.var/app/net.lutris.Lutris/data/lutris/runners/wine/lutris-GE-Proton7-11-x86_64/bin/wine
export WINETRICKS=/home/deck/.var/app/net.lutris.Lutris/data/lutris/runtime/winetricks/winetricks

if [ -f ~/.bin/starship ]; then 
    eval "$(starship init bash)"
fi
