#!/bin/bash

set -euo pipefail

while test $# -gt 0
do
  VERSION=$($1 --version 2>/dev/null ||:)
  if [ "$VERSION" == "" ]; then
    VERSION=$($1 version 2>/dev/null ||:); EXIT=$?
    if [ "$VERSION" == "" ]; then
      echo "**Error: don't know how to get version information from $1"
      exit 1
    fi
  fi
  if [[ ! $VERSION = $1* ]]; then
    VERSION="$1 $VERSION"
  fi
  echo $VERSION
  shift
done

