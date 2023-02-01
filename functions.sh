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
        git -C "$2" pull -q
    fi
}

function latest-release {
    local URL="$(curl -s "https://api.github.com/repos/$1/releases/latest" \
        | jq -r '.assets[].browser_download_url' \
        | grep "$2" \
        | head -n 1)"
    file-get "$URL" "$3"
}

EXIT_CODE=0
function try {
    EXIT_CODE=0
    "$@" || EXIT_CODE=$?
}

LATEST_VERSION=""
function update-to-latest-release {
    local REPO="$1"
    local CURRENT="$2"
    local FILENAME="$3"
    local TARGET="$4"
    local RES="$(curl -s "https://api.github.com/repos/$REPO/releases/latest")"
    LATEST_VERSION="$(echo "$RES" | jq -r '.name')"

    if [[ "$LATEST_VERSION" == "$CURRENT" ]]; then
        echo "Skipping $REPO update, latest version is $CURRENT";
        return 1;
    fi

    if [ -z "$CURRENT" ]; then
        echo "Installing $REPO $LATEST_VERSION";
    else
        echo "Updating $REPO from $CURRENT to $LATEST_VERSION";
    fi

    local URL="$(echo "$RES" \
        | jq -r '.assets[].browser_download_url' \
        | grep "$FILENAME" \
        | head -n 1)"
    file-get "$URL" "$TARGET"

    return 0;
}