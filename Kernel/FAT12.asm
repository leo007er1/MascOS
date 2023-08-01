[bits 16]
[cpu 8086]




LoadFat:
    ; FATs are just after the reserved sectors, so...
    mov ax, word ReservedSectors
    call LbaToChs

    push es
    mov ax, FATMemLocation
    mov es, ax
    xor bx, bx ; Offset
    mov al, byte SectorsPerFAT ; Sectors to read
    call ReadDisk

    pop es
    ret


LoadRootDir:
    ; Get CHS info
    mov ax, word RootDirStartPoint
    call LbaToChs

    push es
    mov bx, RootDirMemLocation
    xor bx, bx ; Offset
    mov al, byte RootDirSize ; Sectors to read
    call ReadDisk

    pop es
    ret


WriteFat:
    ; FATs are just after the reserved sectors, so...
    mov ax, word ReservedSectors
    call LbaToChs

    push es
    mov ax, FATMemLocation
    mov es, ax
    xor bx, bx ; Offset
    mov al, byte SectorsPerFAT ; Sectors to write
    call WriteDisk

    pop es
    ret


WriteRootDir:
    ; Get CHS info
    mov ax, word RootDirStartPoint
    call LbaToChs

    push es
    mov bx, RootDirMemLocation
    xor bx, bx ; Offset
    mov al, byte RootDirSize ; Sectors to write
    call WriteDisk

    pop es
    ret