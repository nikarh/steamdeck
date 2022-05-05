#!/bin/bash

flatpak run --branch=stable --arch=x86_64 com.github.iwalton3.jellyfin-media-player \
    --tv --fullscreen $@
