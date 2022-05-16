#!/usr/bin/bash -xe
# shellcheck disable=SC2155

GAMEDIR=~/Games
STEAM=~/.local/share/Steam
PROTON="$STEAM/${PROTON:-"compatibilitytools.d/GE-Proton7-17"}"
WINE="$PROTON/${WINE_DIR:-files/bin}/wine"

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
cd "$(dirname "$GAMEDIR/$1")" || exit
case "$1" in
proton)
    "$PROTON/proton" run "$GAMEDIR/$2" "${@:3}"
    ;;
wine)
    WINEPREFIX=${WINEPREFIX:-"$STEAM_COMPAT_DATA_PATH/pfx"} \
        "$WINE" "$GAMEDIR/$2" "${@:3}"
    ;;
*)
    echo "Unknown runtime"
    ;;
esac
