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

make -C "$QWORD_DIR" install CC=x86_64-qword-gcc PREFIX="$(realpath ./)"

if [ "$OS" = "Linux" ]; then
    if ! [ -f ./qword.hdd ]; then
        sudo -v
        dd if=/dev/zero bs=1M count=0 seek=$(( $IMGSIZE + 80 )) of=qword.hdd
        sudo losetup -Pf --show qword.hdd > .loopdev

        sudo parted -s `cat .loopdev` mklabel msdos
        sudo parted -s `cat .loopdev` mkpart primary 1 80
        sudo parted -s `cat .loopdev` mkpart primary 81 100%

        sudo echfs-utils `cat .loopdev`p2 quick-format 32768

        sudo mkdir -p mnt

        sudo mkfs.fat `cat .loopdev`p1
        sudo mount `cat .loopdev`p1 ./mnt

        sudo grub-install --target=i386-pc --boot-directory=`realpath ./mnt` `cat .loopdev`
        sudo sync
        sudo umount `cat .loopdev`p1

        sudo rm -rf mnt

        sudo losetup -d `cat .loopdev`
        rm .loopdev
    fi

    # Prepare root
    install -m 644 /etc/localtime root/etc/
    install -d root/lib
    install "$BUILD_DIR/system-root/usr/lib/ld.so" root/lib/

    mkdir -p mnt

    echfs-fuse --mbr -p1 qword.hdd mnt
    while ! rsync -ru --copy-links --info=progress2 "$BUILD_DIR"/system-root/* mnt; do
        true
    done # FIXME: This while loop only exists because of an issue in echfs-fuse that makes it fail randomly.
    sync
    rsync -ru --copy-links --info=progress2 root/* mnt
    sync
    fusermount -u mnt/

    guestmount --pid-file .guestfspid -a qword.hdd -m /dev/sda1 mnt/
    rsync -ru --copy-links --info=progress2 boot/* mnt
    sync
    ( guestunmount mnt/ & tail --pid=`cat .guestfspid` -f /dev/null )
    rm .guestfspid

    rm -rf ./mnt
elif [ "$OS" = "FreeBSD" ]; then
    echo "TODO: Add FreeBSD build instructions."
    exit 1
fi
