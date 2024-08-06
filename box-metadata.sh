#!/bin/bash
set -euo pipefail

VERSION=2024.2

provider="$1"
name="$2"
path="$3"

# see https://developer.hashicorp.com/vagrant/docs/boxes/format#box-metadata
cat >"$path.json" <<EOF
{
  "name": "$name",
  "versions": [
    {
      "version": "$VERSION",
      "providers": [
        {
          "name": "$provider",
          "url": "$path"
        }
      ]
    }
  ]
}
EOF

echo
echo Add the Vagrant Box with:
echo "vagrant box add -f $name $path.json"
