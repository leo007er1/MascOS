# Bootloader

Simple 16-bit bootloader that fits in 1 sector(512 bytes) that loads and executes the kernel. Here's what it does in order:

 - Sets up the BPB, Bios Parameter Block, and the extended one too.
 - Sets up the stack.
 - Prints a boot message to the screen.
 - Loads the root directory and one FAT of the FAT12 filesystem in a specified location.
 - Searches for the kernel in the root directory and loads it in memory.
 - Passes control to the kernel by performing a far jump.
 - Probably doesn't work.


Yes *it works* on real hardware but only in legacy BIOS systems, not modern UEFI computers.