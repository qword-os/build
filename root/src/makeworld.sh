#!/usr/bin/env bash

set -e

BUILDPORTS=$(echo */def.pkg | sed 's/\/def.pkg//g')

cd ../bin
if [ ! "$1" = "clean" ]; then
    ./pkg install $BUILDPORTS
fi
./pkg clean $BUILDPORTS
