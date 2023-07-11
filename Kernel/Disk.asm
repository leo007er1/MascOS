[bits 16]
[cpu 8086]


; This file basically contains only the stuff needed for the kernel from Disk.asm in the bootloader.
; Some labels have been modified too, so it's not completely useless.

; ! IMPORTANT
; ! Since the offset to load files to is relative to the kernel, we need to change the KernelOffset variable according to how many sectors the kernel takes up.



; Stuff from BPB
RootDirEntries equ 224
SectorsPerTrack equ 18
SectorsPerCluster equ 1
Heads equ 2



; Where int 0x21 brings us to
; Input:
;   ah = function to execute
DiskIntHandler:
    test ah, ah
    jnz .NoSearchFile
    call SearchFile
    jmp .Exit

    .NoSearchFile:
        cmp ah, byte 1
        jne .NoLoadFile
        call LoadFile
        jmp .Exit

    .NoLoadFile:
        cmp ah, byte 2
        jne .NoFileName
        call GetFileName
        jmp .Exit

    .NoFileName:
        cmp ah, byte 3
        jne .Exit
        call GetFileSize

    .Exit:
        ; Tell the PIC we are done with interrupt
        mov al, 0x20
        out 0x20, al

        iret




; Reads the disk into the specified buffer in memory
; Input:
;   es:bx = buffer offset
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
        add byte [ReadAttempts], byte 1 ; If I use inc I get an error
        cmp byte [ReadAttempts], byte 3
        je DiskError

        jmp ReadDisk

    .Exit:
        mov byte [ReadAttempts], byte 0
        ret



