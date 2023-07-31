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

    ; Bottom text
    mov ah, byte 9
    mov bx, word 0x1700
    int 0x23

    xor ah, ah
    mov al, byte [NormalColour]
    lea si, BottomText
    int 0x23

    ; Set es to point to root directory
    mov ax, word [ds:2] ; Get the root directory memory location
    mov es, ax

    call ListFiles

    ; * Menu selection
    mov ah, byte 9
    mov bx, word 0x1808
    int 0x23
    mov bx, word 0x0304
    
    xor ch, ch
    ; cl is the number of files

    .SelectFile:
        WaitForKeyPress

        cmp al, byte "w"
        je .PreviousFile
        cmp al, byte "s"
        je .NextFile
        cmp al, byte 13 ; Enter key
        je .CheckFile
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


        .CheckFile:
        jmp .UnknownFile
            lea di, TextFileExtension
            ; cl already set
            call CheckFileExtension
            jc .Exec

            xor ch, ch
            mov ax, word 32
            mul cx

            lea si, TextEditorName
            mov bx, 2
            mov word [bx], ax
            int 0x25

            .Exec:
                lea di, ExecFileExtension
                call CheckFileExtension
                jc .UnknownFile

                ; Calculate offset of the file entry
                xor ch, ch
                mov ax, word 32
                mul cx
                mov si, ax

                push es
                pop ds
                int 0x25

            .UnknownFile:
                push bx
                mov ah, 9
                mov bx, word 0x1808
                int 0x23
                
                xor ah, ah
                mov al, byte [AccentColour]
                and al, 0xfc ; Red
                lea si, UnknownFileString
                int 0x23
                pop bx

                jmp .SelectFile

        .Esc:
            mov ah, byte 6
            int 0x23
            
            int 0x20


ListFiles:
    xor di, di
    xor cx, cx
    mov ch, byte [NormalColour]

    ; Move cursor
    mov bx, word 0x0304
    mov ah, 9
    int 0x23

    push ds
    push es
    pop ds

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


; Input:
;   cl = file number
;   di = pointer to extension to check
; Output:
;   carry flag = set for different extensions, clear if they're the same
CheckFileExtension:
    push bx
    push cx

    ; Calculate offset of the file entry
    xor ah, ah
    mov al, cl
    mov bx, word 32
    mul bx

    add ax, word 8 ; Select the file extension
    mov si, ax
    mov cx, word 3 ; We need to check 3 bytes

    .loop:
        or cl, cl
        jz .End

        mov al, byte [es:si]
        cmp al, byte [di]
        jne .DifferentExtensions

        inc si
        inc di
        dec cl
        loop .loop

    .DifferentExtensions:
        stc
        pop cx
        pop bx
        ret

    .End:
        clc
        pop cx
        pop bx
        ret


AppString: db "File manager v0.0.1  |  ", 0
DriveString: db "Boot drive", 0
FileNameSpacing: db "      ", 0
BottomText: db "Use W and S keys to select files. Enter to open a file.", 10, 13, "Status: ", 0
UnknownFileString: db "Wait for next release :)", 0

TextFileExtension: db "TXT"
ExecFileExtension: db "COM"
TextEditorName: db "TRASHVIMCOM", 0
FileCounter: db 0
NormalColour: db 0
AccentColour: db 0