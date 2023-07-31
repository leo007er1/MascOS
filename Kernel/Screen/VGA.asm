[bits 16]
[cpu 8086]


; *I need to create a VGA driver because I want colours, beautiful colours, aaahhh
; *I can't use int 0x10 for this
; https://en.wikipedia.org/wiki/BIOS_color_attributes
; ES will be our "base" from where to add the offset



; Start of vga buffer in memory
VgaBuffer equ 0xb800 ; Will be moved to es

VgaRows equ 25
VgaColumns equ 80
VgaDefaultColour equ 0x0f ; White foreground, black background

NormalColour: db VgaDefaultColour
AccentColour: db 0x0a
CurrentRow: db 0
CurrentColumn: db 0
CursorPos: dw 0




; Prints a single character to the screen
; Input:
;   %1 = character to print
;   %2 = attribute byte, set to 0 to use default colour
%macro VgaPrintCharMacro 2
    push bx
    push es
    push ds

    mov bx, word KernelSeg
    mov ds, bx
    
    mov cl, byte [NormalColour]
    mov byte [NormalColour], %2

    %%Print:
        mov bx, word VgaBuffer
        mov es, bx

        ; Moves both character and attribute byte
        mov bx, word [CursorPos]
        mov ah, byte [NormalColour]
        mov al, byte %1
        mov word [es:bx], ax

        add word [CursorPos], 2
        inc byte [CurrentColumn]


    mov byte [NormalColour], cl

    pop ds
    pop es
    pop bx
%endmacro


; Input:
;   %1 = number of new lines
%macro VgaPrintNewLine 1
    push ax
    push bx
    push dx

    ; CursorPos += %1 * 160 - (CursorPos % VgaColumns)
    add byte [CurrentRow], %1
    mov byte [CurrentColumn], %1 ; We temporanely store this value here, since I can't directly move it to a register

    ; Checks if we need to scroll
    cmp byte [CurrentRow], 25
    jl %%AddNewLine

    mov al, %1
    call VgaScroll

    %%AddNewLine:
        xor dx, dx
        mov ax, word [CursorPos]
        mov bx, VgaColumns
        div bx

        sub word [CursorPos], dx

        mov al, byte [CurrentColumn]
        mov bx, word 160
        mul bx

        add word [CursorPos], ax
        mov byte [CurrentColumn], 0


    pop dx
    pop bx
    pop ax

%endmacro


%macro VgaCarriageReturn 0
    ; CursorPos -= CurrentColumn * 2
    push ax
    push bx
    push dx
    push ds

    mov bx, word KernelSeg
    mov ds, bx

    ; Yes, I'm too lazy to multiply CurrentColumn by 2
    mov bl, byte [CurrentColumn]
    xor bh, bh
    mov ax, word [CursorPos]
    sub ax, bx
    sub ax, bx

    mov word [CursorPos], ax
    mov byte [CurrentColumn], 0

    pop ds
    pop dx
    pop bx
    pop ax
%endmacro


%macro VgaSetCursor 0
    push ax
    push bx
    push dx

    ; Divide CursorPos by 2(CursorPos is incremented by 2 because we count the attribute byte too)
    xor dx, dx
    mov ax, word [CursorPos]
    mov bx, word 2
    div bx
    xchg ax, bx

    mov dx, 0x3d4 ; I/O port
    mov al, byte 0xf
    out dx, al

    inc dl
    mov al, bl
    out dx, al

    dec dl
    mov al, byte 0xe
    out dx, al

    inc dl
    mov al, bh
    out dx, al

    pop dx
    pop bx
    pop ax
%endmacro




