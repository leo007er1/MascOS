# MascOS

16-bit Real Mode operating system made entirely in Assembly.

## Current situation of the project

The latest version works fine. The "stable" version doesn't have FAT12 and it's there for testing purposes.

## Why MascOS

It's a learning project. I thought creating an operating system that targets old hardware would be a fun experiment to deal with.

## Compiling

To compile and run MascOS you need these packages:
    - Nasm

After installing these packages open a terminal window and clone this repo with:
```sh
git clone https://github.com/leo007er1/MascOS.git && cd MascOS
```

Now you can compile the last stable-usable version of MascOS or the latest one, but currently the stable one has some issue on machines other than mine apparently. If you compile the non-stable version you need sudo permissions because the Makefile mounts an image to /dev/loop7. To compile the "stable" versione run:
```sh
make stable
```

If you want to compile the latest version run:
```sh
make
```

Also if you want to removed the compiled files and the os image run:
```sh
make clean
```

## Running the operating system

It's very simple, but first you need to install Qemu (you need `qemu-system-i386`).
Arch
```sh
sudo pacman -S qemu-base
```

Ubuntu/Linux Mint
```sh
sudo apt install qemu
```

After installing Qemu just execute `Run.sh` with:
```sh
sh Run.sh
```

## Troubleshooting
#### Compiling
**1. mkdosfs: file Build/MascOS.flp already exists**
Run this instead of `make`
```sh
make main
```

**2. losetup: Build/MascOS.flp: failed to set up loop device: Device or resource busy**
Well if you run `lsblk` you can see your devices and where they are mounted. The Makefile uses /dev/loop7 to build the os, so if you see `loop7` you need to change /dev/loop7 to something like /dev/loop8 in the makefile
