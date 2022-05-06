#!/usr/bin/bash -xe

GAMEDIR="$(dirname "$0")/.."

cd "$GAMEDIR/$1" || exit
"$GAMEDIR/$1/$2" "${@:3}"