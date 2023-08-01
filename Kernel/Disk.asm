[bits 16]
[cpu 8086]


; This file basically contains only the stuff needed for the kernel from Disk.asm in the bootloader.
; Some labels have been modified too, so it's not completely useless.


; Where int 0x22 brings us to
; Input:
;   ah = function to execute
DiskIntHandler:
    or ah, ah
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
        jne .RenameFile
        call GetFileSize
        jmp .Exit

    .RenameFile:
        cmp ah, byte 4
        jne .Exit
        call RenameFile

    .Exit:
        ; Tell the PIC we are done with interrupt
        mov al, 0x20
        out 0x20, al

        iret



; Scans the root directory for the first empty entry
; Output:
;   si = offset to entry
GetFirstEmptyEntry:
    push ax
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
        pop es
        pop ax

        ret



; As the name says, it finds the first unused cluster
; Output:
;   ax = first empty cluster
GetFirstFreeCluster:
    push bx
    push cx
    push dx

    push es
    mov bx, FATMemLocation
    mov es, bx

    .FindCluster:
        mov ax, word [FirstEmptyCluster]
        mov dx, ax
        mov bx, ax
        mov cl, byte 1
        shr bx, cl
        add bx, ax

        mov ax, word [es:bx] ; Get the 12 bits

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
        mov ax, word [FirstEmptyCluster]

        pop es
        pop dx
        pop cx
        pop bx
        ret



; Searches for an entry in the root dir with the given file name
; Input:
;   ds:si = pointer to file name
; Output:
;   carry flag = clear for success, set for error
;   si = pointer to entry in root dir
SearchFile:
    push ax
    push cx
    push dx
    push di

    push es
    mov ax, word RootDirMemLocation
    mov es, ax

    xor di, di
    mov cx, word RootDirEntries ; Counter
    mov dx, si

    .NextEntry:
        push di
        push cx

        mov si, dx ; File name
        mov cx, 11 ; How many bytes to compare
        repe cmpsb

        pop cx
        pop di ; Get the original value back(current entry start)
        je .Exit

        add di, word 32 ; Every entry is 32 bytes
        loop .NextEntry

        .Error:
            ; Nope. Nope.
            mov si, di
            pop es
            pop di
            pop dx
            pop cx
            pop ax
            stc

            ret

    .Exit:
        mov si, di
        pop es
        pop di
        pop dx
        pop cx
        pop ax
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
        or cl, cl
        jz .End

        mov al, byte [es:bx]
        mov byte [ds:si], al
        inc si
        inc bx

        dec cl
        jmp .OutputName

    .End:
        pop es
        pop dx
        pop cx

        ret


; Renames a file with the given string. Changes extension!
; Input:
;   ds:si = pointer to file to rename
;   es:di = pointer to new file name
; Output:
;   carry flag = set for invalid file name, clear for success
RenameFile:
    push ax
    push cx
    push si
    push di

    xchg si, di
    call StringLenght

    cmp cl, byte 11
    jne .InvalidFileName
    xchg si, di
    xor ch, ch ; It's better to clean ch

    .loop:
        mov al, byte [es:di]
        mov byte [si], al

        inc si
        inc di
        loop .loop

        clc
        jmp .Exit

    .InvalidFileName:
        xchg si, di
        stc

    .Exit:
        pop di
        pop si
        pop cx
        pop ax
        ret


; Gets a files size and returns how big it is
; Input:
;   bx = pointer to entry in root directory
; Output:
;   ax = file size in KB
;   dx = remainder(in bytes)
GetFileSize:
    push bx
    push cx
    push es

    mov ax, word RootDirMemLocation
    mov es, ax
    add bx, word 0x1c ; File size

    ; Gets and transforms the value in KB
    xor dx, dx
    mov ax, word [es:bx]
    mov cx, word 1024 ; Size in bytes of a KB
    div cx

    pop es
    pop cx
    pop bx
    ret



