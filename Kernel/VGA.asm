[bits 16]
[cpu 286]


; *I need to create a VGA driver because I will implement something cool for 0.1.5 :)
; *I can't use int 0x10 for this



; Start of vga buffer in memory
VgaBuffer equ 0xb8000
; Vga buffer size in bytes
VgaBufferSize equ 4000

VgaRows equ 25
VgaColumns equ 80

DefaultColor equ 49 ; Foreground and background color
DefaultCursorPos equ 0



; Prints a string to the screen by writing manually to the vga buffer
; Input:
;   si = pointer to string
;   bx = attribute(foreground and background color)
VgaPrintString:
    push ax
    
    .Loop:
        lodsb ; Loads the next byte into al

        cmp al, byte 0
        je .Exit

        ; Attribute byte
        mov ah, DefaultColor

        ; Moves the character and attribute into the vga buffer
        mov ax, [VgaBuffer]

        cmp al, byte 0xd ; Carriage return
        je .CarriageReturn

        cmp al, byte 0xa ; New line
        je .NewLine

        ; Then it's a normal character
        inc [CursorPos]


        .CarriageReturn:
            mov ax, byte [CursorPos]
            div VgaRows

            add [CursorPos], dx
            jmp .MoveCursor

        .NewLine:
            mov ax, byte [CursorPos]
            div VgaRows

            add [CursorPos], VgaRows
            add [CursorPos], dx


        .MoveCursor:
            mov ah, 0x2
            mov bh, 0 ; Page
            mov dh, [CurrentRow] ; Row
            mov dl, [CurrentColumn] ; Column

            int 0x10

        jmp .Loop


    .Exit:
        pop ax

        ret




CursorPos: db DefaultCursorPos
CurrentRow: db 0
CurrentColumn: db 0