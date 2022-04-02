#!/usr/bin/bash -xe
ROOT="$(cd "$(dirname "$(readlink -f ${BASH_SOURCE[0]})")" &> /dev/null && pwd)"
source "$ROOT/user_functions.sh"

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
vim +PlugClean! +PlugUpdate +qa

# Add custom bashrc
if ! grep -q "source ~/.bashrc_override" ~/.bashrc; then
    echo "source ~/.bashrc_override" >> ~/.bashrc
    source ~/.bashrc_override
fi

# Download syncthing
if [ ! -f ~/Programs/syncthing/syncthing ]; then
    URL="$(curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest \
        | grep "https://.*syncthing-linux-amd64.*tar\.gz" \
        | cut -d : -f 2,3 \
        | tr -d " ")"
    file-get "$URL" ~/Programs/syncthing.tar.gz
    tar -zxvf ~/Programs/syncthing.tar.gz
    rm syncthing.tar.gz
fi

# Install flatpaks
flatpak install --noninteractive --or-update flathub \
    `# Apps` \
    org.keepassxc.KeePassXC \
    org.qbittorrent.qBittorrent \
    org.telegram.desktop \
    com.visualstudio.code \
    com.discordapp.Discord \
    com.github.tchx84.Flatseal \
    com.heroicgameslauncher.hgl \
    `# Emulators` \
    app.xemu.xemu \
    org.DolphinEmu.dolphin-emu \
    org.citra_emu.citra \
    org.desmume.DeSmuME \
    org.yuzu_emu.yuzu

# NOPASSWD for all of the bellow commands plus systemctl for teamviewer
if ! sudo -n /usr/bin/pacman -V > /dev/null 2>&1; then
    cat "$ROOT/etc/sudoers.d/wheel" | sudo tee /etc/sudoers.d/wheel
fi

# Install system packages
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux
yay -S --noconfirm --needed --overwrite '*' \
    fakeroot p7zip unrar insync insync-dolphin bat teamviewer

sudo steamos-readonly enable
