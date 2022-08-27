# MascOS

16-bit Real Mode operating system made entirely in Assembly

## Current situation of the project

Currently the latest version doesn't work because since I need to load the necessary stuff to execute the kernel I need to create a driver for the filesystem, FAT12. I started creating the driver in `Disk.asm` if you want to check some sh** code. I wanted to release this update now because I can, ok? No one is gonna complain since no one cares about my project, and me mostly.

## Why MascOS

It's a learning project, as simple as that. I thought creating an operating system that targets old hardware would be a fun experiment to deal with.

## Compiling

To compile and run MascOS you need these packages:
    - Nasm

After installing these packages open a terminal window and clone this repo with:
```sh
git clone https://github.com/leo007er1/MascOS.git && cd MascOS
```

Now you can the last stable-usable version of MascOS or the latest one, but currently the latest one doesn't work and the stable one has some issue on machines than mine apparently. To compile the "stable" versione run:
```sh
make
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