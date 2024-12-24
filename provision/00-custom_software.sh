#!/bin/bash
set -eux

export DEBIAN_FRONTEND="noninteractive"

# use bash shell
sudo chsh vagrant -s /bin/bash

echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections

# Add repositories
# docker from debian repositories
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo apt update

# ====================================================================================================
sudo NEEDRESTART_MODE=a apt install -qq --no-install-recommends -y \
    fzf lf npm xclip ripgrep feh xxd curl neovim git-lfs bat \
    ffuf \
    hexedit gdb \
    peass \
    python3-pwntools python3-z3 python3-pycryptodome \
    docker-ce docker-ce-cli containerd.io

sudo update-alternatives --set vim /usr/bin/nvim

# add user to docker group
sudo usermod -a -G docker vagrant

# install bottom
curl -sOL https://github.com/ClementTsang/bottom/releases/download/0.10.2/bottom_0.10.2-1_amd64.deb --output-dir /tmp
sudo dpkg -i /tmp/bottom_0.10.2-1_amd64.deb
rm /tmp/bottom_0.10.2-1_amd64.deb
