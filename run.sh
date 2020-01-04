#!/usr/bin/env bash

set -e

if [ -z "$IMAGE" ]; then
    IMAGE="qword.hdd"
fi

# Emulation settings
QEMU_FLAGS=" \
    $QEMU_FLAGS \
    -m 2G \
    -net none \
    -debugcon stdio \
    -d cpu_reset \
    -hda $IMAGE \
    -smp sockets=1,cores=4,threads=1 \
"

if [ -z "$NO_KVM" ]; then
    QEMU_FLAGS="$QEMU_FLAGS -enable-kvm -cpu host"
fi

qemu-system-x86_64 $QEMU_FLAGS
