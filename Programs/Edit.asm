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


%include "./Kernel/Screen/VGA.asm"

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



; Where the RunProgram label brings us to
EditProgram:
    call VgaClearScreen

    mov al, byte 24
    call VgaGotoLine
    mov al, byte BarsDefaultColour
    call VgaPaintLine




; Code is very similar to the shell
ModeSelector:
    WaitForKeyPress

    cmp al, byte 58 ; 58 is :
    je .EnterCommand
    cmp al, byte 27 ; Esc
    je .Esc
    cmp al, byte 13 ; Carriage return
    je .Enter

    jmp ModeSelector

    .EnterCommand:
        mov al, byte 58
        VgaPrintChar al, BarsDefaultColour

        ; Counter
        xor si, si

        .Loop:
            WaitForKeyPress

            cmp al, byte 113 ; 113 is q
            je .YesCharacter
            cmp al, byte 119 ; 119 is w
            je .YesCharacter
            cmp al, byte 13 ; Carriage return
            je .Enter

            jmp .Loop

            .YesCharacter:
                cmp si, byte 6
                je .Loop

                inc si
                VgaPrintChar al, BarsDefaultColour

                jmp .Loop

            .Enter:
                call VgaClearScreen

                mov al, byte 24
                call VgaGotoLine
                mov al, byte BarsDefaultColour
                call VgaPaintLine
                mov si, EditBottomBar
                mov ah, byte BarsDefaultColour
                call VgaPrintString

                mov al, byte 0
                call VgaGotoLine

                ; Prints the text of the file
                mov si, 0x800
                xor ah, ah
                call VgaPrintString

                jmp TextEdit

    ; Exit and go to shell
    .Esc:
        mov ax, 0x7e0
        mov bx, 4
        push ax
        push bx

        retf



TextEdit:
    WaitForKeyPress

    cmp al, byte 13
    je .Enter
    cmp al, byte 8
    je .Backspace
    cmp al, byte 27
    je .Esc

    .NormalCharacter:
        VgaPrintChar al, 0
        jmp TextEdit

    .Enter:
        mov al, 1
        call VgaNewLine

        jmp TextEdit

    .Backspace:
        cmp [CursorPos], word 0
        jle TextEdit

        ; We decrese CurrentColumn by 2 because then VgaPrintChar increments it
        sub byte [CurrentColumn], 2
        sub word [CursorPos], 2

        mov al, 32
        VgaPrintChar al, 0

        ; Again because VgaPrintCHar adds 2 to CursorPos
        sub word [CursorPos], 2

        jmp TextEdit


    ; Go to mode selector
    .Esc:
        mov al, byte 24
        call VgaGotoLine
        mov al, byte BarsDefaultColour
        call VgaPaintLine
        mov si, EditBottomBar
        mov ah, byte 0xff ; The opposite text color of BarsDefaultColours
        call VgaPrintString

        jmp ModeSelector



EditBottomBar: db "Esc: exit edit mode", 0
ModeSelectorBuffer: times 6 db 0