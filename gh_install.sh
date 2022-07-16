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

http_code=$(curl --silent -L --max-time 30 --output version.txt --write-out "%{http_code}" "https://api.github.com/repos/${REPO}/releases/latest")
if [[ ${http_code} -eq 403 ]] ; then
  echo "Error 403: Forbidden"
  echo "Check URL is correct and you are not API rate limited by your IP address"
  echo $url
  exit 1
elif [[ ${http_code} -lt 200 || ${http_code} -gt 299 ]] ; then
  echo "Error ${http_code} getting version"
  echo "Check URL is correct: $url"
  exit 1
fi
version=$(cat version.txt | jq ".tag_name" | xargs )
rm version.txt
usev=""
if [ "${version:0:1}" == "v" ]; then
  version=$(echo $version | cut -c2-)
  usev="v"
fi

echo "$XFILE $version (https://github.com/$REPO)" | tee sbom.txt

ZFILE=$(echo ${ZFILE/VERSION/$version})
FILE=$(echo ${FILE/VERSION/$version})
XFILE=$(echo ${XFILE/VERSION/$version})

# wget -q --show-progress https://github.com/${REPO}/releases/download/${usev}${version}/${ZFILE}

url="https://github.com/${REPO}/releases/download/${usev}${version}/${ZFILE}"
echo "URL: $url"
echo "Download: $ZFILE, Extract: $FILE, Install as: $XFILE"

http_code=$(curl --silent -L --max-time 30 --output ${ZFILE} --write-out "%{http_code}" "$url")
if [[ ${http_code} -lt 200 || ${http_code} -gt 299 ]]; then
  echo "Error downloading file"
  echo "Check URL is correct and you are not API rate limited by your IP address"
  echo $url
  exit 1
fi

extension="${ZFILE##*.}"

if [[ "$ZFILE" != *"."* ]]; then
  echo "file is not compressed"
elif [ "$extension" == "deb" ]; then
  sudo apt install ./"$ZFILE"
  rm "$ZFILE"
elif [ "$extension" == "zip" ]; then
  unzip ${ZFILE}
  rm ${ZFILE}
  sudo chmod a+x ${FILE}
  sudo mv ${FILE} /usr/local/bin/${XFILE}
elif [ "$extension" == "gz" ]; then
  tar -xvzf ${ZFILE}
  rm ${ZFILE}
  sudo chmod a+x ${FILE}
  sudo mv ${FILE} /usr/local/bin/${XFILE}
elif [ "$extension" == "tgz" ]; then
  tar -xvzf ${ZFILE}
  rm ${ZFILE}
  sudo chmod a+x ${FILE}
  sudo mv ${FILE} /usr/local/bin/${XFILE}
else
  echo "unknown file type"
  exit 1
fi

# if $FILE is a directory, you must change mode to the bin files in it manually
