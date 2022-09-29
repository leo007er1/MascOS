[bits 16]
[cpu 8086]


; This file basically contains only the stuff needed for the kernel from Disk.asm in the bootloader.
; Some labels have been modified too, so it's not completely useless.

; ! IMPORTANT
; ! Since the offset to load files to is relative to the kernel, we need to change the KernelOffset variable according to how many sectors the kernel takes up.



; We load only the first FAT after the IVT and reserve 4.5KB to it
FATMemLocation equ 0x50
; We load the root directory after the FAT and reserve 7KB to it
RootDirMemLocation equ 0x170
; Offset that adds up to the one given in when using the LoadFile
KernelOffset equ 4096 ; 8 sectors

; Stuff from BPB
RootDirEntries equ 224
SectorsPerTrack equ 18
SectorsPerCluster equ 1
Heads equ 2




; Reads the disk into the specified buffer in memory
; Input:
;   bx = buffer offset
;   al = sectors to read
ReadDisk:
    call ResetDisk

    ; Buffer to read to(ES:BX) is already set

    mov ah, 0x02 ; Read please
    ; Sectors to read are already set
    mov dl, byte [BootDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, byte [ChsTrack] ; C (cylinder)
    mov dh, byte [ChsHead] ; H (head)
    mov cl, byte [ChsSector] ; S (sector). Starts from 1, not 0. Why?

    stc
    int 0x13
    jc .Check ; Carry flag set
    jmp .Exit
    
    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add [ReadAttempts], byte 1 ; If I use inc I get an error
        cmp [ReadAttempts], byte 3
        je ReadDiskError

        jmp ReadDisk

    .Exit:
        mov [ReadAttempts], byte 0
        ret



; Searches for an entry in the root dir with the given file name
; Input:
;   si = pointer to file name
; Output:
;   ah = 0 for success, 1 for error
;   dx = the given value in si
;   cx = pointer to entry in root dir
SearchFile:
    push si

    mov ax, RootDirMemLocation
    mov es, ax

    xor di, di
    mov ax, word [RootDirEntries] ; Counter
    mov dx, si

    .NextEntry:
        push di
        dec ax

        mov si, dx ; File name
        mov cx, 11 ; How many bytes to compare

        repe cmpsb

        pop di ; Get the original value back(current entry start)
        je .Exit

        add di, word 32 ; Every entry is 32 bytes

        cmp ax, word 0
        jne .NextEntry

        .Error:
            ; Nope. Nope.
            mov dx, 0x7e0
            mov es, dx

            mov ah, 1 ; Error
            pop dx
            mov cx, di

            ret

    .Exit:
        mov dx, 0x7e0
        mov es, dx

        pop dx
        xor ah, ah
        mov cx, di

        ret



; Loads a file to the specified buffer
; Input:
;   di = pointer to entry in root dir
;   bx = offset to read to(offset is relative to kernel position)
LoadFile:
    mov ax, RootDirMemLocation
    mov es, ax
    add di, word 0x1a
    mov ax, word [es:di] ; Bytes 26-27 is the first cluster

    mov dx, 0x7e0
    mov es, dx

    mov word [CurrentCluster], ax ; Save it
    add word [FileOffset], bx

    .LoadCluster:
        ; The actual data sector starts at sector 33.
        ; Also -2 because the first 2 entries are reserved
        mov ax, word [CurrentCluster]
        add ax, 31

        call LbaToChs

        mov bx, word [FileOffset]
        mov al, byte SectorsPerCluster
        call ReadDisk

        ; Calculates next cluster
        ; Since the values for the clusters are 12 bits we need to read a two bytes
        ; and kick off the other 4 bits. We do:
        ; CurrentCluster + (CurrentCluster / 2)
        mov ax, word [CurrentCluster]
        mov dx, ax
        mov bx, ax
        mov cl, byte 1
        shr bx, cl ; Shift a bit to the right, aka divide by 2
        add ax, bx

        ; Get the 12 bits
        mov bx, FATMemLocation
        mov es, bx

        mov bx, FATMemLocation
        mov bx, ax
        mov ax, word [es:bx]

        ; Would be smart to set ES back
        mov bx, 0x7e0
        mov es, bx

        ; Checks if the current cluster is even or not
        ; Checks if the first bit is 1 or 0
        test dx, 1
        jz .EvenCluster

        .OddCluster:
            mov cl, byte 4
            shr ax, cl
            jmp .Continue

        .EvenCluster:
            and ax, 0xfff

        .Continue:
            mov word [CurrentCluster], ax ; Save the new cluster

            cmp ax, word 0xff8 ; 0xff8 - 0xfff represent the last cluster
            jae .FileLoaded

            add word [FileOffset], 512 ; Next sector
            jmp .LoadCluster


        .FileLoaded:
            mov word [FileOffset], KernelOffset

            ret



; Executes a program in memory
; Input:
;   ax = value to set CS to
RunProgram:
    mov ds, ax
    mov es, ax

    call 0x920:0x0

    mov ax, 0x7e0
    mov ds, ax
    mov es, ax

    ret




; Converts LBA to CHS
; Input:
;   ax = lba address to convert
LbaToChs:
    push ax

    ; Cylinder and head
    xor dx, dx
    mov cx, word SectorsPerTrack
    div cx

    xor dx, dx
    mov cx, word Heads
    div cx

    mov byte [ChsTrack], al
    mov byte [ChsHead], dl

    ; Sectors
    pop ax
    mov cx, word SectorsPerTrack
    div cx
    inc dl ; Sectors start from 1
    mov byte [ChsSector], dl

    ret



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


ReadDiskError:
    mov al, 1
    call VgaNewLine
    mov si, ReadDiskErrorMessage
    mov ah, 0xc ; Red
    call VgaPrintString

    jmp ReadDisk.Exit




BootDisk: db 0
CurrentCluster: dw 0
FileOffset: dw KernelOffset

ChsSector: db 0
ChsTrack: db 0
ChsHead: db 0

ReadAttempts: db 0
ReadDiskErrorMessage: db "You idiot, you got a disk read error", 0