#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" || exit

function expand {
    cat - | sed -r "s:~:/home/$USER:g"
}

CONFIG_DIR="$HOME/Games/.config"
RUNTIMES="$HOME/Games/.wine/runtimes"
LIBRARIES="$HOME/Games/.wine/libraries"
SHELLS_DIR="$HOME/Games/.bin/.generated"

YAML="$CONFIG_DIR/games.yaml"

function file-get {
    curl -s -fLo "$2" --create-dirs "$1"
}

function latest-release {
    curl -s "https://api.github.com/repos/$1/releases" \
        | jq -r '.[].assets[].browser_download_url' \
        | grep "$2" \
        | head -n 1
}

function prepare-runtime {
    mkdir -p "$RUNTIMES"

    local version="$1"

    if [[ "$version" == "default" ]]; then
        version="lutris-GE-Proton.*-x86_64"
    fi

    local url="$(latest-release GloriousEggroll/wine-ge-custom "wine-$version\.tar\.xz$")"
    local version=$(echo $url | awk -F'/' '{print $NF}' | awk -F'.tar.xz' '{print $1}' | cut -c 6-)

    ln -sf "$RUNTIMES/$version" "$RUNTIMES/default"
    if ! [ -d "$RUNTIMES/$version" ]; then
        echo Downloading "$version"
        file-get "$url" "$RUNTIMES/wine.tar.xz"
        tar -xf "$RUNTIMES/wine.tar.xz" -C "$RUNTIMES" && rm "$RUNTIMES"/wine.tar.xz
    fi
}

function prepare-winetricks {
    mkdir -p "$RUNTIMES/.bin"
    if ! [ -f "$RUNTIMES/.bin/winetricks" ]; then
        file-get "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" "$RUNTIMES/.bin/winetricks"
        chmod +x "$RUNTIMES/.bin/winetricks"
    fi

    if ! [ -f "$RUNTIMES/.bin/cabextract" ]; then
        file-get "https://archlinux.org/packages/community/x86_64/cabextract/download/" "$RUNTIMES/cabextract.tar.zst"
        tar --extract -C "$RUNTIMES/.bin" -f "$RUNTIMES/cabextract.tar.zst" usr/bin/cabextract --strip-components 2
        rm "$RUNTIMES/cabextract.tar.zst"
    fi
}

