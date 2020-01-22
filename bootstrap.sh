#!/usr/bin/env bash

DEFAULT_IMAGE_SIZE=4096

set -e

if [ -z "$1" ]; then
    echo "Usage: ./bootstrap.sh BUILD_DIRECTORY [IMAGE_SIZE_MB]"
    exit 0
fi

# Accepted host OSes else fail.
OS=$(uname)
if ! [ "$OS" = "Linux" ] || [ "$OS" = "FreeBSD" ]; then
    echo "Host OS \"$OS\" is not supported."
    exit 1
fi

# Image size in MiB
if [ -z "$2" ]; then
    IMGSIZE=$DEFAULT_IMAGE_SIZE
else
    IMGSIZE="$2"
fi

# Make sure BUILD_DIR is absolute
BUILD_DIR="$(realpath $1)"

# Qword repo
QWORD_DIR="$(realpath ./qword)"
QWORD_REPO=https://github.com/qword-os/qword.git

# Add toolchain to PATH
PATH="$BUILD_DIR/tools/cross-binutils/bin:$PATH"
PATH="$BUILD_DIR/tools/system-gcc/bin:$PATH"

set -x

[ -d "$QWORD_DIR" ] || git clone "$QWORD_REPO" "$QWORD_DIR"
make -C "$QWORD_DIR"

# Download and build qloader2's toolchain
if ! [ -d qloader2 ]; then
    git clone https://github.com/qword-os/qloader2.git
    ( cd qloader2/toolchain && ./make_toolchain.sh "$MAKEFLAGS" )
fi

if [ "$OS" = "Linux" ]; then
    if ! [ -f ./qword.hdd ]; then
        dd if=/dev/zero bs=1M count=0 seek=$IMGSIZE of=qword.hdd

        parted -s qword.hdd mklabel msdos
        parted -s qword.hdd mkpart primary 1 100%

        echfs-utils -m -p0 qword.hdd quick-format 32768
    fi

    # Install qloader2
    ( cd qloader2 && make && ./qloader2-install ../qword.hdd )

    # Prepare root
    install -m 644 qword/qword.bin root/
    install -m 644 /etc/localtime root/etc/
    install -d root/lib
    install "$BUILD_DIR/system-root/usr/lib/ld.so" root/lib/

    mkdir -p mnt

    echfs-fuse --mbr -p0 qword.hdd mnt
    while ! rsync -ru --copy-links --info=progress2 "$BUILD_DIR"/system-root/* mnt; do
        true
    done # FIXME: This while loop only exists because of an issue in echfs-fuse that makes it fail randomly.
    sync
    rsync -ru --copy-links --info=progress2 root/* mnt
    sync
    fusermount -u mnt/

    rm -rf ./mnt
elif [ "$OS" = "FreeBSD" ]; then
    echo "TODO: Add FreeBSD build instructions."
    exit 1
fi
