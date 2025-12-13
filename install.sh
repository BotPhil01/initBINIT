#!/usr/bin/env bash

set -o nounset;
set -o pipefail;
set -o errexit;

SCRIPT_DIR="$(pwd)"
sudo apt-get -qq -y update 
sudo apt-get -qq -y upgrade

# install downlaod dependencies
sudo apt-get -qq -y install curl wget openssh-client git flatpak

# flatpak repo
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# install compression dependencies
sudo apt-get -qq -y install tar zip unzip

# install signing dependencies 
sudo apt-get -qq -y install gpg

# install language dependencies

# node and npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

\. "$HOME/.nvm/nvm.sh"
nvm install 24

# use below for erros loading nvm
# export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# C
sudo apt-get -qq -y install make gcc clang
# sudo apt-get -qq -y install gcc
# sudo apt-get -qq -y install clang

# Python
sudo apt-get -qq -y install python3

# C++
sudo apt-get -qq -y install g++

# Java 21
# good enough
sudo apt-get -qq -y install openjdk-21-jre

# code editors
sudo apt-get -qq -y install vim neovim
# sudo apt-get -qq -y install neovim
sudo apt-get -qq -y remove nano # fuck nano
sudo snap remove --purge code # fuck code

# config dependencies
sudo apt-get -qq -y install ripgrep xclip
# sudo apt-get -qq -y install xclip

# get nvim config
nvimconfig_d="$HOME/.config/nvim/"
if [[ ! -d $HOME/.config/nvim ]]; then
    mkdir $nvimconfig_d -p
    git clone https://github.com/BotPhil01/nvim.git $nvimconfig_d -q
fi

# browsers
# mullvad-browser
sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list
sudo apt-get -qq -y update
sudo apt-get -qq -y install mullvad-vpn

# firefox
if ! firefox --version 1>&/dev/null; then
    sudo snap install firefox
fi

# bitwarden
# use flatpak because bitwarden doesnt have a cli tool
if [[ "$(flatpak list | grep bitwarden)" == "" ]]; then
    sudo flatpak install -y flathub com.bitwarden.desktop 
fi

# Tor browser
curl -sLo /tmp/tor.tar.xz.asc https://www.torproject.org/dist/torbrowser/15.0.3/tor-browser-linux-x86_64-15.0.3.tar.xz.asc
curl -sLo /tmp/tor.tar.xz https://www.torproject.org/dist/torbrowser/15.0.3/tor-browser-linux-x86_64-15.0.3.tar.xz
torpub="$(gpg -q --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org 1>&1 2>/dev/null | grep pub -A 1 | tail -n 1 | sed -s 's/ //g')"
gpg --output /tmp/tor.keyring --export "0x$torpub" --yes
response="$(gpgv -q --keyring /tmp/tor.keyring /tmp/tor.tar.xz.asc /tmp/tor.tar.xz 2>&1)"
goodsig=*"Good signature from Tor Browser Developers (signing key) <torbrowser@torproject.org>"*

if [[ "$response" != *"$goodsig"* ]]; then
    echo "Tor bad signature"
    exit 1
fi
sudo tar xf tor.tar.xz -C /opt/
sudo cp tor /etc/tor

# litte-t-tor
sudo apt-get -qq -y install apt-transport-https
echo "   Types: deb deb-src
   URIs: https://deb.torproject.org/torproject.org/
   Suites: $(lsb_release -c | awk '{print$2}')
   Components: main
   Signed-By: /usr/share/keyrings/deb.torproject.org-keyring.gpg" > /etc/apt/sources.list.d/tor.sources
sudo apt-get -qq -y install gnupg
wget -sqO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | sudo tee /usr/share/keyrings/deb.torproject.org-keyring.gpg >/dev/null
sudo apt-get -qq -y update
sudo apt-get -qq -y install tor deb.torproject.org-keyring
cd script_dir

# autostart config
cp $SCRIPT_DIR/autostarts/* ~/config/autostart

# Anki
sudo apt-get install -qq -y libxcb-xinerama0 libxcb-cursor0 libnss3 zstd
curl -sLo /tmp/anki.tar.zst https://github.com/ankitects/anki/releases/download/25.09/anki-launcher-25.09-linux.tar.zst
mkdir /tmp/anki
tar xaf /tmp/anki.tar.zst -C /tmp/anki
cd /tmp/anki/$(ls /tmp/anki/)
sudo ./install.sh

# clamav
sudo apt-get install -qq -y clamav clamav-daemon
sudo cp $SCRIPT_DIR/clamav /etc/clamav
sudo crontab $SCRIPT_DIR/clamcron

# bin scripts

git clone https://github.com/BotPhil01/bin.git 
