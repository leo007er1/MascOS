[bits 16]
[org 0x100]
[cpu 8086]


; * This is a simple file manager made for MascOS



; Just waits till a key is pressed
;
; Output:
;   al = character
;   ah = BIOS scan code
%macro WaitForKeyPress 0
    push bx
    push cx

    xor ax, ax
    int 0x16

    pop cx
    pop bx
%endmacro



Start:
    ; Get colours
    mov ah, byte 8
    int 0x23
    mov word [NormalColour], bx ; Sets AccentColour too

    ; Clear screen
    mov ah, byte 6
    int 0x23

    xor ah, ah
    lea si, AppString
    mov al, bl
    int 0x23

    xor ah, ah
    mov al, bh
    lea si, DriveString
    int 0x23

    call ListFiles

    ; * Menu selection
    mov ah, byte 9
    mov bx, word 0x0304
    int 0x23
    
    xor ch, ch
    ; cl is the number of files

    .SelectFile:
        WaitForKeyPress

        cmp al, byte "w"
        je .PreviousFile
        cmp al, byte "s"
        je .NextFile
        cmp al, byte 27
        je .Esc

        jmp .SelectFile

        .PreviousFile:
            or ch, ch
            jz .SelectFile

            dec ch
            push cx
            mov ah, byte 5
            mov cx, word 11
            mov al, byte [NormalColour]
            int 0x23

            dec bh ; Line above
            mov al, byte [AccentColour]
            int 0x23
            pop cx

            jmp .SelectFile

        .NextFile:
            cmp ch, cl
            jge .SelectFile

            inc ch
            push cx
            mov ah, byte 5
            mov cx, word 11
            mov al, byte [NormalColour]
            int 0x23

            inc bh ; Lines below
            mov al, byte [AccentColour]
            int 0x23
            pop cx

            jmp .SelectFile

        .Esc:
            mov ah, byte 6
            int 0x23
            
            int 0x20


ListFiles:
    push ds
    xor di, di
    xor cx, cx
    mov ch, byte [NormalColour]

    mov bx, word 0x0304
    mov ah, 9
    int 0x23

    mov ax, word [ds:2] ; Get the root directory memory location
    mov ds, ax

    .CheckForFile:
        cmp byte [di], 0
        je .End

        ; Print file name
        xor ah, ah
        mov al, ch
        mov si, di
        int 0x23

        ; Next line
        inc bh
        mov ah, byte 9
        int 0x23

        add di, 32 ; Size of an entry
        inc cl
        jmp .CheckForFile

    .End:
        mov byte [FileCounter], cl
        pop ds
        ret


AppString: db "File manager v0.0.1  |  ", 0
DriveString: db "Boot drive", 0
FileNameSpacing: db "      ", 0
FileCounter: db 0
NormalColour: db 0
AccentColour: db 0