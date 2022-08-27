[bits 16]
[cpu 286]


; *NOTES
; *FAT on disk looks like this:
; *-------------------------------------------------------------------------------
; *| Boot sector | Extra reserved sectors | FAT1 | FAT2 | Root dir | Data region |
; *-------------------------------------------------------------------------------
;
; *How to calculate start point of root directory:
; ReservedSectors + (NumberOfFATs * SectorsPerFAT) = 19
; *How to calculate the size of the root dir:
; 32(entry size) * RootDirEntries / BytesPerSector




; Reads the disk into the specified buffer in memory
; Input:
;   bx = buffer offset
;   al = sectors to read
ReadDisk:
    call ResetDisk

    ; Buffer to read to(ES:BX) is already set

    mov ah, 0x02 ; Read please
    ; Sectors to read are alraady set
    mov dl, byte [BootDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, byte [ChsTrack] ; C (cylinder)
    mov dh, byte [ChsHead] ; H (head)
    mov cl, byte [ChsSector] ; S (sector). Starts from 1, not 0. Why?

    int 0x13
    jc .Check ; Carry flag set
    jmp .Exit
    
    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add [ReadAttempts], byte 1 ; If I use inc I get and error
        cmp [ReadAttempts], byte 3
        je ReadDiskError

        jmp ReadDisk

    .Exit:
        mov [ReadAttempts], byte 0
        ret



; Searches all entries for kernel
SearchKernel:
    mov cx, word [RootDirEntries] ; loop uses cx as counter
    mov di, 0x7e00 ; Where we loaded the root dir table

    .NextEntry:
        push cx
        push di

        mov si, KernelFileName ; First string
        mov cx, 11 ; How many bytes to compare

        rep cmpsb

        pop di ; Sets the original value back
        je .KernelFound

        ; Nope
        pop cx
        add di, 32 ; Bytes per entry
        loop .NextEntry

        ; Oh no, no mighty kernel?
        jmp ReadDiskError

    .KernelFound:

        jmp $




; Resets the disk: moves to the first sector
; Output:
;   ah = status (0 if success)
;   cf = 0 if success, set if not
ResetDisk:
    push ax

    mov ah, 0
    mov dl, [BootDisk]
    int 0x13

    pop ax

    ret



; Converts LBA to CHS
; Input:
;   ax = lba address to convert
LbaToChs:
    push cx
    mov dx, 0

    ; Sector
    div word [SectorsPerTrack]
    inc dl ; Sectors start from 1
    mov byte [ChsSector], dl

    ; Head and track
    mov dx, 0
    div word [Heads]
    mov byte [ChsTrack], al
    mov byte [ChsHead], dl

    pop cx

    ret



; Gets root dir info and stores it into variables
GetRootDirInfo:
    mov ax, 0
    mov dx, 0

    ; Gets the start point of the root dir
    mov al, byte [NumberOfFATs]
    mul word [SectorsPerFAT]
    add ax, word [ReservedSectors]

    mov word [RootDirStartPoint], ax

    ; Gets the size in sectors of the root dir
    mov ax, 32 ; Every entry is 32 bytes
    mul word [RootDirEntries]
    div word [BytesPerSector]

    mov word [RootDirSize], ax

    ret



ReadDiskError:
    mov si, ReadDiskErrorMessage
    call PrintString

    ; Wait for key press
    mov ah, 0
    int 0x16

    ; Reboot
    mov ah, 0
    int 0x19





BootDisk: db 0
RootDirSize: dw 0
RootDirStartPoint: dw 0
KernelFileName: db "KERNEL  BIN"
CurrentCluster: dw 0

ChsSector: db 0
ChsTrack: db 0
ChsHead: db 0

ReadAttempts: db 0
ReadDiskErrorMessage: db 10, 13, "Disk read error", 0