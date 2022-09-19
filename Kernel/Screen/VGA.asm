[bits 16]
[cpu 286]


; *I need to create a VGA driver because I want colours, beautiful colours, aaahhh
; *I can't use int 0x10 for this
; https://en.wikipedia.org/wiki/BIOS_color_attributes
; GS will be our "base" from where to add the offset



; Start of vga buffer in memory
VgaBuffer equ 0xb800 ; Will be moved to gs

VgaRows equ 25
VgaColumns equ 80
VgaDefaultColour equ 0xf ; White foreground, black background

CurrentColour: db VgaDefaultColour
CurrentRow: db 0
CurrentColumn: db 0
CursorPos: dw 0




; Prints a single character to the screen
; Input:
;   %1 = character to print
;   %2 = attribute byte, set to 0 to use default colour
%macro VgaPrintChar 2
    push bx

    mov bl, %2
    cmp bl, byte 0
    je %%Print

    mov byte [CurrentColour], %2

    %%Print:
        mov bx, VgaBuffer
        mov gs, bx

        ; Moves character
        mov bx, word [CursorPos]
        mov byte [gs:bx], %1

        ; Moves attribute byte
        inc bx
        mov ah, byte [CurrentColour]
        mov byte [gs:bx], ah

        add word [CursorPos], 2
        inc byte [CurrentColumn]


    VgaSetCursor

    pop bx

    mov byte [CurrentColour], VgaDefaultColour

%endmacro


; Input:
;   %1 = number of new lines
%macro VgaPrintNewLine 1
    ; CursorPos += %1 * 160 - (CursorPos % VgaColumns)
    add byte [CurrentRow], %1
    mov byte [CurrentColumn], %1 ; We temporanely store this value here, since I can't directly move it to a register

    ; Checks if we need to scroll
    cmp byte [CurrentRow], 25
    jl %%AddNewLine

    sub byte [CurrentRow], %1
    mov al, %1
    call VgaScroll

    %%AddNewLine:
        xor dx, dx
        mov ax, word [CursorPos]
        mov bx, VgaColumns
        div bx

        sub word [CursorPos], dx

        mov al, byte [CurrentColumn]
        mov bx, 160
        mul bx

        add word [CursorPos], ax
        mov byte [CurrentColumn], 0

%endmacro


%macro VgaCarriageReturn 0
    ; CursorPos -= CurrentColumn * 2
    push ax

    ; Yes, I'm too lazy to multiply CurrentColumn by 2
    mov bl, byte [CurrentColumn]
    mov bh, 0
    mov ax, word [CursorPos]
    sub ax, bx
    sub ax, bx

    mov word [CursorPos], ax
    mov byte [CurrentColumn], 0

    pop ax

%endmacro


%macro VgaSetCursor 0
    push ax
    push bx
    push dx

    ; Sets the cursor
    mov ah, 0x2
    mov bh, 0 ; Page
    mov dh, byte [CurrentRow] ; Row
    mov dl, byte [CurrentColumn] ; Column
    int 0x10

    pop dx
    pop bx
    pop ax

%endmacro




VgaInit:
    ; *NOTE: this won't do anything on new hardware that emulates VGA, only on real VGA hardware
    ; Disable blink bit so we can use all 16 colours instead of 8
    ; Reset index or data flip-flop. We don't known it's initial state
    mov dx, 0x03da
    in al, dx

    ; Now 0x3c0 is in index state, so we select the "Attribute mode control register" that contains
    ; the "Palette address source"
    mov dx, 0x03c0
    mov al, 0x30
    out dx, al

    ; Get value from "Attribute mode control register" in 0x3c1
    mov dx, 0x03c1
    in al, dx

    ; Sets bit 3, which is the blink enable bit
    ; To enable it use 0x08
    and al, 0xf7

    ; Updates that freaking register with new value
    mov dx, 0x03c0
    out dx, al

    ; Woah, that was a lot for disabling text blinking

    ret



