[bits 16]
[cpu 8086]

; *Here there are some important values used by the kernel


KernelSeg equ 0x7e0 ; Pretty important one
; Offset that adds up to the one given in when using LoadFile
KernelOffset equ 7168 ; 14 sectors
KernelLastAddress equ KernelSeg + KernelOffset

; We load only the first FAT after the IVT and reserve 4.5KB to it
FATMemLocationOffset equ 0x500
FATMemLocation equ 0x50
; We load the root directory after the FAT and reserve 7KB to it
RootDirMemLocationOffset equ 0x1700
RootDirMemLocation equ 0x170

ProgramSeg equ 0x9c0 ; Another relevant one
ProgramOffset equ 0x100 ; MS DOS loads programs at cs:0x100
