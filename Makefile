# User variables
SHELL  = /bin/bash
PREFIX = $(shell pwd)/root

LOOP_DEVICE = $(shell losetup --find)

# Add toolchain to PATH
PATH := $(shell pwd)/host/toolchain/cross-root/bin:$(PATH)

# Qword repo
QWORD_DIR  := $(shell pwd)/qword
QWORD_REPO := https://github.com/qword-os/qword.git

.PHONY: all clean hdd run run-nokvm

all:
	git clone $(QWORD_REPO) $(QWORD_DIR)
	cd $(QWORD_DIR) && $(MAKE) install PREFIX=$(shell pwd)/root && cd ..
	cp -v /etc/localtime ./root/etc/

clean:
	cd $(QWORD_DIR) && $(MAKE) uninstall PREFIX=$(shell pwd)/root && cd ..
	cd $(QWORD_DIR) && $(MAKE) clean                              && cd ..
	rm -rf $(QWORD_DIR) qword.hdd

# Image creation.
IMGSIZE := 4096

hdd: all
	sudo -v
	rm -rf qword.part
	fallocate -l $(IMGSIZE)M qword.part
	echfs-utils ./qword.part quick-format 32768
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

# Emulation settings
QEMU_FLAGS := $(QEMU_FLAGS) \
	-m 2G \
	-net none \
	-debugcon stdio \
	-d cpu_reset

run:
	qemu-system-x86_64 $(QEMU_FLAGS) -device ahci,id=ahci -drive if=none,id=disk,file=qword.hdd,format=raw -device ide-drive,drive=disk,bus=ahci.0 -smp sockets=1,cores=4,threads=1 -enable-kvm

run-nokvm:
	qemu-system-x86_64 $(QEMU_FLAGS) -device ahci,id=ahci -drive if=none,id=disk,file=qword.hdd,format=raw -device ide-drive,drive=disk,bus=ahci.0 -smp sockets=1,cores=4,threads=1
