#!/usr/bin/env bash

set -euo pipefail

GIFSICLE_VERSION="1.94"
GIFSICLE_PREFIX="/opt"

echo "Cloning gifsicle sources"
wget -O "sources.tar.gz" "https://www.lcdf.org/gifsicle/gifsicle-${GIFSICLE_VERSION}.tar.gz"

echo "Extracting gifsicle sources"
mkdir -v gifsicle
tar -C ./gifsicle --strip-components=1 -xf sources.tar.gz
rm sources.tar.gz

echo "Compiling gifsicle"
cd gifsicle || exit 1
./configure --prefix="$GIFSICLE_PREFIX" --disable-gifview --disable-gifdiff
make install
