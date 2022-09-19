[bits 16]
[cpu 286]

; cli
; hlt
; jmp EditProgram


; This file is the text editor program for MascOS
; *NOTE: Hasn't been tested yet
; %include "./Kernel/Screen/VGA.asm"


EditTopBar: db "                            Edit v0.0.1 by leo007er1", 0
EditNote: db "                  This program is being created, not available", 0
EditNote1: db "                                             Press any key to go back", 0



EditProgram:
    ; Clears the screen
    call VgaClearScreen

    mov si, EditTopBar
    xor ah, ah
    call VgaPrintString

    mov al, 0x8f
    call VgaPaintLine

    mov al, 6
    call VgaNewLine

    mov si, EditNote
    xor ah, ah
    call VgaPrintString

    mov si, EditNote1
    mov ah, 0xe
    call VgaPrintString

    ; Waits for keypress
    mov ah, 0
    int 0x16

    ret


