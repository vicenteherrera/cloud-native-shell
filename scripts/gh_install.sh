#!/bin/bash

# Install a binary file from compressed GitHub repo releases channel
# by Vicente Herrera

set -euo pipefail

# repository as username/reponame in GitHub URL
[ "$REPO" == "" ] && echo "REPO env variable required" && exit 1
# filename to download from releseas channel, include VERSION when it is part of the name
: "${ZFILE:=vVERSION.tar.gz}"
# File or directory you want to move to /usr/local/bin if downloaded is a compressed file 
: "${FILE:=$ZFILE}"
# Name of the file or directory after moving to /usr/local/bin if different
: "${XFILE:=$FILE}"

GHTOKEN="${GHTOKEN:-}"
ghtoken_param=""
if [ "$GHTOKEN" != "" ]; then
  ghtoken_param="-u $GHTOKEN"
  echo "Using GitHub API token"
fi

url="https://api.github.com/repos/${REPO}/releases/latest"
http_code=$(curl --silent -L $ghtoken_param --max-time 30 --output version.txt --write-out "%{http_code}" "$url" ||:)
if [[ ${http_code} -eq 403 ]] ; then
  echo "Error 403: Forbidden"
  echo "GitHub API may have rate limited your IP address. Please wait and retry build."
  if [ "$GHTOKEN" == "" ]; then
    echo "You should use a GitHub API token to avoid rate limiting"
  fi
  echo $url
  exit 1
elif [[ ${http_code} -lt 200 || ${http_code} -gt 299 ]] ; then
  echo "Error $http_code getting version"
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

# Guess all filenames to use
if [ "$ZFILE" == "vVERSION.tar.gz" ] && [ "$FILE" == "$ZFILE" ] && [ "$XFILE" == "$ZFILE" ]; then
  echo "Applying heuristics to get url and file names"
  FILE=$(echo "$REPO" | sed 's|[a-zA-Z0-9_-]*/||')
  XFILE="$FILE"
  separator="(_|-)"
  osName="linux"
  osArch="(x86_64|amd64|64bit)"
  extension="(zip|tar\.gz|deb)"
  echo "Running query from: curl -sSfL https://api.github.com/repos/${REPO}/releases/latest"
  url=$(curl -sSfL "https://api.github.com/repos/${REPO}/releases/latest" | grep -Eio "browser_download_url.*${separator}${osName}${separator}${osArch}\.${extension}")
  if [ "$url" == "" ]; then
    echo "**Error, couldn't guess url or file to download"
    exit 1
  elif (( $(grep -c . <<<"$url") > 1 )); then
    echo "More than one possible file to download:"
    echo $url
    url="${url##*$'\n'}"
    echo "Using: $url"
  fi
  url=${url//\"}
  url=${url/browser_download_url: /}
  ZFILE=$(basename "$url")
fi

# Download from automatic source code attached to tag
url=""
if [ "$ZFILE" == 'vVERSION.tar.gz' ]; then
  url="https://github.com/${REPO}/archive/refs/tags/v$version.tar.gz"
fi

# Substitue 'VERSION' for the version tag in file names
ZFILE=$(echo ${ZFILE/VERSION/$version})
FILE=$(echo ${FILE/VERSION/$version})
XFILE=$(echo ${XFILE/VERSION/$version})

# Download from specific file attached to tag
if [ "$url" == "" ]; then
  url="https://github.com/${REPO}/releases/download/${usev}${version}/${ZFILE}"
fi

echo "$XFILE $version (https://github.com/$REPO)" | tee -a sbom.txt
echo "URL: $url"
echo "Download: $ZFILE, Extract: $FILE, Install as: $XFILE"

mkdir -p temp
cd temp

http_code=$(curl --silent -L --max-time 30 --output ${ZFILE} --write-out "%{http_code}" "$url" ||:)
if [[ ${http_code} -lt 200 || ${http_code} -gt 299 ]]; then
  echo "Error $http_code downloading file"
  echo "Check URL is correct and you are not API rate limited by your IP address"
  echo "URL: $url"
  exit 1
fi

echo "File downloaded"
[ ! -s "${ZFILE}" ] && echo "Error: file is empty, please wait and retry building to download again" && exit 1

extension="${ZFILE##*.}"
if [[ "${ZFILE}" == "${FILE}" || "${ZFILE}" != *"."* ]]; then
  echo "File is not compressed"
  sudo chmod a+x ${ZFILE}
  sudo mv ${ZFILE} /usr/local/bin/${XFILE}
  echo "Installed as /usr/local/bin/${XFILE}"
elif [ "$extension" == "deb" ]; then
  echo "File is a deb package"
  sudo apt-get install ./"${ZFILE}"
  rm "${ZFILE}"
  echo "Installed deb package ${ZFILE}"
elif [ "$extension" == "zip" ]; then
  echo "File is a zip"
  unzip "${ZFILE}" ${FILE} -d ./
  rm "${ZFILE}"
  sudo chmod a+x ${FILE}
  sudo chmod -R a+rX ${FILE}
  sudo mv ${FILE} /usr/local/bin/${XFILE}
  echo "Installed as /usr/local/bin/${XFILE}"
elif [ "$extension" == "gz" ] || [ "$extension" == "tgz" ]; then
  echo "File is gzipped"
  tar -xvzf "${ZFILE}" ${FILE}
  rm "${ZFILE}"
  sudo chmod a+x ${FILE}
  sudo chmod -R a+rX ${FILE}
  sudo mv ${FILE} /usr/local/bin/${XFILE}
  echo "Installed as /usr/local/bin/${XFILE}"
else
  echo "Unknown file type: $extension"
  exit 1
fi

cd ..
rm -rf ./temp

# if $FILE is a directory, you must change mode to the bin files in it manually