VgaInit:
    ; *NOTE: this won't do anything on new hardware that emulates VGA, only on real VGA hardware
    ; Disable blink bit so we can use all 16 colours instead of 8
    ; Reset index or data flip-flop. We don't known it's initial state
    mov dx, word 0x03da
    in al, dx

    ; Now 0x3c0 is in index state, so we select the "Attribute mode control register" that contains
    ; the "Palette address source"
    mov dx, word 0x03c0
    mov al, 0x30
    out dx, al

    ; Get value from "Attribute mode control register" in 0x3c1
    mov dx, word 0x03c1
    in al, dx

    ; Sets bit 3, which is the blink enable bit
    ; To enable it use 0x08
    and al, 0xf7

    ; Updates that freaking register with new value
    dec dl
    out dx, al

    ret


; Checks for the correct label to execute
; Input:
;   ah = function to run
VgaIntHandler:
    ; *I do have an idea to use just use a loop,
    ; *but this will work for now.

    cmp ah, byte 0
    jne .NoPrintString
    call VgaPrintString
    jmp .Exit

    .NoPrintString:
        cmp ah, byte 1
        jne .NoPrintChar
        call VgaPrintChar
        jmp .Exit

    .NoPrintChar:
        cmp ah, byte 2
        jne .NoNewLine
        call VgaNewLine
        jmp .Exit

    .NoNewLine:
        cmp ah, byte 3
        jne .NoGotoLine
        call VgaGotoLine
        jmp .Exit

    .NoGotoLine:
        cmp ah, byte 4
        jne .NoClearLine
        call VgaClearLine
        jmp .Exit

    .NoClearLine:
        cmp ah, byte 5
        jne .NoPaint
        call VgaPaint
        jmp .Exit

    .NoPaint:
        cmp ah, byte 6
        jne .NoClearScreen
        call VgaClearScreen
        jmp .Exit

    .NoClearScreen:
        cmp ah, byte 7
        jne .NoBackspace
        call VgaBackspace
        jmp .Exit

    .NoBackspace:
        cmp ah, byte 8
        jne .NoGetColours
        call VgaGetColours
        jmp .Exit

    .NoGetColours:
        cmp ah, byte 9
        jne .Exit
        call VgaGotoPos

    .Exit:
        ; Tell the PIC we are done with interrupt
        mov al, 0x20
        out 0x20, al

        iret



; Prints a string to the screen by writing manually to the vga buffer
; Input:
;   si = pointer to string
;   al = attribute(foreground and background colour)
VgaPrintString:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Setup process
    push es
    push ds

    mov bx, VgaBuffer
    mov es, bx
    mov bx, word KernelSeg
    mov ds, bx

    ; Get the required values
    mov bx, word [CursorPos]
    mov dl, byte [CurrentColumn]
    mov dh, al

    pop ds
    mov ah, dh ; Ah will stay as it is now

    .PrintLoop:
        lodsb ; Loads next character into al

        or al, al
        jz .Exit

        ; MS DOS terminates strings with a dollar sign....
        ; cmp al, byte "$"
        ; je .Exit

        cmp al, byte 10
        je .NewLine

        cmp al, byte 13
        je .CarriageReturn

        ; The first byte is the character, the second the attribute byte
        mov word [es:bx], ax ; Move character and attribute byte

        add bx, 2 ; CursorPos += 2
        inc dl ; CurrentColumn++

        ; No buffer overflow, pls (asks with a cute face)
        cmp bx, word 4000
        jle .PrintLoop

        mov al, 1
        call VgaScroll
        jmp .PrintLoop

        .NewLine:
            push ds
            mov cx, word KernelSeg
            mov ds, cx

            VgaPrintNewLine 1
            mov bx, word [CursorPos] ; Get new CursorPos

            pop ds
            xor dl, dl ; CurrentColumn = 0
            jmp .PrintLoop


        .CarriageReturn:
            VgaCarriageReturn
            xor dl, dl ; CurrentColumn = 0

            jmp .PrintLoop


    .Exit:
        mov ax, word KernelSeg
        mov es, ax
        mov word [es:CursorPos], bx
        mov byte [es:CurrentColumn], dl

        pop es
        pop si
        pop dx
        pop cx
        pop bx
        pop ax

        VgaSetCursor

        ret



