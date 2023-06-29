[bits 16]
[cpu 8086]


DosInt21:
    cmp ah, byte 0x1
    je ah1
    cmp ah, byte 0x2
    je ah2
    cmp ah, byte 0x3
    je ah3
    cmp ah, byte 0x4
    je ah4
    ; cmp ah, byte 0x5
    ; je ah5
    cmp ah, byte 0x6
    je ah6
    cmp ah, byte 0x7
    je ah7
    cmp ah, byte 0x8
    je ah7
    cmp ah, byte 0x9
    je ah9
    cmp ah, byte 0xa
    je ah0a
    ; cmp ah, byte 0xb
    ; je ah0b
    ; cmp ah, byte 0xc
    ; je ah0c
    cmp ah, byte 0x19
    je ah19
    cmp ah, byte 0x2a
    je ah2a
    cmp ah, byte 0x2c
    je ah2c
    cmp ah, byte 0x4c
    je ah4c

    jmp ReturnFromInt



; Read char from standard input with echo
ah1:
    push cx

    push ds
    mov ax, word KernelSeg
    mov ds, ax
    mov cl, byte [NormalColour]
    pop ds

    xor ax, ax
    int 0x16

    call VgaPrintChar

    pop cx
    jmp ReturnFromInt


; Write char to standard output
ah2:
    push cx

    push ds
    mov cx, word KernelSeg
    mov ds, cx
    mov cl, byte [NormalColour]
    pop ds

    xchg al, dl
    call VgaPrintChar

    pop cx
    jmp ReturnFromInt


; Read char from serial port
ah3:
    call SerialRead

    jmp ReturnFromInt


; Write char to serial port
ah4:
    push ax

    xchg al, dl
    call SerialWrite

    pop ax
    jmp ReturnFromInt


; Direct console output
ah6:
    cmp dl, byte 0xff
    jne ah2

    jmp ah7

    jmp ReturnFromInt


; Read char form standard input without echo
ah7:
    xor ax, ax
    int 0x16

    jmp ReturnFromInt


; Write string to standard output
ah9:
    push ax
    push si

    push ds
    mov ax, word KernelSeg
    mov ds, ax
    mov al, byte [NormalColour]
    pop ds

    xchg dx, si
    call VgaPrintString

    pop si
    pop ax
    jmp ReturnFromInt


; Buffered input from standard input
ah0a:
    ; ds:dx is the buffer
    ; First byte is buffer size, second byte is the number of chars readed
    push ax
    push bx
    push cx
    push si

    push ds
    mov ax, word KernelSeg
    mov ds, ax
    mov cl, byte [NormalColour]
    pop ds

    mov si, dx
    mov bh, byte [ds:si] ; Buffer size
    xor bl, bl

    .NextChar:
        cmp bl, bh
        je .CarriageReturn

        xor ax, ax
        int 0x16

        cmp al, byte 13
        je .CarriageReturn

        call VgaPrintChar
        mov byte [ds:si], al ; Move char to buffer
        inc bl
        inc si

        jmp .NextChar
    
    .CarriageReturn:
        mov byte [ds:si + 1], bl ; Number of chars readed

        pop si
        pop cx
        pop bx
        pop ax

        jmp ReturnFromInt


; Get current default drive
ah19:
    push bx

    push ds
    mov bx, word KernelSeg
    mov ds, bx
    mov al, byte [BootDisk]
    pop ds

    pop bx

    jmp ReturnFromInt


; Get system date
ah2a:
    push bx

    call CmosGetSystemDate
    mov cx, bx ; Year
    mov dh, ah ; Month
    mov dl, al ; Day
    mov al, dl - 1 ; Day of week

    pop bx
    jmp ReturnFromInt


; Get system time
ah2c:
    push ax

    call CmosGetSystemTime
    mov ch, ah ; Hours
    mov cl, al ; Minutes
    xor dl, dl ; ????

    pop ax
    jmp ReturnFromInt


; Exit program
ah4c:
    jmp ProgramEndPoint


ReturnFromInt:
    ; Tell the PIC we are done with interrupt
    ; No idea why but let's do it
    mov al, 0x20
    out 0x20, al

    iret