; Writes the given buffer to the disk
; Code is basically the same as ReadDisk
; Input:
;   al = number of sectors to write
;   es:bx = data buffer
WriteDisk:
    call ResetDisk

    ; Es:bx is the data buffer
    mov ah, byte 3
    ; Al contains sectors to write
    mov dl, byte [BootDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, byte [ChsTrack] ; C (cylinder)
    mov dh, byte [ChsHead] ; H (head)
    mov cl, byte [ChsSector] ; S (sector). Starts from 1, not 0. Why?

    stc
    int 0x13
    jnc .Exit

    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add byte [ReadAttempts], byte 1 ; If I use inc I get an error
        cmp byte [ReadAttempts], byte 3
        je DiskError

        jmp WriteDisk

    .Exit:
        mov byte [ReadAttempts], byte 0
        ret



; Scans the root directory for the first empty entry
; Output:
;   di = offset to entry, also saved inside FirstEmptyEntry
GetFirstEmptyEntry:
    push ax
    push si
    push es

    mov ax, RootDirMemLocation
    mov es, ax
    xor si, si

    .CheckEntry:
        cmp byte [es:si], byte 0
        jz .FoundIt

        add si, word 32 ; Next entry

        jmp .CheckEntry


    .FoundIt:
        mov word [FirstEmptyEntry], di

        pop ax
        mov es, ax

        pop si
        pop ax

        ret



; As the name says, it finds the first unused cluster
; Input:
;   ax = cluster to start from
GetFirstFreeCluster:
    push bx
    push cx
    push dx

    mov word [FirstEmptyCluster], ax

    push es
    mov bx, FATMemLocation
    mov es, bx

    .FindCluster:
        mov ax, word [FirstEmptyCluster]
        mov dx, ax
        mov bx, ax
        mov cl, byte 1
        shr bx, cl
        add ax, bx

        ; Get the 12 bits
        mov bx, ax
        mov ax, word [es:bx]

        ; Checks if the current cluster is even or not
        test dx, 1
        jz .EvenCluster

        .OddCluster:
            mov cl, byte 4
            shr ax, cl
            jmp .Continue

        .EvenCluster:
            and ax, 0xfff

        .Continue:
            cmp ax, word 0
            jz .Exit

            inc word [FirstEmptyCluster]
            jmp .FindCluster

    .Exit:
        cli
        hlt

        pop dx
        mov es, dx
        pop dx
        pop cx
        pop bx
        ret



; Searches for an entry in the root dir with the given file name
; Input:
;   si = pointer to file name
; Output:
;   carry flag = clear for success, set for error
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

        test ax, ax
        jnz .NextEntry

        .Error:
            ; Nope. Nope.
            mov dx, KernelSeg
            mov es, dx

            stc
            pop dx
            mov cx, di

            ret

    .Exit:
        mov dx, KernelSeg
        mov es, dx

        pop dx
        mov cx, di
        clc

        ret



; Get a files name from the given entry in the root directory
; Input:
;   bx = pointer to entry in root directory
;   ds:si = pointer to string to output name to(12 characters because remember the 0 at the end)
GetFileName:
    push cx
    push dx
    push es

    mov dx, RootDirMemLocation
    mov es, dx

    mov cl, byte 11 ; Counter

    .OutputName:
        test cl, cl
        jz .End

        mov al, byte [es:bx]
        mov byte [ds:si], al
        inc si
        inc bx

        dec cl
        jmp .OutputName

    .End:
        pop dx
        mov es, dx

        pop dx
        pop cx

        ret



; Gets a files size and returns how big it is
; Input:
;   bx = pointer to entry in root directory
; Output:
;   ax = file size in KB
;   dx = remainder(in bytes)
GetFileSize:
    push cx
    push dx
    push es

    mov ax, RootDirMemLocation
    mov es, ax
    add bx, word 0x1c ; File size

    ; Gets and transforms the value in KB
    xor dx, dx
    mov ax, word [es:bx]
    mov cx, word 1024 ; Size in bytes of a KB
    div cx

    pop es
    pop dx
    pop cx
    ret



; Creates a new empty file
; Input:
;   si = pointer to file name
CreateFile:
    push es
    push ds
    push ds

    lea si, FileNameBuffer
        mov al, byte [AccentColour]
        call VgaPrintString

        cli
        hlt

    pop es ; Set es to ds
    mov bx, word KernelSeg
    mov ds, bx
    xor bx, bx

    ; Calculate lenght of file name
    .NameLenght:
        cmp bx, byte 11
        je .NameToBuffer

        mov al, byte [es:si + bx]

        ; If the name is shorter than 4 bytes throw an error
        test al, al
        jnz .Continue
        cmp bx, byte 4
        jb .Error

        .Continue:
            mov byte [FileNameBuffer + bx], al ; Move to buffer
            inc bx
            inc si

            jmp .NameLenght

    .NameToBuffer:
        lea si, FileNameBuffer
        mov al, byte [AccentColour]
        call VgaPrintString

        cli
        hlt

        call GetFirstEmptyEntry



    ; Now let's check for a free cluster in FAT
    ; TODO: Capire come scrivere nel FAT senza spaccarlo in due
    ; TODO: e anche come capire di quale cluster si sta parlando

    .Error:
        cli
        hlt

        ret



; Loads a file to the specified buffer
; Input:
;   di = pointer to entry in root dir
;   es:bx = offset to read to
LoadFile:
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, RootDirMemLocation
    mov es, ax
    add di, word 0x1a
    mov ax, word [es:di] ; Bytes 26-27 is the first cluster

    pop dx
    mov es, dx

    push es
    push ds
    mov dx, word KernelSeg
    mov ds, dx

    mov word [CurrentCluster], ax ; Save it
    mov word [FileOffset], bx

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
        ; Since the values for the clusters are 12 bits we need to read two bytes
        ; and kick off the other 4 bits. We do:
        ; CurrentCluster + (CurrentCluster / 2)
        mov ax, word [CurrentCluster]
        mov dx, ax
        mov bx, ax
        mov cl, byte 1
        shr bx, cl ; Shift a bit to the right, aka divide by 2
        add ax, bx

        ; Get the 12 bits
        push es
        mov bx, FATMemLocation
        mov es, bx

        mov bx, ax
        mov ax, word [es:bx]

        ; Would be smart to set ES back
        pop bx
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
            mov word [FileOffset], 0

            pop dx
            mov ds, dx
            pop dx
            mov es, dx

            pop dx
            pop cx
            pop bx
            pop ax
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

    xor ah, ah
    mov dl, byte [BootDisk]
    int 0x13

    pop ax
    ret


DiskError:
    mov al, 1
    call VgaNewLine
    mov si, DiskErrorMessage
    mov ah, 0xc ; Red
    call VgaPrintString

    ret



BootDisk: db 0
CurrentCluster: dw 0
FileOffset: dw 0
FirstEmptyEntry: dw 0
FirstEmptyCluster: dw 0
FileNameBuffer: times 11 db 0
FileNameBufferSize: db 0

ChsSector: db 0
ChsTrack: db 0
ChsHead: db 0

ReadAttempts: db 0
DiskErrorMessage: db "You idiot, you got a disk read/write error", 0