; Prints a single character using VgaPrintCharMacro(don't wanna use macro directly)
; Input:
;   al = character
;   cl = colour
VgaPrintChar:
    VgaPrintCharMacro al, cl
    VgaSetCursor

    ret




; "Prints" a new line
; Input:
;   al = number of new lines
VgaNewLine:
    push bx
    push cx
    push ds

    mov bx, word KernelSeg
    mov ds, bx

    VgaCarriageReturn
    VgaPrintNewLine al
    VgaSetCursor

    pop ds
    pop cx
    pop bx

    ret


; Goes to a specified line
; Input:
;   al = line
VgaGotoLine:
    push ds

    mov bx, word KernelSeg
    mov ds, bx

    VgaCarriageReturn

    mov byte [CurrentRow], al
    xor ah, ah
    xor dx, dx
    mov cx, 160
    mul cx

    mov word [CursorPos], ax
    VgaSetCursor

    pop ds
    ret


; Goes to a specified coordinate
; Input:
;   bl = x position(max 80)
;   bh = y position(max 24)
VgaGotoPos:
    push ax
    push bx
    push cx
    push ds

    mov ax, word KernelSeg
    mov ds, ax

    mov byte [CurrentColumn], bl
    mov byte [CurrentRow], bh

    ; (bh * VgaColumns + bl) * 2
    xor ax, ax
    xchg al, bh
    mov dx, VgaColumns
    mul dx
    add ax, bx
    mov cl, 1
    shl ax, cl

    mov word [CursorPos], ax
    VgaSetCursor

    pop ds
    pop cx
    pop bx
    pop ax
    ret


; Paints the foreground and background of a line with the given colour
; Input:
;   cx = number of columns to change colour of
;   bl = x position(max 80)
;   bh = y position(max 24)
;   al = attribute byte
VgaPaint:
    push ax
    push bx
    push cx
    push dx
    push ds
    push es
    mov dx, word KernelSeg
    mov ds, dx
    mov dx, VgaBuffer
    mov es, dx

    ; Can't do something like: push word [CursorPos]
    mov dx, word [CursorPos]
    push dx
    mov dx, word [CurrentRow] ; Moves CurrentColumn too because together they are 2 bytes, we move a word both of them
    push dx

    mov byte [CurrentColumn], bl
    mov byte [CurrentRow], bh

    push ax
    push cx
    ; (bh * VgaColumns + bl) * 2
    xor ax, ax
    xchg al, bh
    mov dx, VgaColumns
    mul dx
    add ax, bx
    mov cl, 1
    shl ax, cl

    inc ax ; Select first attribute byte
    pop cx
    pop bx
    xchg ax, bx
    
    .Loop:
        mov byte [es:bx], al
        add bx, 2

        loop .Loop
    
    .Exit:
        pop dx
        mov word [CurrentRow], dx ; Sets CurrentColumn too
        pop dx
        mov word [CursorPos], dx

        pop es
        pop ds
        pop dx
        pop cx
        pop bx
        pop ax
        ret


; Scrolls a line down
; Input:
;   al = number of lines to scrool
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

    push bx
    push cx
    push dx
    push ds
    push ax

    mov cx, word KernelSeg
    mov ds, cx

    mov ah, 6
    ; Al is the number of lines to scroll
    mov bh, byte [NormalColour] ; Attribute byte
    ; Upper left corner
    xor cx, cx
    ; Bottom right corner
    mov dh, VgaRows
    mov dl, VgaColumns

    int 0x10

    ; Update values
    xor dx, dx
    mov ax, word 160
    pop bx ; Number of lines to scrool
    xor bh, bh ; For safety
    mul bx

    sub word [CursorPos], ax
    sub byte [CurrentRow], bl

    .Finished:
        VgaSetCursor
        
        pop ds
        pop dx
        pop cx
        pop bx

        ret



; Clears the screen and resets values
VgaClearScreen:
    push bx
    push cx
    push es
    push ds

    mov bx, VgaBuffer
    mov es, bx
    mov bx, word KernelSeg
    mov ds, bx

    xor al, al
    mov ah, byte [NormalColour]
    xor bx, bx

    .ClearBuffer:
        cmp bx, word 4000 ; Yep, 4000 freaking times
        jge .Exit

        mov word [es:bx], ax
        add bx, word 2

        jmp .ClearBuffer

    .Exit:
        ; Al is 0 so...
        mov word [CursorPos], 0
        mov byte [CurrentColumn], al
        mov byte [CurrentRow], al

        pop ds
        pop es
        pop cx
        pop bx
        ret



; Clears a single line
; Input:
;   al = line
VgaClearLine:
    push ds
    mov bx, word KernelSeg
    mov ds, bx

    ; Can't do something like: push word [CursorPos]
    mov bx, word [CursorPos]
    push bx
    mov bl, byte [CurrentColumn]
    xor bh, bh
    push bx
    push es

    ; Calculates the cursor position
    xor ah, ah
    mov bx, word 160
    mul bx

    push ax
    mov cx, VgaColumns ; Counter
    xor al, al
    mov ah, byte [NormalColour]

    mov bx, VgaBuffer
    mov es, bx
    pop bx

    .Loop:
        mov word [es:bx], ax
        add bx, 2

        loop .Loop

    .Exit:
        mov word [CursorPos], bx
        pop es
        pop bx
        mov byte [CurrentColumn], bl
        pop bx
        mov word [CursorPos], bx

        pop ds
        ret



; Changes every attribute byte in the vga buffer and the default colour values
; Input:
;   al = normal colour
;   bl = accent colour
VgaPaintScreen:
    push bx
    push cx
    push dx
    push es
    push ds

    mov dl, bl

    mov bx, VgaBuffer
    mov es, bx
    mov bx, word KernelSeg
    mov ds, bx

    mov bx, word 1 ; First attribute byte
    mov cx, 2000

    ; If both colours are 0 don't paint anything
    or al, al
    jz .Exit

    or dl, dl
    jz .Exit

    ; We need to set the new colours
    mov byte [NormalColour], al
    mov byte [AccentColour], dl

    .PaintScreen:
        or cx, cx
        jz .Exit

        mov byte [es:bx], al ; Set attribute byte
        add bx, word 2 ; Next attribute byte
        dec cx

        jmp .PaintScreen


    .Exit:
        pop ds
        pop es
        pop dx
        pop cx
        pop bx
        ret



; Returns the current colours. Might be useful for exernal programs
; Output:
;   bl = normal colour
;   bh = accent colour
VgaGetColours:
    push ds
    mov bx, word KernelSeg
    mov ds, bx

    mov bx, word [ds:NormalColour]

    pop ds
    ret



; Do what backspace does: delete the previous character
; I added this because it was needed by Edit program
VgaBackspace:
    push bx
    push ds

    mov bx, word KernelSeg
    mov ds, bx

    mov al, byte [CurrentColumn]
    mov ah, byte [CurrentRow]

    cmp word [CursorPos], word 0
    jle .Exit

    or al, al
    jnz .Skip

    dec ah
    mov al, byte 79

    .Skip:
        sub word [CursorPos], 2
        mov cl, byte [NormalColour]
        VgaPrintCharMacro 32, cl

        ; Yes, again because VgaPrintCharMacro increments it by 2
        sub word [CursorPos], 2
        ; We decrese CurrentColumn by 2 because then VgaPrintCharMacro increments it
        dec al

        VgaSetCursor

    .Exit:
        mov byte [CurrentColumn], al
        mov byte [CurrentRow], ah

        pop ds
        pop bx
        ret