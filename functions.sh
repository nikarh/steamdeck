#!/usr/bin/bash -e

function file-get {
    echo "Downloading $1 to $2"
    curl -s -fLo "$2" --create-dirs "$1"
}

function git-get {
    if [ ! -d "$2" ]; then
        echo "Cloning $1 to $2"
        git clone -q "$1" "$2"
    else
        echo "Updating $1 in $2"
        git -C "$2" pull -q;
    fi
}

function latest-release {
    local URL="$(curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep "$2" \
        | cut -d : -f 2,3 \
        | tr -d " ")"
    file-get "$URL" "$3"
}