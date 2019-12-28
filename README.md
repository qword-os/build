# qword - A KISS Unix-like operating system, written in C and Assembly for x86_64.

![Reference screenshot](/screenshot.png?raw=true "Reference screenshot")

## Prebuilt image
Get a prebuilt image today at: https://ci.oogacraft.com/job/qword/lastSuccessfulBuild/artifact/qword.hdd.xz

Note: The default user/password is 'root/root'.

## Build requirements
In order to build qword, make sure to have the following installed:
 `wget`, `git`, `bash`, `make` (`gmake` on FreeBSD), `patch`,
 `meson` (from pip3), `ninja`, `xz`, `gzip`, `tar`,
 `gcc/g++` (8 or higher), `nasm`, `autoconf`, `bison`,
 `fuse-devel`, `rsync`,
 `parted` (on Linux), `grub2` (on Linux),
 `mtools` (on FreeBSD), `syslinux` (on FreeBSD),
 and `qemu` (to test it).

## Building
```bash
# Clone repo wherever you like
git clone https://github.com/qword-os/build.git qword-build
cd qword-build/host
# Let's first build and install the echfs-utils
git clone https://github.com/qword-os/echfs.git
cd echfs
make
# This will install echfs-utils in /usr/local
sudo make install
# Else specify a PREFIX variable if you want to install it elsewhere
#make PREFIX=<myprefix> install
# Now build the toolchain (this step will take a while)
cd ../toolchain
# You can replace the 4 in -j4 with your number of cores + 1
./make_toolchain.sh -j4
# Go back to the root of the tree
cd ../..
# Build the ports distribution
cd root/src
MAKEFLAGS=-j4 ./makeworld.sh
# Now to build qword itself
cd ../..
make clean && make hdd               # For a standard release build
make clean && make DBGOUT=qemu hdd   # For QEMU console debug output
make clean && make DBGOUT=tty hdd    # For kernel tty debug output
make clean && make DBGOUT=both hdd   # For both of the above
make clean && make DBGSYM=yes hdd    # For compilation with debug symbols and other debug facilities (can be used in combination with the other options)
# And now if you wanna test it in qemu simply run
make run
# If that doesn't work because you don't have hardware virtualisation/KVM, run
make run-nokvm
# After the first time `make hdd` is ran, one can also use the much faster `make hdd-fast-sync` which also
# does not require root.
make hdd-fast-sync
```
