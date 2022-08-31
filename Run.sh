#! /bin/bash


# Yes I do use i386 because I can't get qemu-system-x86 to work
qemu-system-i386 -fda "Build/MascOS.flp" -M smm=off -no-shutdown -no-reboot -d int