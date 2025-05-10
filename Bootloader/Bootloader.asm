[org 0x7c00]
[bits 16]
[cpu 8086]

; *IMPORTANT STUFF
; *FAT stuff: https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system




jmp short Start
nop



; --//  BIOS paramenter block (BPB)  \\--



OEMidentifier: db "MSDOS5.0"
dw BytesPerSector
db SectorsPerCluster
dw ReservedSectors ; Sectors for boot record
db NumberOfFATs ; Number of copies of FAT. Usually 2
dw RootDirEntries ; Number of entries in the root directory
dw LogicalSectors ; Sectors in logical volume
db MediaDescriptor ; Media descriptor byte, see IMPORTANT STUFF at the beggining of this file
dw SectorsPerFAT
dw SectorsPerTrack
dw DiskHeads
dd HiddenSectors
dd LargeSectors ; Sectors per LBA

; Extended boot record
db DriveNumber ; Should be equal to the value returned in dl
db ReservedByte ; Always 0
db Signature ; Or 0x28 or 0x29
dd VolumeId ; Ignore I you aren't willing to put one
VolumeLabel: db "MASCOS     " ; Anything but must be 11 bytes
FileSystem: db "FAT12   " ; Don't touch pls



; --//  Bootloader code  \\--




; Some BIOSes jump to the boot sector with 0x07c0:0x0000 or 0x0000:0x7c00 and other ways so we set CS to 0
Start:
    cli
    jmp 0x0000:Main


Main:
    ; Segments setup
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    ; Saves the number of the drive where we currently are
    mov byte [BootDisk], dl

    ; Stack setup
    mov ss, ax
    mov sp, 0x7c00

    sti

    lea si, BootMessage
    call PrintString

    jmp LoadFAT
    call SearchKernel

    cli
    hlt


BootMessage: db "Preparing the couch for kernel...", 0


%include "./Bootloader/Print.asm"
%include "./Bootloader/Disk.asm"
%include "./Bootloader/Common.inc"


; Fills the rest of the sector with 0s and boot signature
times 510-($-$$) db 0
dw 0xaa55