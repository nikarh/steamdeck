#!/usr/bin/bash -xe

GAMEDIR=~/Games

cd "$GAMEDIR/$1" || exit
"$GAMEDIR/$1/$2" "${@:3}"