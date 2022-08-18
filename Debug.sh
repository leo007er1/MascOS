#! /bin/bash

qemu-system-i386 -fda "Build/MascOS.img" -M smm=off -no-shutdown -no-reboot -d int -monitor stdio