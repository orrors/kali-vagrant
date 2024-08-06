#!/bin/bash

set -e

# when run, this script

if [[ ! -d scripts ]] ; then
	echo "Run from parent directory './scripts/$(basename $0)'"
	exit
fi

# get the current kali version
VERSION=$(curl -s "https://cdimage.kali.org/current/" | sed -n 's@.*kali-linux-\([0-9]\+.[0-9]\)\+-installer-netinst-amd64.iso".*@\1@p')
SHA256SUM=$(curl -s "https://kali.download/base-images/kali-$VERSION/SHA256SUMS" | grep 'installer-netinst-amd64.iso$' | awk '{print$1}')

sed -i "/VERSION=[0-9]\+.[0-9]/ s/[0-9]\+.[0-9]/$VERSION/" box-metadata.sh
sed -i "/cdimage.kali.org/ s/[0-9]\+.[0-9]/$VERSION/" kali.pkr.hcl
sed -i "/sha256:/ s/\(sha256:\)[^\"]*/\1$SHA256SUM/" kali.pkr.hcl
sed -i "/VERSION=[0-9]\+.[0-9]/ s/[0-9]\+.[0-9]/$VERSION/" Makefile
sed -i "/BOX_VERSION=[0-9]\+.[0-9]/ s/[0-9]\+.[0-9]/$VERSION/" scripts/upload_to_vagrant_cloud.sh
sed -i "/kali-[0-9]\+.[0-9]/ s/[0-9]\+.[0-9]/$VERSION/" Vagrantfile.template
sed -i "/kali-[0-9]\+.[0-9]-amd64/ s/[0-9]\+.[0-9]/$VERSION/" .github/workflows/build_and_publish.yml




