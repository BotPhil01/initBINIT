#!/usr/bin/env bash

set -o nounset;
set -o pipefail;
set -o errexit;

SCRIPT_DIR="$(pwd)"
echo "updating current packages"
sudo apt-get -qq -y update
echo "upgrading current packages"
sudo apt-get -qq -y upgrade 

echo "installing dependencies"
# install downlaod dependencies
echo "installing curl wget openssh-client git flatpak"
sudo apt-get -qq -y install curl wget openssh-client git flatpak

# flatpak repo
echo "adding flathub repo to flatpack"
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# install compression dependencies
echo "installing tar zip unzip"
sudo apt-get -qq -y install tar zip unzip

# install signing dependencies 
echo "installing gpg"
sudo apt-get -qq -y install gpg

# install language dependencies
echo "installing languages"

# node and npm
echo "installing node npm nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash 1>/dev/null

\. "$HOME/.nvm/nvm.sh"
nvm install 24 1&>/dev/null

# use below for erros loading nvm
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# C
echo "installing make gcc clang"
sudo apt-get install -qq -y make gcc clang

# Python
echo "installing python3"
sudo apt-get install -qq -y python3 python3.12-venv

# C++
echo "installing g++"
sudo apt-get install -qq -y g++

# Java 21
# good enough
echo "installing openjdk-21-jre"
sudo apt-get install -qq -y openjdk-21-jre

# code editors
echo "installing text editors"
echo "installing vim"
sudo apt-get install -qq -y vim
echo "installing neovim"
curl -Lo /tmp/nvim-linux-x86_64.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
sudo chmod u+x /tmp/nvim-linux-x86_64.appimage
if [[ ! -d /opt/nvum ]]; then
    sudo mkdir -p /opt/nvim
fi
sudo mv /tmp/nvim-linux-x86_64.appimage /opt/nvim/nvim
pathnvim="$(grep nvim ~/.bashrc)"
if [[ "$pathnvim" == "" ]]; then
    echo "export PATH=\"$PATH:/opt/nvim/\"" >> $HOME/.bashrc
fi

echo "purging nano code"
sudo apt-get remove -qq -y nano # fuck nano
sudo snap remove --purge code # fuck code

echo "installing neovim config"

# config dependencies
echo "installing ripgrep xclip"
sudo apt-get install -qq -y ripgrep xclip
# sudo apt-get -qq -y install xclip

# get nvim config
echo "installing nvim config"
nvimconfig_d="$HOME/.config/nvim/"
if [[ ! -d $HOME/.config/nvim ]]; then
    mkdir $nvimconfig_d -p
    git clone https://github.com/BotPhil01/nvim.git $nvimconfig_d -q
fi

# browsers
# mullvad-browser
echo "installing browsers"
echo "installing mullvad"
sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list
sudo apt-get -qq -y update
sudo apt-get -qq -y install mullvad-browser

# firefox
echo "installing firefox"
if ! firefox --version 1>&/dev/null; then
    sudo snap install firefox
fi

# Tor browser
echo "installing tor browser"
curl -sLo /tmp/tor.tar.xz.asc https://www.torproject.org/dist/torbrowser/15.0.3/tor-browser-linux-x86_64-15.0.3.tar.xz.asc
curl -sLo /tmp/tor.tar.xz https://www.torproject.org/dist/torbrowser/15.0.3/tor-browser-linux-x86_64-15.0.3.tar.xz
torpub="$(gpg -q --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org 1>&1 2>/dev/null | grep pub -A 1 | tail -n 1 | sed -s 's/ //g')"
gpg --yes --output /tmp/tor.keyring --export "0x$torpub"
response="$(gpgv -q --keyring /tmp/tor.keyring /tmp/tor.tar.xz.asc /tmp/tor.tar.xz 2>&1)"
goodsig="Good signature from \"Tor Browser Developers (signing key) <torbrowser@torproject.org>\""

if [[ "$response" != *"$goodsig"* ]]; then
    echo "Tor bad signature exiting..."
    exit 1
fi
sudo tar xf /tmp/tor.tar.xz -C /opt/
sudo cp -r tor /etc/tor

# litte-t-tor
echo "installing little-t-tor"
sudo apt-get -qq -y install apt-transport-https
torsource="Types: deb deb-src
URIs: https://deb.torproject.org/torproject.org/
Suites: $(lsb_release -c | awk '{print$2}')
Components: main
Signed-By: /usr/share/keyrings/deb.torproject.org-keyring.gpg"
echo "$torsource" | sudo tee /etc/apt/sources.list.d/tor.sources

sudo apt-get -qq -y install gnupg
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | sudo tee /usr/share/keyrings/deb.torproject.org-keyring.gpg >/dev/null
sudo apt-get -qq -y update
echo "N" | sudo apt-get -qq -y install tor deb.torproject.org-keyring
cd $SCRIPT_DIR

# bitwarden
# use flatpak because bitwarden doesnt have a cli tool
echo "installing bitwarden"
if [[ "$(flatpak list | grep bitwarden)" == "" ]]; then
    sudo flatpak install -y flathub com.bitwarden.desktop 
fi

# Anki
echo "installing Anki"
sudo apt-get install -qq -y libxcb-xinerama0 libxcb-cursor0 libnss3 zstd
curl -Lo /tmp/anki.tar.zst https://github.com/ankitects/anki/releases/download/25.09/anki-launcher-25.09-linux.tar.zst
if [[ ! -d /tmp/anki ]]; then
    mkdir /tmp/anki
fi
tar xaf /tmp/anki.tar.zst -C /tmp/anki
cd /tmp/anki/$(ls /tmp/anki/)
sudo ./install.sh

# clamav
echo "installing clamav"
sudo apt-get install -qq -y clamav clamav-daemon
sudo cp -r $SCRIPT_DIR/clamav /etc/clamav
sudo crontab $SCRIPT_DIR/clamcron


# autostart config
echo "installing autostarts"
if [[ ! -d ~/.config/autostart ]]; then
	mkdir ~/.config/autostart
fi
cp -r $SCRIPT_DIR/autostarts/* ~/.config/autostart

# bin scripts
echo "installing bin scripts"
git clone https://github.com/BotPhil01/nonBINgusBONgus $HOME/.bin/
cd $HOME/.bin/
./install.sh
