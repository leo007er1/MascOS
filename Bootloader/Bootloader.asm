[org 0x7c00]
[bits 16]
[cpu 8086]

; *IMPORTANT STUFF
; *FAT stuff: https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system




jmp short Start
nop



; --//  BIOS paramenter block (BPB)  \\--



OEMidentifier: db "MascOS  "
BytesPerSector: dw 512
SectorsPerCluster: db 1
ReservedSectors: dw 1 ; Sectors for boot record
NumberOfFATs: db 2 ; Number of copies of FAT. Usually 2
RootDirEntries: dw 224 ; Number of entries in the root directory
LogicalSectors: dw 2880 ; Sectors in logical volume
MediaDescriptor: db 0xF0 ; Media descriptor byte, see IMPORTANT STUFF at the beggining of this file
SectorsPerFAT: dw 9
SectorsPerTrack: dw 18
Heads: dw 2
HiddenSectors: dd 0
LargeSectors: dd 0 ; Sectors per LBA

; Extended boot record
DriveNumber: dw 0 ; Should be equal to the value returned in dl
Signature: db 0x29 ; Or 0x28 or 0x29
VolumeId: dd 0 ; Ignore I you aren't willing to put one
VolumeLabel: db "MascOS     " ; Anything but must be 11 bytes
FileSystem: db "FAT12   " ; Don't touch pls



; --//  Bootloader code  \\--




; Some BIOSes jump to the boot sector with 0x07c0:0x0000 or 0x0000:0x7c00 and other ways so we set CS to 0
Start:
    cli
    jmp 0x0000:Main


Main:
    ; Saves the number of the drive where we currently are
    mov byte [BootDisk], dl

    ; Segments setup
    xor ax, ax
    mov ds, ax
    mov es, ax
    ; mov fs, ax
    ; mov gs, ax

    ; Stack setup
    mov ss, ax
    mov sp, 0x7c00

    sti

    call GetMemoryAvaiable

    jmp LoadFAT
    call SearchKernel

    cli
    hlt




%include "./Bootloader/Print.asm"
%include "./Bootloader/Disk.asm"
%include "./Bootloader/Memory.asm"


; Fills the rest of the sector with 0s and boot signature
times 510-($-$$) db 0
dw 0xaa55