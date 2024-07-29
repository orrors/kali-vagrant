#!/bin/bash
# abort this script when a command fails or a unset variable is used.
set -eu
# echo all the executed commands.
set -x

# use bash shell
sudo chsh vagrant -s /bin/bash

echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections

# install main software
sudo NEEDRESTART_MODE=a apt install -y -qq --no-install-recommends \
    fzf npm xclip ripgrep strace feh golang-go xxd \ # general use
    patchelf hexedit gdb ghidra gdbserver \ # reverse tools
    peass \ # enumeration
    # docker.io \ # default docker
    vim-gtk3 git-lfs \

# install latest docker from debian repositories
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list
curl -fsSL https://download.docker.com/linux/debian/gpg |
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

# install lf
env CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest

# install bottom
curl -sOL https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_amd64.deb --output-dir /tmp && sudo dpkg -i /tmp/bottom_0.9.6_amd64.deb

# install usefull python packages
pip install pwntools z3-solver ortools pycryptodome

# add user to docker group
sudo usermod -a -G docker vagrant

# SET DARK THEMES
mkdir -p ~/.ghidra/.ghidra_11.0_DEV/ && echo "Theme=Class\:generic.theme.builtin.FlatDarkTheme" > ~/.ghidra/.ghidra_11.0_DEV/preferences
mkdir -p ~/.BurpSuite && echo '{"user_options":{"display":{"user_interface":{"look_and_feel":"Dark"}},"misc":{"hotkeys":[{"action":"open_embedded_browser","hotkey":"Ctrl+P"}]}}}' > ~/.BurpSuite/UserConfigCommunity.json

# Fix X11 sharing timeout for gnome windows
echo 'eval `dbus-launch --sh-syntax`' >> ~/.profile
