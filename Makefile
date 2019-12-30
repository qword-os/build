# Accepted host OSes else fail.
OS := $(shell uname)
ifeq      ($(OS), Linux)
else ifeq ($(OS), FreeBSD)
else
$(error Host OS $(OS) is not supported.)
endif

# User variables
PREFIX = $(shell pwd)/root
# -- Image size in M.
IMGSIZE = 4096

# Add toolchain to PATH
PATH := $(shell pwd)/host/toolchain/cross-root/bin:$(PATH)

# Qword repo
QWORD_DIR  := $(shell pwd)/qword
QWORD_REPO := https://github.com/qword-os/qword.git

.PHONY: all prepare clean hdd run run-nokvm

all: prepare
	$(MAKE) -C $(QWORD_DIR) install CC=x86_64-qword-gcc PREFIX=$(PREFIX)

clean:
	$(MAKE) -C $(QWORD_DIR) clean || true

prepare: $(QWORD_DIR)
ifeq ($(PULLREPOS), true)
	cd $(QWORD_DIR) && git pull
else
	true # -- NOT PULLING QWORD REPO -- #
endif

$(QWORD_DIR):
	git clone $(QWORD_REPO) $(QWORD_DIR)

ifeq ($(OS), FreeBSD)
LOOP_DEVICE := md9
endif

hdd: all
ifeq ($(OS), Linux)
ifeq (,$(wildcard ./qword.hdd))
	sudo -v
	dd if=/dev/zero bs=1M count=0 seek=$$(( $(IMGSIZE) + 80 )) of=qword.hdd
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
endif
	cp -v /etc/localtime root/etc/
	chmod 644 root/etc/localtime

	mkdir -p mnt

	echfs-fuse --mbr -p1 qword.hdd mnt
	rsync -ru --copy-links --info=progress2 root/* mnt/
	sync
	fusermount -u mnt/

	guestmount --pid-file .guestfspid -a qword.hdd -m /dev/sda1 mnt/
	rsync -ru --copy-links --info=progress2 root/boot/* mnt/
	sync
	( guestunmount mnt/ & tail --pid=`cat .guestfspid` -f /dev/null )
	rm .guestfspid

	rm -rf ./mnt
else ifeq ($(OS), FreeBSD)
	sudo -v
	rm -rf qword.part
	dd if=/dev/zero bs=1M count=0 seek=$(IMGSIZE) of=qword.part
	echfs-utils ./qword.part quick-format 32768
	cp -v /etc/localtime root/etc/
	chmod 644 root/etc/localtime
	./copy-root-to-img.sh root qword.part
	rm -rf qword.hdd
	dd if=/dev/zero bs=1M count=0 seek=$$(( $(IMGSIZE) + 65 )) of=qword.hdd
	sudo mdconfig -a -t vnode -f qword.hdd -u $(LOOP_DEVICE)
	sudo gpart create -s mbr $(LOOP_DEVICE)
	sudo mdconfig -d -u $(LOOP_DEVICE)
	dd if=./syslinux/mbr.bin of=qword.hdd conv=notrunc
	sudo mdconfig -a -t vnode -f qword.hdd -u $(LOOP_DEVICE)
	sudo gpart add -a 4k -t '!14' -s 64M $(LOOP_DEVICE)
	sudo gpart add -a 4k -t '!14' $(LOOP_DEVICE)
	sudo gpart set -a active -i 1 $(LOOP_DEVICE)
	sudo newfs_msdos /dev/$(LOOP_DEVICE)s1
	sudo syslinux -f -i /dev/$(LOOP_DEVICE)s1
	sudo rm -rf ./mnt && sudo mkdir mnt
	sudo mount -t msdosfs /dev/$(LOOP_DEVICE)s1 ./mnt
	sudo cp -r ./root/boot/* ./mnt/
	sync
	sudo umount /dev/$(LOOP_DEVICE)s1
	sudo rm -rf ./mnt
	sudo dd bs=4M if=qword.part of=/dev/$(LOOP_DEVICE)s2 status=progress
	sudo mdconfig -d -u $(LOOP_DEVICE)
	rm qword.part
endif

# Emulation settings
QEMU_FLAGS := $(QEMU_FLAGS)                          \
	-m 2G                                            \
	-net none                                        \
	-debugcon stdio                                  \
	-d cpu_reset                                     \
	-hda qword.hdd                                   \
	-smp sockets=1,cores=4,threads=1

run:
	qemu-system-x86_64 $(QEMU_FLAGS) -enable-kvm -cpu host

run-nokvm:
	qemu-system-x86_64 $(QEMU_FLAGS)
