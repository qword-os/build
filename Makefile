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

.PHONY: all clean hdd run run-nokvm

all: $(QWORD_DIR)
	$(MAKE) -C $(QWORD_DIR) install CC=x86_64-qword-gcc PREFIX=$(PREFIX)

clean: $(QWORD_DIR)
	$(MAKE) -C $(QWORD_DIR) clean

$(QWORD_DIR):
	git clone $(QWORD_REPO) $(QWORD_DIR)

ifeq ($(OS), Linux)
LOOP_DEVICE := $(shell losetup --find)
else ifeq ($(OS), FreeBSD)
LOOP_DEVICE := md9
endif

hdd: all
ifeq ($(OS), Linux)
	sudo -v
	rm -rf qword.part
	fallocate -l $(IMGSIZE)M qword.part
	echfs-utils ./qword.part quick-format 32768
	cp -v /etc/localtime root/etc/
	chmod 644 root/etc/localtime
	./copy-root-to-img.sh root qword.part
	rm -rf qword.hdd
	fallocate -l $(IMGSIZE)M qword.hdd
	fallocate -o $(IMGSIZE)M -l $$(( 67108864 + 1048576 )) qword.hdd
	./create_partition_scheme.sh
	sudo losetup -P $(LOOP_DEVICE) qword.hdd
	sudo mkfs.fat $(LOOP_DEVICE)p1
	sudo rm -rf mnt
	sudo mkdir mnt && sudo mount $(LOOP_DEVICE)p1 ./mnt
	sudo grub-install --target=i386-pc --boot-directory=`realpath ./mnt/boot` $(LOOP_DEVICE)
	sudo cp -r ./root/boot/* ./mnt/boot/
	sudo umount ./mnt
	sudo rm -rf mnt
	sudo bash -c "cat qword.part > $(LOOP_DEVICE)p2"
	sudo losetup -d $(LOOP_DEVICE)
	rm qword.part
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
	sudo gpart add -t '!14' -s 64M $(LOOP_DEVICE)
	sudo gpart add -t '!14' $(LOOP_DEVICE)
	sudo gpart set -a active -i 1 $(LOOP_DEVICE)
	sudo newfs_msdos /dev/$(LOOP_DEVICE)s1
	sudo syslinux -f -i /dev/$(LOOP_DEVICE)s1
	sudo rm -rf ./mnt && sudo mkdir mnt
	sudo mount -t msdosfs /dev/$(LOOP_DEVICE)s1 ./mnt
	sudo cp -r ./root/boot/* ./mnt/
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
	-device ahci,id=ahci                             \
	-drive if=none,id=disk,file=qword.hdd,format=raw \
	-device ide-drive,drive=disk,bus=ahci.0          \
	-smp sockets=1,cores=4,threads=1

run:
	qemu-system-x86_64 $(QEMU_FLAGS) -enable-kvm

run-nokvm:
	qemu-system-x86_64 $(QEMU_FLAGS)
