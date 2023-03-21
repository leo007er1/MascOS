[bits 16]
[cpu 8086]


; *This is the text editor program for MascOS
; ! It's in early stages of development and it doesn't save files!

; * This program is inspired by Vim
; When you launch the text editor you can't type, but you can press enter and edit the text directly.
; When in mode selection, you can tell by looking at the bottom bar and if you typed ":", you can type these letters that do nothing for now.
;   w = write
;   q = close
;
; You can also exit by pressing Esc twice if you are editing text, or once when you aren't.



ProgramEntryPoint:
    jmp EditProgram




BarsDefaultColour equ 0xf0
NormalColour: db 0
AccentColour: db 0



; Just waits till a key is pressed
;
; Output:
;   al = character
;   ah = BIOS scan code
%macro WaitForKeyPress 0
    xor ax, ax

    int 0x16

%endmacro



EditProgram:
    push cx

    ; Get colours
    mov ah, byte 8
    int 0x21
    mov word [NormalColour], bx ; Sets AccentColour too

    ; Clear screen
    mov ah, byte 6
    int 0x21

    ; Print file name
    mov bx, cx ; Get that pointer back
    mov ah, byte 2
    lea si, FileName
    int 0x22

    ; Print top text
    mov ah, byte 2
    mov al, byte 3
    int 0x21

    xor ah, ah
    mov al, byte [AccentColour]
    and al, byte 0xfe
    lea si, EditingMessage
    int 0x21

    ; Print bottom bar
    mov ah, byte 3
    mov al, byte 24
    int 0x21

    xor ah, ah
    mov al, byte [NormalColour]
    lea si, BottomBarModeSelector
    int 0x21

    ; Paint bottom line
    mov ah, byte 5
    mov cl, byte 24
    mov al, byte [NormalColour]
    and al, byte 0xf7
    int 0x21

    ; Loads file after this program
    ; *NOTE:
    ;* I KNOW that I shouldn't do this, but uff, I'm too lazy to figure out a workaroud fort his
    pop di
    mov bx, word 0x400 ; 3KB
    mov ah, byte 1
    int 0x22


; Code is very similar to the shell
ModeSelector:
    WaitForKeyPress

    cmp al, byte ":"
    je .EnterCommand
    cmp al, byte 27
    je .Esc
    cmp al, byte 13
    je .Enter

    jmp ModeSelector

    .EnterCommand:
        mov ah, byte 3
        mov al, byte 24
        int 0x21

        xor ah, ah
        lea si, ModeSelectorText
        mov al, byte BarsDefaultColour
        int 0x21

        .Loop:
            WaitForKeyPress

            cmp al, byte "q"
            je ModeSelector.Esc
            cmp al, byte "w"
            je .Write
            cmp al, byte 13 ; Carriage return
            je .Enter

            jmp .Loop


            .Write:
                mov ah, byte 3
                mov al, byte 23
                int 0x21

                ; Show message
                xor ah, ah
                lea si, SaveMessage
                mov al, byte [AccentColour]
                and al, 0xfc ; Red
                int 0x21

                mov ah, byte 3
                mov al, byte 24
                int 0x21

                jmp .Loop

            .Enter:
                ; Clears screen and read the bottom bar
                mov ah, byte 6
                int 0x21

                mov ah, byte 3
                mov al, byte 24
                int 0x21

                xor ah, ah
                lea si, BottomBarEditMode
                mov al, byte BarsDefaultColour
                int 0x21

                mov ah, byte 5
                mov al, byte BarsDefaultColour
                mov cl, byte 24
                int 0x21

                mov ah, byte 3
                xor al, al
                int 0x21

                ; Prints the text of the file
                mov si, 0x400 ; 2KB after this file
                xor ah, ah
                mov al, byte [NormalColour]
                int 0x21

                jmp TextEdit

    ; Exit and go back to shell
    .Esc:
        int 0x20



TextEdit:
    WaitForKeyPress

    cmp al, byte 13
    je .Enter
    cmp al, byte 8
    je .Backspace
    cmp al, byte 27
    je .Esc

    .NormalCharacter:
        mov ah, byte 1
        mov cl, byte [NormalColour]
        int 0x21

        jmp TextEdit

    .Enter:
        mov ah, byte 2
        mov al, byte 1
        int 0x21

        jmp TextEdit

    .Backspace:
        mov ah, byte 7
        int 0x21

        jmp TextEdit


    ; Go to mode selector
    .Esc:
        mov ah, byte 3
        mov al, byte 24
        int 0x21

        mov ah, byte 5
        mov al, byte BarsDefaultColour
        mov cl, byte 24
        int 0x21

        xor ah, ah
        lea si, BottomBarEditMode
        mov al, byte 0xff ; The opposite text color of BarsDefaultColours
        int 0x21

        jmp ModeSelector



EditingMessage: db "                        Currently editing  "
FileName: times 12 db 0
BottomBarModeSelector: db "Press enter to edit  |  Esc to exit program                      TrashVim v0.1.0", 0
BottomBarEditMode: db "Esc: exit edit mode", 0
ModeSelectorText: db "W: save changes  Q: exit program", 0
SaveMessage: db "Edit can't save files for now :/", 0
ModeSelectorBuffer: times 6 db 0