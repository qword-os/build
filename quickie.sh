#!/bin/sh

rm -f qword.hdd && ( cd qword/ && make clean ) && MAKEFLAGS="DBGOUT=qemu -j8" ./bootstrap.sh build/ && ./run.sh
