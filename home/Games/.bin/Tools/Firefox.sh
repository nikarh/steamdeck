#!/usr/bin/bash

MOZ_ENABLE_WAYLAND=1 flatpak run org.mozilla.firefox --window-size 1280,720 "$@"
