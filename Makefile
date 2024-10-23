SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=2024.3

kali-${VERSION}-amd64-libvirt.box: clean preseed.cfg kali.pkr.hcl Vagrantfile.template \
				provision/00-custom_software.sh \
				provision/01-xfce.sh \
				provision/97-guest-additions.sh \
				provision/98-vagrant.sh \
				provision/99-cleanup.sh

	CHECKPOINT_DISABLE=1 PACKER_LOG=1 PACKER_LOG_PATH=$@.init.log packer init kali.pkr.hcl

	mkdir ./packer_cache
	TMPDIR=${PWD}/packer_cache \
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.kali-amd64 -on-error=abort -timestamp-ui kali.pkr.hcl
	rmdir packer_cache

clean:
	rm -rf kali-${VERSION}-amd64-libvirt.box* ./output-kali-amd64 ./packer_cache

