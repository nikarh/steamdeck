#!/bin/bash

flatpak run --branch=stable --arch=x86_64 com.github.Eloston.UngoogledChromium \
     --window-size=1024,640 --force-device-scale-factor=1.25 --device-scale-factor=1.25 \
     --dark --force-dark-mode \
      $@
