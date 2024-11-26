#!/usr/bin/bash -e
ROOT="$(cd "$(dirname "$(readlink -f ${BASH_SOURCE[0]})")" &> /dev/null && pwd)"
source "$ROOT/functions.sh"

# Link configs
mkdir -p ~/.bin
mkdir -p ~/Games
mkdir -p ~/Applications

cp -frsTv "$ROOT/home/" ~
ln -sf "$ROOT/setup.sh" ~/.bin/

#if [[ 1 -eq 2 ]]; then

# Download stuff
file-get https://raw.githubusercontent.com/mrzool/bash-sensible/master/sensible.bash \
    ~/.bash-sensible
file-get https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    ~/.vim/autoload/plug.vim
git-get https://github.com/junegunn/fzf.git \
    ~/.fzf

try update-to-latest-release \
        nikarh/brie \
        "$(briectl -V | awk '{print "v"$2}' || echo)" \
        "brie-x86_64-unknown-linux-gnu-v.*\.tar\.gz$" /tmp/brie.tar.gz \
        /tmp/brie.tar.gz

if [ $EXIT_CODE -eq 0 ]; then
    tar -zxvf /tmp/brie.tar.gz -C ~/.bin brie
    tar -zxvf /tmp/brie.tar.gz -C ~/.bin briectl
    rm /tmp/brie.tar.gz
fi

systemctl enable --now --user briectl

# Init vim
echo "Updating vim plugins"
vim +PlugClean! +PlugUpdate +qa > /dev/null 2>&1

#fi

# Download and enable syncthing
# It will autoupdate, so install it precisely once
if [ ! -f ~/Applications/syncthing/syncthing ]; then
    latest-release syncthing/syncthing "syncthing-linux-amd64.*tar\.gz$" \
            ~/Applications/syncthing.tar.gz
    tar -zxvf ~/Applications/syncthing.tar.gz
    rm ~/Applications/syncthing.tar.gz
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
    unzip -o /tmp/sdgyrodsu.zip -d ~/Applications >/dev/null;
    rm -f /tmp/sdgyrodsu.zip
    sed -i 's/ExecStart=.*/ExecStart=%h\/.bin\/sdgyrodsu/g' ~/Applications/SteamDeckGyroDSUSetup/sdgyrodsu.service
    sed -i 's/HOME\/sdgyrodsu/HOME\/.bin/g' ~/Applications/SteamDeckGyroDSUSetup/install.sh

    if groups | grep -q usbaccess; then
        mkdir -p ~/.config/systemd/user/
        mv ~/Applications/SteamDeckGyroDSUSetup/sdgyrodsu.service ~/.config/systemd/user/
        mv ~/Applications/SteamDeckGyroDSUSetup/sdgyrodsu ~/.bin/
    else
        (cd ~/Applications/SteamDeckGyroDSUSetup/; ./install.sh)
    fi

    rm -rf ~/Applications/SteamDeckGyroDSUSetup
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
flatpak install  --user --noninteractive --or-update flathub \
    `# Apps` \
    dev.lizardbyte.app.Sunshine \
    com.rustdesk.RustDesk \
    org.mozilla.firefox \
    io.github.ungoogled_software.ungoogled_chromium \
    org.keepassxc.KeePassXC \
    org.qbittorrent.qBittorrent \
    com.visualstudio.code \
    com.github.iwalton3.jellyfin-media-player \
    com.steamgriddb.steam-rom-manager \
    com.heroicgameslauncher.hgl \
    com.github.tchx84.Flatseal \

    # Emulators
    #app.xemu.xemu \
    #org.DolphinEmu.dolphin-emu \
    #org.citra_emu.citra \
    #org.desmume.DeSmuME \
    #org.yuzu_emu.yuzu

flatpak override --user io.github.ungoogled_software.ungoogled_chromium --socket=session-bus

# wine-ge-custom also requires lib32-libxrandr.
# It can either be installed system-wide, or linked
# from steam with LD_LIBRARY_PATH:
# LD_LIBRARY_PATH="/home/deck/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/"
