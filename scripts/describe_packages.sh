#!/bin/bash

CUSTOM_PACKAGES_SCRIPT=provision/custom.sh

echo -e "Apt packages:\n\`\`\`"
sed -n ':x; /\\$/ {N; s/\\\n\s\+//; tx}; /apt install/ {s/.*-y //g; s/ /\n/gp}' $CUSTOM_PACKAGES_SCRIPT
echo -e "\`\`\`"

echo -e "Python packages:\n\`\`\`"
sed -n '/pip install/ {s/.* install //g; s/ /\n/gp}' $CUSTOM_PACKAGES_SCRIPT
echo -e "\`\`\`"

echo -e "Other packages:\n\`\`\`"
sed -n 's@.*go install.*/\(lf\@.*\).*@\1@p' $CUSTOM_PACKAGES_SCRIPT
sed -n 's@curl.*bottom.*/\(bottom_.*\.deb\) .*@\1@p' $CUSTOM_PACKAGES_SCRIPT
echo -e "\`\`\`"

