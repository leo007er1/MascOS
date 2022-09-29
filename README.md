# MascOS

16-bit Real Mode operating system made entirely in Assembly.

![MascOS logo](./Showcase/MascOSLogo.png)
![MascOS shell with the ls and fetch command](./Showcase/MascOSShell.jpg)

## Current situation of the project

The latest version includes the new VGA driver, althought scrolling is still buggy, to "reset" the screen you can just type `clear` and it will go back to normal. The "stable" version doesn't have FAT12 and it's there for testing purposes.

If you want to lear how to create program for MascOS check [a relative link](ProgramsDocumentation.md)

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

You can use the .flp image provided in the latest release or compile yourself the operating system. For the last one refer to the `Compiling` section of this file.
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
#### OS
**1. Why does the text in the ** `edit` **program blink?**
The VGA driver disables bliking to allow to use all 16 colors for background on real VGA hardware. Unfortunately on simulated VGA this doesn't work, and the text blinks.

#### Compiling
**1. losetup: Build/MascOS.flp: failed to set up loop device: Device or resource busy**
Well if you run `lsblk` you can see your devices and where they are mounted. The Makefile uses /dev/loop7 to build the os, so if you see `loop7` you need to change /dev/loop7 to something like /dev/loop8 in the makefile
