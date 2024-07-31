#!/bin/bash
set -eux

export DEBIAN_FRONTEND="noninteractive"

# use bash shell
sudo chsh vagrant -s /bin/bash

echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections

# ====================================================================================================
# MAIN
sudo NEEDRESTART_MODE=a apt install -qq --no-install-recommends -y \
    fzf npm xclip ripgrep strace feh xxd curl vim-gtk3 git-lfs \
    golang-go \
    ffuf \
    hexedit gdb \
    peass

# ====================================================================================================
# install latest docker from debian repositories
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
# add user to docker group
sudo usermod -a -G docker vagrant

# ====================================================================================================
# install lf
env CGO_ENABLED=0 go install -ldflags="-s -w" github.com/gokcehan/lf@latest

# install bottom
curl -sOL https://github.com/ClementTsang/bottom/releases/download/0.9.6/bottom_0.9.6_amd64.deb --output-dir /tmp
sudo dpkg -i /tmp/bottom_0.9.6_amd64.deb
rm /tmp/bottom_0.9.6_amd64.deb

# ====================================================================================================
# install usefull python packages
pip install pwntools z3-solver ortools pycryptodome

