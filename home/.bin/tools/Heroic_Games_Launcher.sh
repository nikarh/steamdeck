#!/bin/bash

flatpak run --branch=stable --arch=x86_64 --command=heroic-run com.heroicgameslauncher.hgl \
    $@
