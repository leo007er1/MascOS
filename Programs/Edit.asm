[bits 16]
[cpu 286]


; This file is the text editor program for MascOS
; *NOTE: Hasn't been tested yet
; %include "./Kernel/IO.asm"




EditProgram:
    ; Clears the screen
    mov ah, 0
    mov al, 3
    int 0x10

    mov si, EditTopBar
    call PrintString

    call PrintNewDoubleLine
    call PrintNewDoubleLine
    call PrintNewDoubleLine

    mov si, EditNote
    call PrintString

    mov si, EditNote1
    call PrintString

    ; Waits for keypress
    mov ah, 0
    int 0x16

    ret




EditTopBar: db "                           Edit v0.0.1 by leo007er1", 0
EditNote: db "                  This program is being created, not avaiable ", 0
EditNote1: db "                                             Press any key to go back", 0