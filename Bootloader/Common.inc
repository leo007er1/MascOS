[bits 16]
[cpu 8086]

; *Here there are some important values used by the kernel


KernelSeg equ 0x7e0 ; Pretty important one
; Offset that adds up to the one given in when using the LoadFile
KernelOffset equ 6144 ; 12 sectors
KernelLastAddress equ 0x960 ; KernelSeg + KernelOffset / 512
ProgramSeg equ 0x960 ; Another relevant one
