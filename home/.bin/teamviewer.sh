#!/usr/bin/bash -xe
sudo systemctl start teamviewerd
teamviewer
sudo systemctl stop teamviewerd
