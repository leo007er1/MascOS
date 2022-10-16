#! /bin/bash

qemu-system-i386 -fda "Build/MascOS.flp" -M smm=off -no-shutdown -no-reboot -d int -monitor stdio -D ./QemuLog.txt -cpu 486 -audiodev oss,driver=oss,id=audio0 -machine pcspk-audiodev=audio0