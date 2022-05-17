#!/usr/bin/bash -xe
# shellcheck disable=SC2155

GAMEDIR=~/Games
STEAM=~/.local/share/Steam
PROTON="$STEAM/${PROTON:-"compatibilitytools.d/GE-Proton7-17"}"
WINE="${WINE_PATH:-"$PROTON/${WINE_DIR:-files/bin}/wine"}"

export STEAM_COMPAT_CLIENT_INSTALL_PATH=~/.local/share/Steam/
export STEAM_COMPAT_DATA_PATH="$GAMEDIR/.wine/$PREFIX_ID"

function init-prefix {
    echo Create prefix
    mkdir -p "$STEAM_COMPAT_DATA_PATH/pfx/dosdevices"
    cd "$STEAM_COMPAT_DATA_PATH/pfx/dosdevices" || exit
    PROTON_LOG=1 PROTON_NO_ESYNC=1 PROTON_DUMP_DEBUG_COMMANDS=1 \
        "$PROTON/proton" run noop
}

if [ -z "$NO_INIT" ] && [ -z "$WINEPREFIX" ]; then
    init-prefix
fi

echo Run game
cd "$(dirname "$GAMEDIR/$2")" || exit
case "$1" in
proton)
    "$PROTON/proton" run "$GAMEDIR/$2" "${@:3}"
    ;;
wine)
    export WINEPREFIX="${WINEPREFIX:-"$STEAM_COMPAT_DATA_PATH/pfx"}"

    if [ -n "$VIRTUAL_DESKTOP" ]; then
        RES=""
        if [ "$VIRTUAL_DESKTOP" = 1 ]; then
            RES=$(xdpyinfo | awk '/dimensions/ {print $2}')
        fi
        cat > /tmp/res.reg << EOF
REGEDIT4
[HKEY_CURRENT_USER\Software\Wine\Explorer]
"Desktop"="Default"
[HKEY_CURRENT_USER\Software\Wine\Explorer\Desktops]
"Default"="${RES}"
[HKEY_CURRENT_USER\Software\Wine\X11 Driver]
"GrabFullscreen"="N"
EOF
        "$WINE" regedit /tmp/res.reg
        rm /tmp/res.reg
    fi
    "$WINE" "$GAMEDIR/$2" "${@:3}"
    ;;
*)
    echo "Unknown runtime"
    ;;
esac
