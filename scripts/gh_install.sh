#!/bin/bash

# Install a binary file from compressed GitHub repo releases channel
# by Vicente Herrera

set -euo pipefail

function setg_content_curl {
  local url="$1"
  local gh_token="$2"
  local ghtoken_param=""
  local ret=0
  local response
  local http_code
  local content
  if [ "$gh_token" != "" ]; then
    ghtoken_param="-u $gh_token"
    echo "Using GitHub API token"
  fi
  
  response=$(curl -s -L $ghtoken_param --max-time 30 -w "%{http_code}" "$url") || ret=$?
  if [ $ret -gt 0 ]; then
    echo "**Error executing CURL to get from $url"
  fi
  http_code=$(tail -n1 <<< "$response")  # get the last line
  # echo "http_code: $http_code"
  if [ ${http_code} -eq 403 ] ; then
    echo "**Error 403: Forbidden calling $url"
    echo "Server may have rate limited your IP address. Please wait and retry build."
    if [ "$ghtoken_param" == "" ]; then
      echo "You should use a GitHub API token to avoid rate limiting"
    fi
    echo $url
    exit 1
  elif [ "${http_code}" -eq "000" ] ; then
    echo "**Error 000: Timeout calling $url"
    echo "Please wait and retry build."
    exit 1
  elif [[ ${http_code} -lt 200 || ${http_code} -gt 299 ]] ; then
    echo "**Error $http_code getting version"
    echo "Check URL is correct: $url1"
    exit 1
  fi
  GLOBAL_CONTENT=$(sed '$ d' <<< "$response")
}


# repository as username/reponame in GitHub URL
[ "$REPO" == "" ] && echo "REPO env variable required" && exit 1
# filename to download from releseas channel, include VERSION when it is part of the name
default_zfile="vVERSION.tar.gz"
: "${ZFILE:=vVERSION.tar.gz}"
# File or directory you want to move to /usr/local/bin if downloaded is a compressed file 
: "${FILE:=$ZFILE}"
# Name of the file or directory after moving to /usr/local/bin if different
: "${XFILE:=$FILE}"

# GH token for calls to its API
GHTOKEN="${GHTOKEN:-}"

# Globals
GLOBAL_CONTENT=""

echo "# Install GH $REPO"

setg_content_curl "https://api.github.com/repos/${REPO}/releases/latest" "$GHTOKEN"
version=$(echo "$GLOBAL_CONTENT" | jq ".tag_name" | xargs )

## Alternative
# GITHUB_LATEST_VERSION=$(curl -L -s -H 'Accept: application/json' https://github.com/${REPO}/releases/latest | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
# GITHUB_URL="https://github.com/${REPO}/releases/download/${GITHUB_LATEST_VERSION}/${GITHUB_FILE}"

usev=""
if [ "${version:0:1}" == "v" ]; then
  version=$(echo $version | cut -c2-)
  usev="v"
fi

# Guess all filenames to use
if [ "$ZFILE" == "$default_zfile" ] && [ "$FILE" == "$ZFILE" ] && [ "$XFILE" == "$ZFILE" ]; then
  echo "Applying heuristics to get url and file names"
  FILE=$(echo "$REPO" | sed 's|[a-zA-Z0-9_-]*/||')
  XFILE="$FILE"
  sep="(_|-|)"
  osName="(L|l)inux"
  osArch="(x86_64|amd64|64bit|)"
  extension="(zip|tar\.gz|deb)"
  optVersion="(v)?(\.[0-9])*"

  url=$(echo "$GLOBAL_CONTENT" | grep -Eio "browser_download_url.*${sep}${optVersion}${sep}${osName}${sep}${osArch}${sep}${optVersion}"'"' | head -n1 ||:)
  if [ "$url" == "" ]; then
    echo "No file without extension for download"
    url=$(echo "$GLOBAL_CONTENT" | grep -Eio "browser_download_url.*${sep}${optVersion}${sep}${osName}${sep}${osArch}${sep}${optVersion}\.${extension}" | head -n1 ||:)
  else
    echo "Found file without extension for download"
    FILE=""
  fi
  if [ "$url" == "" ]; then
    echo "**Error, couldn't guess url or file to download"
    echo "$GLOBAL_CONTENT" | grep -Eio "browser_download_url.*"
    exit 1
  elif (( $(grep -c . <<<"$url") > 1 )); then
    echo "More than one possible file to download:"
    echo $url
    url="${url##*$'\n'}"
    echo "Using: $url"
    exit 1
  fi
  url=${url//\"}
  url=${url/browser_download_url: /}
  echo "At $url"
  ZFILE=$(basename "$url")
  [ "$FILE" == "" ] && FILE="$ZFILE"
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

echo "$XFILE $version (https://github.com/$REPO)"
echo "URL: $url"
echo "Download: $ZFILE, Extract: $FILE, Install as: $XFILE"

mkdir -p temp
cd temp

ret=0
http_code=$(curl --silent -L --max-time 30 --output ${ZFILE} --write-out "%{http_code}" "$url") || ret=$?
if [ $ret -gt 0 ]; then
  echo "**Error getting file with CURL from $url"
  exit 1
fi
if [[ ${http_code} -lt 200 || ${http_code} -gt 299 ]]; then
  echo "Error $http_code downloading file from $url"
  echo "Check URL is correct and you are not API rate limited by your IP address"
  exit 1
fi

echo "File downloaded"
[ ! -s "${ZFILE}" ] && echo "Error: file is empty, please wait and retry building to download again" && exit 1

extension="${ZFILE##*.}"
if [ "$extension" == "deb" ]; then
  echo "File is a deb package"
  sudo apt-get install ./"${ZFILE}"
  rm "${ZFILE}"
  echo "Installed deb package ${ZFILE}"
  cd ..
  echo "$ZFILE $version (https://github.com/$REPO)" | tee -a sbom.txt
else 
  if [[ "${ZFILE}" == "${FILE}" ]]; then
    echo "File is not compressed"    
  elif [ "$extension" == "zip" ]; then
    echo "File is a zip"
    unzip "${ZFILE}" ${FILE} -d ./
    rm "${ZFILE}"
  elif [ "$extension" == "gz" ] || [ "$extension" == "tgz" ]; then
    echo "File is gzipped"
    tar -xvzf "${ZFILE}" ${FILE}
    rm "${ZFILE}"
  else
    echo "Unknown file type: $extension"
    exit 1
  fi
  sudo chmod a+x ${FILE}
  sudo chmod -R a+rX ${FILE}
  sudo mv ${FILE} /usr/local/bin/${XFILE}
  echo "Installed as /usr/local/bin/${XFILE}"
  size=$(du --apparent-size --block-size=1 -sh "/usr/local/bin/${XFILE}" | awk '{ print $1 }')
  cd ..
  echo "$XFILE $version (https://github.com/$REPO) $size" | tee -a sbom.txt
fi

rm -rf ./temp

# if $FILE is a directory, you must change mode to the bin files in it manually
