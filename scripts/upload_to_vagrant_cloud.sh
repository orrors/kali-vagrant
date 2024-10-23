#!/bin/bash

set -eux

VAGRANT_CLOUD_USER=$1
NAME=$2
VAGRANT_BOX_FILE=$3

# Vagrant cloud api documentation
# https://developer.hashicorp.com/vagrant/vagrant-cloud/api/v2

BOX_VERSION=2024.3
PROVIDER='libvirt'

if [[ ! -f ${VAGRANT_BOX_FILE} ]] ; then
  exit 1
fi

version_status=$(curl -s \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION} | jq -r '.status')


# create box version if it doesn't exist
if [[ $version_status == 'null' ]]; then
  curl -X POST \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/versions \
    --data "{ \"version\": { \"version\": \"${BOX_VERSION}\", \"description\": \"$(./scripts/describe_packages.sh)\" } }"
fi

BOX_CHECKSUM=$(sha256sum "${VAGRANT_BOX_FILE}" | cut -d ' ' -f 1)

# check if provider already exists
provider_checksum=$(curl -s \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/provider/${PROVIDER}/amd64" | jq -r '.checksum')


if [[ $provider_checksum == $BOX_CHECKSUM ]]; then
  echo Existing version box is the same. Nothing to do...
  exit
fi

if [[ $provider_checksum == 'null' ]]; then
  # create box provider if not exists
  curl -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/providers \
    --data "{ \"provider\": { \"name\": \"${PROVIDER}\", \"checksum\": \"${BOX_CHECKSUM}\", \"checksum_type\": \"sha256\", \"architecture\": \"amd64\" } }"
else
  # update box provider
  curl -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/provider/${PROVIDER}/amd64 \
    --data "{ \"provider\": { \"name\": \"${PROVIDER}\", \"checksum\": \"${BOX_CHECKSUM}\", \"checksum_type\": \"sha256\", \"architecture\": \"amd64\" } }"
fi

# get upload path
upload_path=$(curl -s \
  -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/provider/${PROVIDER}/amd64/upload \
  | jq -r .upload_path)

# upload box
curl -X PUT --upload-file ${VAGRANT_BOX_FILE} "${upload_path}"

# release version
if [[ $version_status != 'active' ]]; then
  curl -X PUT \
    -H "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    https://app.vagrantup.com/api/v2/box/${VAGRANT_CLOUD_USER}/${NAME}/version/${BOX_VERSION}/release
fi

