#!/usr/bin/bash -xe
ROOT="$(cd "$(dirname "$(readlink -f ${BASH_SOURCE[0]})")" &> /dev/null && pwd)"
source "$ROOT/functions.sh"

# Link configs
cp -frsTv "$ROOT/home/" ~
ln -sf "$ROOT/setup.sh" ~/.bin/

# Download stuff
file-get https://raw.githubusercontent.com/mrzool/bash-sensible/master/sensible.bash \
    ~/.bash-sensible
file-get https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
    ~/.vim/autoload/plug.vim
git-get https://github.com/junegunn/fzf.git \
    ~/.fzf

# Init vim
vim +PlugClean! +PlugUpdate +qa > /dev/null 2>&1

# Download and enable syncthing
if [ ! -f ~/Programs/syncthing/syncthing ]; then
    latest-release syncthing/syncthing "syncthing-linux-amd64.*tar\.gz$" \
        ~/Programs/syncthing.tar.gz
    tar -zxvf ~/Programs/syncthing.tar.gz
    rm syncthing.tar.gz
fi
systemctl enable --now --user syncthing

# Gyro support for yuzu and cemu
latest-release kmicki/SteamDeckGyroDSU "SteamDeckGyroDSUSetup\.zip$" \
        ~/Programs/sdgyrodsu.zip
unzip -o ~/Programs/sdgyrodsu.zip -d ~/Programs >/dev/null;
rm -f ~/Programs/sdgyrodsu.zip
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

# Download starship
if [ ! -f ~/.bin/starship ]; then
    latest-release starship/starship "starship-x86_64-unknown-linux-gnu\.tar\.gz$" \
        /tmp/starship.tar.gz
    tar -zxvf /tmp/starship.tar.gz -C ~/.bin/
    rm /tmp/starship.tar.gz
fi

# Install flatpaks
flatpak install --noninteractive --or-update flathub \
    `# Apps` \
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

# NOPASSWD for all of the bellow commands plus systemctl for teamviewer
if ! sudo -n /usr/bin/pacman -V > /dev/null 2>&1; then
    cat "$ROOT/etc/sudoers.d/wheel" | sudo tee /etc/sudoers.d/wheel
fi

# Install system packages
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
yay -Sy --noconfirm --needed --overwrite '*' \
    lib32-freetype2 \
    fakeroot p7zip unrar insync insync-dolphin bat teamviewer \
    xdg-desktop-portal-gtk podman

sudo steamos-readonly enable
