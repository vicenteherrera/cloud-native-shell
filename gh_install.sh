#!/bin/bash

# Install a binary file from compressed GitHub repo releases channel
# by Vicente Herrera

set -e pipefail

# repository as username/reponame in GitHub URL
[ "$REPO" == "" ] && echo "REPO env variable required" && exit 1
# filename to download from releseas channel, include VERSION when it is part of the name
[ "$ZFILE" == "" ] && echo "ZFILE env variable required" && exit 1
# File or directory you want to move to /usr/local/bin if downloaded is a compressed file 
: "${FILE:=$ZFILE}"
# Name of the file or directory after moving to /usr/local/bin if different
: "${XFILE:=$FILE}"

usev=""
version=$(curl -s https://api.github.com/repos/${REPO}/releases/latest | jq ".tag_name" | xargs )
if [ "${version:0:1}" == "v" ]; then
  version=$(echo $version | cut -c2-)
  usev="v"
fi

echo "$XFILE $version (https://github.com/$REPO)" | tee sbom.txt

ZFILE=$(echo ${ZFILE/VERSION/$version})
FILE=$(echo ${FILE/VERSION/$version})
XFILE=$(echo ${XFILE/VERSION/$version})

wget -q --show-progress https://github.com/${REPO}/releases/download/${usev}${version}/${ZFILE}

extension="${ZFILE##*.}"

if [[ "$ZFILE" != *"."* ]]; then
  echo "file is not compressed"
elif [ "$extension" == "zip" ]; then
  unzip ${ZFILE}
  rm ${ZFILE}
elif [ "$extension" == "gz" ]; then
  tar -xvzf ${ZFILE}
  rm ${ZFILE}
elif [ "$extension" == "tgz" ]; then
  tar -xvzf ${ZFILE}
  rm ${ZFILE}
else
  echo "unknown file type"
  exit 1
fi

sudo chmod a+x ${FILE}
sudo mv ${FILE} /usr/local/bin/${XFILE}
# if $FILE is a directory, you must change mode to the bin files in it manually