; Creates a new empty file
; Input:
;   ds:dx = pointer to File Control Block(FCB)
CreateFile:
    push es
    push ds

    mov ax, word RootDirMemLocation
    mov es, ax
    
    call GetFirstEmptyEntry

    ; Copy file name into entry
    xchg si, di
    mov si, dx
    inc si ; Point to file name
    mov cx, word 11
    rep movsb

    call GetFirstFreeCluster
    push ax ; Save first free cluster
    push dx ; Save FCB pointer

    mov si, dx
    mov ax, word [si + 0x10] ; File size
    mov dx, word [si + 0x12] ; File size
    mov bx, BytesPerSector
    div bx

    or dx, dx ; If remainder isn't 0 we need to count another sector
    jz .NoExtraSector
    inc ax

    .NoExtraSector:
        pop dx
        pop ax

        ; call WriteFat
        call WriteRootDir

        pop ds
        pop es
        ret





; Loads a file to the specified buffer
; Input:
;   si = pointer to entry in root dir
;   es:bx = offset to read to
LoadFile:
    push ax
    push bx
    push cx
    push dx
    push es

    mov ax, RootDirMemLocation
    mov es, ax
    add si, word 0x1a
    mov ax, word [es:si] ; Bytes 26-27 is the first cluster

    pop es
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
        add bx, ax

        ; Get the 12 bits
        push es
        mov cx, word FATMemLocation
        mov es, cx
        mov ax, word [es:bx]
        pop es ; Would be smart to set ES back

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
            cmp ax, word 0xff8 ; 0xff8 - 0xfff represent the last cluster
            jae .FileLoaded

            mov word [CurrentCluster], ax ; Save the new cluster
            add word [FileOffset], 512 ; Next sector
            jmp .LoadCluster


        .FileLoaded:
            mov word [FileOffset], 0

            pop ds
            pop es
            pop dx
            pop cx
            pop bx
            pop ax
            ret





;* --//  Other functions  \\--


; Reads the disk into the specified buffer in memory
; Input:
;   es:bx = data buffer
;   al = sectors to read
ReadDisk:
    mov ah, byte 2 ; Read please
    jmp DiskSectorRoutine

; Writes the given buffer to the disk
; Code is basically the same as ReadDisk
; Input:
;   al = number of sectors to write
;   es:bx = data buffer
WriteDisk:
    mov ah, byte 3

DiskSectorRoutine:
    call ResetDisk

    ; Buffer to read to(ES:BX) is already set
    ; Sectors to read are already set
    mov dl, byte [CurrentDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, byte [ChsTrack] ; C (cylinder)
    mov dh, byte [ChsHead] ; H (head)
    mov cl, byte [ChsSector] ; S (sector). Starts from 1, not 0. Why?

    stc
    int 0x13
    jc .Check ; Carry flag set

    mov byte [ReadAttempts], byte 0
    ret
    
    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add byte [ReadAttempts], byte 1 ; If I use inc I get an error
        cmp byte [ReadAttempts], byte 3
        jge DiskError

        jmp DiskSectorRoutine


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
    mov cx, word DiskHeads
    div cx

    mov byte [ChsTrack], al
    mov byte [ChsHead], dl

    ; Sectors
    pop ax
    xor dx, dx
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
    mov dl, byte [CurrentDisk]
    int 0x13

    pop ax
    ret


DiskError:
    mov al, 1
    call VgaPrintNewLine
    lea si, DiskErrorMessage
    mov al, 0xc ; Red
    call VgaPrintString

    ret



CurrentDisk: db 0
CurrentCluster: dw 0
FileOffset: dw 0
FirstEmptyEntry: dw 0
FirstEmptyCluster: dw 3 ; First data cluster
FileNameBuffer: times 11 db 0
FileNameBufferSize: db 0

; WriteFile variables
SectorCount: dw 0
SectorsUsedByFile: dw 0
ClustersToWrite: times 128 dw 0

ChsSector: db 0
ChsTrack: db 0
ChsHead: db 0

ReadAttempts: db 0
DiskErrorMessage: db "Disk read/write error, idiot", 0