[bits 16]
[cpu 8086]


; *Stuff from BPB
BytesPerSector equ 512 ; Word
SectorsPerCluster equ 1 ; Byte
ReservedSectors equ 1 ; Sectors for boot record, word
NumberOfFATs equ 2 ; Byte
RootDirEntries equ 224 ; Number of entries in the root directory, word
LogicalSectors equ 2880 ; Sectors in logical volume, word
MediaDescriptor equ 0xF0 ; Media descriptor byte, byte
SectorsPerFAT equ 9 ; Word
SectorsPerTrack equ 18 ; Word
DiskHeads equ 2 ; Word
HiddenSectors equ 0 ; Double word
LargeSectors equ 0 ; Sectors per LBA, double word

; Extended boot record
DriveNumber equ 0 ; Should be equal to the value returned in dl, byte
ReservedByte equ 0 ; Always 0, byte
Signature equ 0x29 ; Or 0x28 or 0x29, byte
VolumeId equ 0 ; Ignore I you aren't willing to put one, double word


; *Here there are some important values used by the kernel

KernelSeg equ 0x7e0 ; Pretty important one
; Offset that adds up to the one given in when using LoadFile
KernelOffset equ 7680 ; 15 sectors
KernelLastAddress equ KernelSeg + KernelOffset

; We load only the first FAT after the IVT and reserve 4.5KB to it
FATMemLocationOffset equ 0x500
FATMemLocation equ 0x50
; We load the root directory after the FAT and reserve 7KB to it
RootDirMemLocationOffset equ 0x1700
RootDirMemLocation equ 0x170
RootDirStartPoint equ (NumberOfFATs * SectorsPerFAT) + ReservedSectors
RootDirSize equ (RootDirEntries * 32) / BytesPerSector ; Every entry is 32 bytes

ProgramSeg equ 0x9c0 ; Another relevant one
ProgramOffset equ 0x100 ; MS DOS loads programs at cs:0x100
