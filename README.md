# qword - A KISS Unix-like operating system, written in C and Assembly for x86_64.

![Reference screenshot](/screenshot.png?raw=true "Reference screenshot")

## Discord
Join our Discord! Invite: https://discord.gg/z6b3qZC

## Prebuilt image
Get a prebuilt image today at: https://ci.oogacraft.com/job/qword/lastSuccessfulBuild/artifact/qword.hdd.xz

Note 1: This is a hard drive image compressed with xz. Unpack it with
```bash
xzcat < qword.hdd.xz > qword.hdd
```

Note 2: This image can be ran on QEMU using the provided `run.sh` script
```bash
./run.sh qword.hdd
```
This image should also work on other VM software assuming it is inserted into a ATA controller.
The image can also be booted off a SATA or NVMe device, but that requires editing
the `root=...` parameter in GRUB's config. One can do this by pressing `e` when the
boot menu shows up.
Useful root values are `ideXpY`, `nvmeXpY`, and `sataXpY`, where `X` is the number of the
device in the system and `Y` is the partition number. The partition number of the root
partition in the provided image is `1`.

Note 3: The default user/password is 'root/root'.

## Build requirements
In order to build qword, make sure to have the following installed:
 `wget`, `git`, `bash`, `make` (`gmake` on FreeBSD), `patch`,
 `meson` (from pip3), `ninja`, `xz`, `gzip`, `tar`,
 `gcc/g++` (8 or higher), `nasm`, `autoconf`, `bison`,
 `gperf`, `autopoint`, `help2man`,
 `fuse-devel` (on Linux), `rsync` (on Linux),
 `libguestfs` (on Linux),
 `parted` (on Linux), `grub2` (on Linux),
 `mtools` (on FreeBSD), `syslinux` (on FreeBSD),
 and `qemu` (to test it).

After installing `libguestfs` it might be necessary to run the following:
```bash
sudo install -d /usr/lib/guestfs
sudo update-libguestfs-appliance
```

The echfs utilities are necessary to build the image. Install them:
```bash
git clone https://github.com/qword-os/echfs.git
cd echfs
make
# This will install echfs-utils in /usr/local
sudo make install
```

And finally, make sure you have `xbstrap`. You can install it from `pip3`:
```bash
sudo pip3 install xbstrap
```

## Building
```bash
# Clone this repo wherever you like
git clone https://github.com/qword-os/build.git qword-bootstrap
# Create and enter a build directory
mkdir build && cd build
# Initialise xbstrap and start a full build
xbstrap init ../qword-bootstrap
xbstrap install --all
# Enter the qword-bootstrap directory
cd ../qword-bootstrap
# Create the image using the bootstrap.sh script
./bootstrap.sh ../build
# And now if you wanna test it in qemu simply run
./run.sh
# If that doesn't work because you don't have hardware virtualisation/KVM, run
NO_KVM=1 ./run.sh
```

Some MAKEFLAGS that can be useful are:
```bash
MAKEFLAGS="-j8" ./bootstrap.sh ../build  # For parallelism
MAKEFLAGS="DBGOUT=qemu -j8" ./bootstrap.sh ../build  # For QEMU console debug output
DBGOUT=tty    # For kernel tty debug output
DBGOUT=both   # For both of the above
DBGSYM=yes    # For compilation with debug symbols and other debug facilities (can be used in combination with the other options)
```