function prepare-libaries {
    rm -rf "$LIBRARIES"
    mkdir -p "$LIBRARIES"
    file-get "$(latest-release Sporif/dxvk-async "dxvk-async.*\.tar\.gz$")" "$LIBRARIES/dxvk-async.tar.gz"
    file-get "$(latest-release HansKristian-Work/vkd3d-proton "vkd3d-proton.*\.tar\.zst$")" "$LIBRARIES/vkd3d-proton.tar.zst"

    tar -xf "$LIBRARIES/dxvk-async.tar.gz" -C "$LIBRARIES" && mv "$LIBRARIES"/dxvk-async-* "$LIBRARIES"/dxvk-async && rm "$LIBRARIES"/dxvk-async.tar.gz
    tar -xf "$LIBRARIES/vkd3d-proton.tar.zst" -C "$LIBRARIES" && mv "$LIBRARIES"/vkd3d-proton-* "$LIBRARIES"/vkd3d-proton && rm "$LIBRARIES"/vkd3d-proton.tar.zst

    chmod +x "$LIBRARIES"/*/*.sh
}

function create-shell-scripts {
    rm -rf "$SHELLS_DIR"
    mkdir -p "$SHELLS_DIR"

    while read line; do
        local game="$(echo $line | awk '{print $2}')"
        local name="$(cat "$YAML" | yq ".games[\"$game\"].name")"

        echo -e "#!/bin/bash\n$HOME/.bin/play.sh $game" > "$SHELLS_DIR/$name.sh"
        chmod +x "$SHELLS_DIR/$name.sh"
    done <<< "$(cat "$YAML" | yq '.games | keys')"
}

function run-wine {
    local GAME="$1"

    local RUNTIME=$(cat "$YAML" | yq '.runtime // "default"' | expand)
    local PREFIXES=$(cat "$YAML" | yq .prefixes | expand)
    local WINE="$RUNTIMES/$RUNTIME"

    mkdir -p "$PREFIXES"

    # Download runtime
    if ! [ -d "$WINE" ]; then
        prepare-runtime "$RUNTIME"
    fi

    # Download libraries
    if ! [ -d "$LIBRARIES/dxvk-async" ]; then
        prepare-libaries
    fi

    prepare-winetricks

    eval "$(cat "$YAML" | yq -o p '.env' | sed -r 's/([^ ]+) = (.*)/export \1="\2"/')" > /dev/null

    local NAME="$(cat "$YAML" | yq ".games[\"$GAME\"].name")"
    local PREFIX="$(cat "$YAML" | yq ".games[\"$GAME\"].prefix // \"$NAME\"")"
    local GAME_DIR="$(cat "$YAML" | yq ".games[\"$GAME\"].dir")"
    local GAME_EXE="$(cat "$YAML" | yq ".games[\"$GAME\"].run")"

    eval "$(cat "$YAML" | yq -o p ".games[\"$GAME\"].env" | sed -r 's/([^ ]+) = (.*)/export \1="\2"/')" > /dev/null

    export PATH="$WINE/bin:$RUNTIMES/.bin:$PATH"
    export WINEPREFIX="$PREFIXES/$PREFIX"

    # Init prefix
    if [ ! -d "$WINEPREFIX" ]; then
        echo Initializing prefix
        WINEDLLOVERRIDES=winemenubuilder.exe=d \
            wine __INITPREFIX > /dev/null 2>&1 || true
        wineserver --wait
    fi

    cd "$WINEPREFIX"

    # Replace symlinks to $HOME with directories
    find "$WINEPREFIX/drive_c/users/$USER" -maxdepth 1 -type l \
        -exec unlink {} \; \
        -exec mkdir {} \;

    # Winetricks
    while read line; do
        local line="$(echo $line | awk '{print $2}')"
        if [[ "$line" == "" ]]; then
            continue
        fi
        if ! grep -Fxq "$line" "$WINEPREFIX/.winetricks"; then
            winetricks $line
            echo "$line" >> "$WINEPREFIX/.winetricks"
        fi
    done <<< "$(cat "$YAML" | yq ".games[\"$GAME\"].winetricks // []")"

    # Mounts
    while read line; do
        local line="$(echo $line | awk '{print $2}')"
        if [[ "$line" == "" ]]; then
            continue
        fi

        local from="$(cat "$YAML" | yq ".games[\"$GAME\"].mounts[\"$line\"]")"
        ln -s "$from" "$WINEPREFIX/dosdevices/${line}:"
    done <<< "$(cat "$YAML" | yq ".games[\"$GAME\"].mounts // {} | keys")"

    # Install libraries for games
    local syswow="$WINEPREFIX/drive_c/windows/syswow64"
    if ! diff -q "$syswow/d3d11.dll" "$LIBRARIES/dxvk-async/x32"; then
        echo Installing dxvk...
        $LIBRARIES/dxvk-async/setup_dxvk.sh install
    fi

    if ! diff -q "$syswow/d3d12.dll" "$LIBRARIES/vkd3d-proton/x86"; then
        echo Installing vkd3d-proton...
        $LIBRARIES/vkd3d-proton/setup_vkd3d_proton.sh install
    fi

    wineserver --wait

    echo "cd \"$GAME_DIR\""
    echo "export PATH=\"$WINE/bin:\$PATH\""
    echo "export WINEPREFIX=\"$PREFIXES/$PREFIX\""
    echo 'wine '\""$GAME_EXE"\" $(cat "$YAML" | yq ".games[\"$GAME\"].args // \"\"" | sed -r 's/- ([^ ]+)/\1/')

    cd "$GAME_DIR"
    wine "$GAME_EXE" "${@:2}" $(cat "$YAML" | yq ".games[\"$GAME\"].args // \"\"" | sed -r 's/- ([^ ]+)/\1/')

    # Some games fork, don't cleanup for them
    if [[ "$(cat "$YAML" | yq ".games[\"$GAME\"].cleanup")" != "false" ]]; then
        wineserver -k
    fi
}

function run-native {
    local GAME="$1"
    local RUN="$(cat "$YAML" | yq ".games[\"$GAME\"].run")"
    local GAME_DIR="$(cat "$YAML" | yq ".games[\"$GAME\"].dir // \"$HOME\"")"

    cd "$GAME_DIR"

    "$RUN" $(cat "$YAML" | yq ".games[\"$GAME\"].args // \"\"" | sed -r 's/- ([^ ]+)/\1/')
}

function run {
    local GAME="$1"

    if [ -z "$GAME" ]; then
        echo Provide game key as an argument:
        echo "$(cat "$YAML" | yq '.games | keys')"
        exit 1;
    fi

    if [[ "$(cat "$YAML" | yq ".games[\"$GAME\"]")" == "null" ]]; then
        echo Invalid game "$GAME", provide valid game key as an argument:
        echo "$(cat "$YAML" | yq '.games | keys')"
        exit 1;
    fi

    local TYPE="$(cat "$YAML" | yq ".games[\"$GAME\"].type // \"wine\"")"

    case "$TYPE" in
        native)
            run-native "$1" "${@:2}";;
        "wine")
            run-wine "$1" "${@:2}";;
        *)
            echo "invalid type";;
    esac
}

function refresh {
    if ! sha1sum --quiet --check "$YAML.sha1" 2>/dev/null; then
        create-shell-scripts
        sha1sum "$YAML" >| "$YAML.sha1"
    fi
}

refresh

if [ "$1" == "watch" ]; then
    while inotifywait -e modify "$YAML"; do
        echo "Recreating shell scripts"
        refresh;
    done
else
    run "$1" "${@:2}"
fi