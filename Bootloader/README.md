# Bootloader

This is a simple 16-bit bootloader that:

 - Sets up the BPB, Bios Parameter Block, and the extended one too
 - Sets up the stack
 - Loads the root directory, one FAT of the FAT12 filesystem
 - Prints text to the screen
 - Calculates some information about the root directory
 - Searches an entry in the FAT for the kernel and loads it
 - Jumps to the kernel
 - Probably doesn't work


Apparently the bootloader doesn't work on a real 286. I'll try to solve this.