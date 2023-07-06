[bits 16]
[cpu 8086]

; *Here there are some important values used by the kernel


KernelSeg equ 0x7e0 ; Pretty important one
; Offset that adds up to the one given in when using LoadFile
KernelOffset equ 7168 ; 14 sectors
KernelLastAddress equ KernelSeg + KernelOffset

ProgramSeg equ 0x9c0 ; Another relevant one
ProgramOffset equ 0x100 ; MS DOS loads programs at cs:0x100
