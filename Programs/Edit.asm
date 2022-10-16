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
    mov ah, byte 6
    int 0x21

    mov ah, byte 5
    mov cl, byte 24
    mov al, byte BarsDefaultColour
    int 0x21




; Code is very similar to the shell
ModeSelector:
    WaitForKeyPress

    cmp al, byte 58 ; 58 is :
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
        add si, 0x1800
        mov al, byte BarsDefaultColour
        int 0x21

        .Loop:
            WaitForKeyPress

            cmp al, byte 113 ; 113 is q
            je ModeSelector.Esc
            cmp al, byte 119 ; 119 is w
            je .Write
            cmp al, byte 13 ; Carriage return
            je .Enter

            jmp .Loop


            .Write:
                mov ah, byte 3
                mov al, byte 23
                int 0x21

                xor ah, ah
                lea si, SaveMessage
                add si, 0x1800
                mov al, 0xc ; Red
                int 0x21

                mov ah, byte 3
                mov al, byte 24
                int 0x21

                jmp .Loop

            .Enter:
                ; Clears screen and readd the bottom bar
                mov ah, byte 6
                int 0x21

                mov ah, byte 3
                mov al, byte 24
                int 0x21

                xor ah, ah
                lea si, BottomBar
                add si, 0x1800
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
                xor ax, ax
                lea si, 0x2000
                int 0x22

                jmp TextEdit

    ; Exit and go back to shell
    .Esc:
        jmp 0x7e0:0x4



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
        xor cl, cl
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
        lea si, BottomBar
        add si, 0x1800
        mov al, byte 0xff ; The opposite text color of BarsDefaultColours
        int 0x21

        jmp ModeSelector



BottomBar: db "Esc: exit edit mode", 0
ModeSelectorText: db "W: save changes  Q: exit program", 0
SaveMessage: db "Edit can't save files for now :/", 0
ModeSelectorBuffer: times 6 db 0