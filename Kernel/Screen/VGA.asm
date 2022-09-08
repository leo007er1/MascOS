[bits 16]
[cpu 286]


; *I need to create a VGA driver because I want colors, beautiful colors, aaahhh
; *I can't use int 0x10 for this
; https://en.wikipedia.org/wiki/BIOS_color_attributes
; GS will be our "base" from where to add the offset



; Start of vga buffer in memory
VgaBuffer equ 0xb800 ; Will be moved to gs

VgaRows equ 25
VgaColumns equ 80
VgaDefaultColor equ 0xf ; White foreground, black background

CurrentColor: db VgaDefaultColor
CursorPos: dw 0
CurrentRow: db 0
CurrentColumn: db 0




; Prints a string to the screen by writing manually to the vga buffer
; Input:
;   si = pointer to string
;   ah = attribute(foreground and background color), clear to use default color
VgaPrintString:
    push bx
    push ax

    ; If 0 we just use the default color
    cmp ah, 0
    je .PrintLoop

    ; Save the color
    mov byte [CurrentColor], ah

    .PrintLoop:
        lodsb ; Loads next character into al

        cmp al, byte 0
        je .Exit

        cmp al, byte 10 ; New line
        je .NewLine

        cmp al, byte 13
        je .CarriageReturn


        mov bx, VgaBuffer
        mov gs, bx

        ; The first byte is the character, the second the attribute byte
        mov bx, [CursorPos]
        mov byte [gs:bx], al

        inc bx ; Next byte
        mov cl, [CurrentColor]
        mov byte [gs:bx], cl

        add word [CursorPos], 2
        inc byte [CurrentColumn]

        jmp .Skip

        .NewLine:
            ; CursorPos = CurrentRow * VgaColumns + CurrentColumn
            add byte [CurrentRow], 2
            mov byte [CurrentColumn], 0

            xor dx, dx
            mov ax, [CurrentRow]
            mov cx, 80
            mul cx

            mov bx, [CurrentColumn]
            add ax, bx

            mov word [CursorPos], ax

            jmp .Skip


        .CarriageReturn:
            ; CursorPos -= CurrentColumn
            mov bx, [CurrentColumn]
            mov ax, [CursorPos]
            sub ax, bx

            mov word [CursorPos], ax
            mov byte [CurrentColumn], 0

        .Skip:
            jmp .PrintLoop


    .Exit:
        pop ax
        pop bx

        ; The "real" current row: CurrentRow /= 2
        xor dx, dx
        mov al, [CurrentRow]
        mov bx, 2
        div bx
        sub byte [CurrentRow], al

        push ax

        ; Sets the cursor
        mov ah, 0x2
        mov bh, 0 ; Page
        mov dh, [CurrentRow] ; Row
        mov dl, [CurrentColumn] ; Column
        int 0x10

        pop ax
        add byte [CurrentRow], al ; Sets the previous value back

        ; Restore the default color
        mov byte [CurrentColor], VgaDefaultColor

        ret


; "Prints" a new line
VgaNewLine:
    push cx

    ; Same formulas as VgaPrintString
    add byte [CurrentRow], 2

    xor dx, dx
    mov ax, [CurrentRow]
    mov cx, 80
    mul cx

    mov bx, [CurrentColumn]
    add ax, bx

    mov word [CursorPos], ax
    mov byte [CurrentColumn], 0

    ; The "real" current row: CurrentRow /= 2
    xor dx, dx
    mov al, [CurrentRow]
    mov bx, 2
    div bx
    sub byte [CurrentRow], al

    push ax

    ; Sets the cursor
    mov ah, 0x2
    mov bh, 0 ; Page
    mov dh, [CurrentRow] ; Row
    mov dl, [CurrentColumn] ; Column
    int 0x10

    pop ax
    add byte [CurrentRow], al ; Sets the previous value back

    pop cx

    ret



; Clears the screen and resets values
VgaClearScreen:
    ; Clears the screen
    mov ah, 0x0
    mov al, 0x3
    int 0x10

    mov word [CursorPos], 0
    mov byte [CurrentColumn], 0
    mov byte [CurrentRow], 0

    ret