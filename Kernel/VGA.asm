[bits 16]

; TODO: Make VgaPrintChar work, and finish VgaUpdateAttribute
; * https://wiki.osdev.org/Text_mode


CharsPerLine equ 80
CharsPerColumn equ 25

VgaBuffer: dq 0xb8000
PositionX: db 0
PositionY: db 0
Position: dw 0

ColorAttribute: db 0xf


VgaInit:
    call BiosUpdateVgaPosition

    ret


; Prints a character to the screen
; Input:
;   al = character to print
;   ah = color(optional)
; *NOTE for the future me:
; *ONLY BX can be used as an index register
VgaPrintChar:
    ; call VgaUpdatePosition

    push bx

    cmp ah, byte 0
    jne .Color

    ; No color
    mov bx, [Position]
    mov [VgaBuffer + bx], al

    ; Color
    inc bx
    mov ah, [ColorAttribute]
    mov [VgaBuffer + bx], ah

    jmp .Exit

    .Color:
        mov bx, [Position]
        mov [VgaBuffer + bx], al

        ; Color
        inc bx
        mov [VgaBuffer + bx], ah

    .Exit:
        pop bx

        ret


; Updates the default attribute, ColorAttribute
; Input:
;   ah = foreground color
;   al = background color
VgaUpdateAttribute:


    ret



; Uses BIOS to get the position in vga buffer
BiosUpdateVgaPosition:
    mov ah, 3
    mov bh, 0 ; Page
    int 0x10

    mov [PositionX], dl
    mov [PositionY], dh

    call VgaUpdatePosition

    ret



; Calculates the current position in the vga buffer,
; and moves it to the Position variable
VgaUpdatePosition:
    push ax
    push cx

    mov ax, [PositionY]
    mov cx, CharsPerLine
    mul cx

    add ax, [PositionX]

    mov [Position], ax

    pop ax
    pop cx

    ret
