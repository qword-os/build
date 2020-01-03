#!/usr/bin/env bash

set -e

cd pkgs
TOOLS=$(echo */def.pkg | sed 's/\/def.pkg//g')
cd ..

if [ ! "$1" = "clean" ]; then
    ./pkg install $TOOLS
fi
./pkg clean $TOOLS

for i in $TOOLS; do
    ( cd pkgs/$i && rm -f installed )
done
