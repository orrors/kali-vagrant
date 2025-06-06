#!/bin/bash

CUSTOM_PACKAGES_SCRIPT=provision/00-custom_software.sh

echo -e "Apt packages:\n\`\`\`"
sed -n ':x; /\\$/ {N; s/\\\n\s\+//; tx}; /apt install/ {s/.*-y //g; s/ /\n/gp}' $CUSTOM_PACKAGES_SCRIPT
echo -e "\`\`\`"

echo -e "Other packages:\n\`\`\`"
sed -n 's@curl.*bottom.*/\(bottom_.*\.deb\) .*@\1@p' $CUSTOM_PACKAGES_SCRIPT
echo -e "\`\`\`"

