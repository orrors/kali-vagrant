SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=2024.1

build-libvirt: kali-${VERSION}-amd64-libvirt.box

kali-${VERSION}-amd64-libvirt.box: clean preseed.txt scripts/guest-additions.sh scripts/final.sh kali.pkr.hcl Vagrantfile.template
	rm -f $@
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 \
	PACKER_LOG_PATH=$@.init.log \
		packer init kali.pkr.hcl
	mkdir ./packer_cache
	TMPDIR=${PWD}/packer_cache \
	PACKER_KEY_INTERVAL=10ms \
	CHECKPOINT_DISABLE=1 \
	PACKER_LOG=1 PACKER_LOG_PATH=$@.log \
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
		packer build -only=qemu.kali-amd64 -on-error=abort -timestamp-ui kali.pkr.hcl
	@./box-metadata.sh libvirt kali-${VERSION}-amd64 $@

clean:
	rm -rf ./output-kali-amd64 ./packer_cache

.PHONY: help buid-libvirt