; Prints a string to the screen by writing manually to the vga buffer
; Input:
;   si = pointer to string
;   ah = attribute(foreground and background colour), clear to use default colour
VgaPrintString:
    push bx
    push ax

    ; If 0 we just use the default colour
    cmp ah, 0
    je .PrintLoop

    mov byte [CurrentColour], ah

    .PrintLoop:
        lodsb ; Loads next character into al

        cmp al, byte 0
        je .Exit

        cmp al, byte 10
        je .NewLine

        cmp al, byte 13
        je .CarriageReturn

        mov bx, VgaBuffer
        mov gs, bx

        ; The first byte is the character, the second the attribute byte
        mov bx, word [CursorPos]
        mov byte [gs:bx], al

        inc bx ; Next byte
        mov cl, byte [CurrentColour]
        mov byte [gs:bx], cl

        add word [CursorPos], 2
        inc byte [CurrentColumn]

        ; No buffer overflow, pls (asks with a cute face)
        cmp word [CursorPos], 4000
        jle .Skip

        mov al, 1
        call VgaScroll
        jmp .Skip

        .NewLine:
            VgaPrintNewLine 1
            VgaSetCursor

            jmp .Skip


        .CarriageReturn:
            VgaCarriageReturn

        .Skip:
            jmp .PrintLoop


    .Exit:
        pop ax
        pop bx

        VgaSetCursor

        ; Restore the default colour
        mov byte [CurrentColour], VgaDefaultColour

        ret


; "Prints" a new line
; Input:
;   al = number of new lines
VgaNewLine:
    push cx

    VgaCarriageReturn
    VgaPrintNewLine al
    VgaSetCursor

    pop cx

    ret


; Paints the foreground and background of a line with the given colour
; Input:
;   al = colour
VgaPaintLine:
    ; Can't do something like: push word [CursorPos]
    mov bx, word [CursorPos]
    push bx
    mov bl, [CurrentColumn]
    xor bh, bh
    push bx

    VgaCarriageReturn
    mov cx, VgaColumns ; Counter
    add word [CursorPos], 1 ; We select the attribute byte, since after we add 2 to CursorPos it will skip the character byte

    .Loop:
        cmp cx, 0
        je .Exit

        mov bx, VgaBuffer
        mov gs, bx

        mov bx, word [CursorPos]
        mov byte [gs:bx], al

        add word [CursorPos], 2

        dec cx
        jmp .Loop

    .Exit:
        pop bx
        mov byte [CurrentColumn], bl
        pop bx
        mov word [CursorPos], bx

        ret



; Scrolls a line down
VgaScroll:
    ; *Idea:
    ; * I can just move every line up a single row, so copy row 160 bytes before it.
    ; * The first row will just GET THROWN IN THE TRASH
    ; ? In the future I might make this myself, I don't like using the BIOS

    ; Counter - 1 cause first row nono
    ; mov cx, VgaRows
    ; dec cx

    ; VgaCarriageReturn ; Get to the start of the row

    ; ; Sets segments
    ; push VgaBuffer
    ; push VgaBuffer
    ; pop ds
    ; pop es

    ; mov ax, word [CursorPos]
    ; mov bx, 160


    ; .Loop:
    ;     movsb


    ;     jmp .Loop

    push ax
    push bx
    push cx
    push dx
    push ax

    mov ah, 0x6
    ; Al is the number of lines to scroll
    mov bh, 0 ; Attribute byte
    ; Upper left corner
    mov ch, 0
    mov cl, 0
    ; Bottom right corner
    mov dh, VgaRows
    mov dl, VgaColumns

    int 0x10

    ; Update values
    mov ax, word 160
    pop bx ; Number of lines to scrool
    xor bh, bh ; For safety
    mul bx

    sub word [CursorPos], ax
    sub byte [CurrentRow], bl

    .Finished:
        pop dx
        pop cx
        pop bx
        pop ax

        VgaSetCursor

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