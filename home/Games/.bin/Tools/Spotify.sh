#!/usr/bin/bash

flatpak run --branch=stable --arch=x86_64 com.spotify.Client --fullscreen "$@"
