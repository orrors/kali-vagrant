#!/bin/bash

set -eux

VAGRANT_CLOUD_USER=$1
NAME=$2
VAGRANT_BOX_FILE=$3

# Vagrant cloud api documentation
# https://developer.hashicorp.com/vagrant/vagrant-cloud/api/v2

last_version=$(curl -sf "https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}" | jq -r '.versions[-1].version' | cut -f1 -d.)
BOX_VERSION=$((last_version+1)).0.0

# create box version
curl -X POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/versions \
  --data "{ \"version\": { \"version\": \"${BOX_VERSION}\", \"description\": \"$(./scripts/describe_packages.sh)\" } }"

BOX_CHECKSUM=$(sha256sum "${VAGRANT_BOX_FILE}" | cut -d ' ' -f 1)

# create box provider
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/providers \
  --data "{ \"provider\": { \"name\": \"libvirt\", \"checksum\": \"${BOX_CHECKSUM}\", \"checksum_type\": \"sha256\", \"architecture\": \"amd64\" } }"


# get upload path
upload_path=$(curl -s \
  -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/provider/libvirt/amd64/upload \
  | jq -r .upload_path)

# upload box
curl -X PUT --upload-file ${VAGRANT_BOX_FILE} "${upload_path}"

# release version
curl -X PUT \
  -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/release

