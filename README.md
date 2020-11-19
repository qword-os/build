# qword - A KISS Unix-like operating system, written in C and Assembly for x86_64.

![Reference screenshot](/screenshot.png?raw=true "Reference screenshot")

# THIS PROJECT IS DEFUNCT.
Sorry about that.

Please do not send PRs or open issues against this defunct project which will
no longer be updated.

You're free to check out the code, fork it, and all that, as long as the license
(LICENSE.md) is respected.

# Moving on

## Build requirements
In order to build qword, make sure to have the following installed:
 `wget`, `git`, `bash`, `make` (`gmake` on FreeBSD), `patch`,
 `meson` (from pip3), `ninja`, `xz`, `gzip`, `tar`,
 `gcc/g++` (8 or higher), `nasm`, `autoconf`, `bison`,
 `gperf`, `autopoint`, `help2man`,
 `fuse-devel` (on Linux), `rsync` (on Linux),
 `parted` (on Linux), and `qemu` (to test it).

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
MAKEFLAGS="-j4" ./bootstrap.sh ../build
# If your platform doesnt support fuse, you can use.
# MAKEFLAGS="-j4" USE_FUSE=no ./bootstrap.sh ../build
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
