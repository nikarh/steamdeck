#!/usr/bin/bash -xe
ROOT="$(cd "$(dirname "$(readlink -f ${BASH_SOURCE[0]})")" &> /dev/null && pwd)"
source "$ROOT/functions.sh"

# Sunshine for streaming, not in flathub yet
latest-release LizardByte/Sunshine "sunshine_x86_64\.flatpak$" \
        /tmp/sunshine.flatpak
flatpak install --user --noninteractive \
    /tmp/sunshine.flatpak
