#!/usr/bin/bash -e
ROOT="$(cd "$(dirname "$(readlink -f ${BASH_SOURCE[0]})")" &> /dev/null && pwd)"
source "$ROOT/functions.sh"

# Link configs
mkdir -p ~/.bin
mkdir -p ~/Games
mkdir -p ~/Programs

cp -frsTv "$ROOT/home/" ~
ln -sf "$ROOT/setup.sh" ~/.bin/

# Download stuff
file-get https://raw.githubusercontent.com/mrzool/bash-sensible/master/sensible.bash \
    ~/.bash-sensible
file-get https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    ~/.vim/autoload/plug.vim
git-get https://github.com/junegunn/fzf.git \
    ~/.fzf

# Install brie
latest-release nikarh/brie "brie-x86_64-unknown-linux-gnu-v.*\.tar\.gz$" /tmp/brie.tar.gz
tar -zxvf /tmp/brie.tar.gz -C ~/.bin brie
tar -zxvf /tmp/brie.tar.gz -C ~/.bin briectl
rm /tmp/brie.tar.gz
systemctl enable --now --user briectl

# Init vim
echo "Updating vim plugins"
vim +PlugClean! +PlugUpdate +qa > /dev/null 2>&1

# Download and enable syncthing
# It will autoupdate, so install it precisely once
if [ ! -f ~/Programs/syncthing/syncthing ]; then
    latest-release syncthing/syncthing "syncthing-linux-amd64.*tar\.gz$" \
            ~/Programs/syncthing.tar.gz
    tar -zxvf ~/Programs/syncthing.tar.gz
    rm ~/Programs/syncthing.tar.gz
fi
systemctl enable --now --user syncthing

# Gyro support for yuzu and cemu
try update-to-latest-release \
        kmicki/SteamDeckGyroDSU \
        "$(cat ~/.cache/.SteamDeckGyroDSU.version || echo)" \
        "SteamDeckGyroDSUSetup\.zip$" \
        /tmp/sdgyrodsu.zip

if [ $EXIT_CODE -eq 0 ]; then
    echo "$LATEST_VERSION" >| ~/.cache/.SteamDeckGyroDSU.version
    unzip -o /tmp/sdgyrodsu.zip -d ~/Programs >/dev/null;
    rm -f /tmp/sdgyrodsu.zip
    sed -i 's/ExecStart=.*/ExecStart=%h\/.bin\/sdgyrodsu/g' ~/Programs/SteamDeckGyroDSUSetup/sdgyrodsu.service
    sed -i 's/HOME\/sdgyrodsu/HOME\/.bin/g' ~/Programs/SteamDeckGyroDSUSetup/install.sh

    if groups | grep -q usbaccess; then
        mkdir -p ~/.config/systemd/user/
        mv ~/Programs/SteamDeckGyroDSUSetup/sdgyrodsu.service ~/.config/systemd/user/
        mv ~/Programs/SteamDeckGyroDSUSetup/sdgyrodsu ~/.bin/
    else
        (cd ~/Programs/SteamDeckGyroDSUSetup/; ./install.sh)
    fi

    rm -rf ~/Programs/SteamDeckGyroDSUSetup
    systemctl enable --now --user sdgyrodsu
fi

# Download starship
try update-to-latest-release \
        starship/starship \
        "$(starship -V | awk '{print "v"$2}' || echo)" \
        "starship-x86_64-unknown-linux-gnu\.tar\.gz$" \
        /tmp/starship.tar.gz

if [ $EXIT_CODE -eq 0 ]; then 
    tar -zxvf /tmp/starship.tar.gz -C ~/.bin/
    rm /tmp/starship.tar.gz
fi

# Install flatpaks
flatpak install --noninteractive --or-update flathub \
    `# Apps` \
    dev.lizardbyte.app.Sunshine \
    com.github.Eloston.UngoogledChromium \
    org.keepassxc.KeePassXC \
    org.qbittorrent.qBittorrent \
    org.telegram.desktop \
    com.visualstudio.code \
    com.discordapp.Discord \
    com.github.iwalton3.jellyfin-media-player \
    com.steamgriddb.steam-rom-manager \
    com.heroicgameslauncher.hgl \
    com.github.tchx84.Flatseal \
    `# Emulators` \
    app.xemu.xemu \
    org.DolphinEmu.dolphin-emu \
    org.citra_emu.citra \
    org.desmume.DeSmuME \
    org.yuzu_emu.yuzu

flatpak override --user com.github.Eloston.UngoogledChromium --socket=session-bus

# NOPASSWD for all of the bellow commands plus systemctl
if ! sudo -n /usr/bin/pacman -V > /dev/null 2>&1; then
    cat "$ROOT/etc/sudoers.d/wheel" | sudo tee /etc/sudoers.d/wheel
fi

# Install yay for insync
if [ ! -f ~/.bin/yay ]; then
    latest-release Jguer/yay "yay_.*_x86_64.tar.gz$" \
        ~/.bin/yay.tar.gz
    tar -zxf ~/.bin/yay.tar.gz
    mv ~/.bin/yay_*/yay ~/.bin/yay
    rm -rf ~/.bin/yay_*
    rm ~/.bin/yay.tar.gz
fi

# Install system packages
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo
~/.bin/yay -Sy --noconfirm --needed --overwrite '*' \
    fakeroot wine-staging

# sudo steamos-readonly enable
