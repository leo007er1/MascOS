[bits 16]


; TODO: Now clear works by using "clearr" as the command string, FIX IT


; *General notes
; * Scan code of enter is 13
; * Scan code of backspace is 8
; * Scan code of space is 32



%include "./Kernel/ShellCommands.asm"



CommandThingColor equ 0xa




; Just waits till a key is pressed
;
; Output:
;   al = character
;   ah = BIOS scan code
%macro WaitForKeyPress 0
    xor ax, ax
    mov ah, 0

    int 0x16

%endmacro


InitShell:
    mov si, InitShellMessage
    xor ah, ah
    call VgaPrintString

    mov si, CommandThing
    mov ah, CommandThingColor
    call VgaPrintString

    ; si will be used for the command buffer position
    xor si, si

    jmp GetCommand



; Waits for input and handles it
GetCommand:
    WaitForKeyPress

    cmp al, 13
    je .Enter
    cmp al, 8
    je .Backspace

    ; Saves the character
    mov [CommandBuffer + si], al
    inc si

    jmp .Continue

    .Enter:
        cmp si, byte 0
        je .AddNewLine

        .ExecCommand:
            mov di, help
            call CompareCommand
            cmp ah, byte 0
            je Help

            mov di, clear
            call CompareCommand
            cmp ah, byte 0
            je Clear

            mov di, ls
            call CompareCommand
            cmp ah, byte 0
            je Ls

            mov di, edit
            call CompareCommand
            cmp ah, byte 0
            je Edit

            mov di, fetch
            call CompareCommand
            cmp ah, byte 0
            je Fetch

            mov di, reboot
            call CompareCommand
            cmp ah, byte 0
            je Reboot

            mov di, himom
            call CompareCommand
            cmp ah, byte 0
            je Himom

            call CommandNotFound
            call ClearCommandBuffer

        .AddNewLine:
            call PrintNewLine
            jmp .SkipNewLine

        .AddNewDoubleLine:
            call PrintNewDoubleLine
            
        .SkipNewLine:
            mov si, CommandThing
            ; mov ah, CommandThingColor
            call PrintString

            mov si, 0 ; Resets the command buffer position

            jmp GetCommand


    .Backspace:
        cmp si, byte 0
        je GetCommand

        dec si
        mov [CommandBuffer + si], byte 0

        ; Get cursor position
        mov ah, 3
        mov bh, 0 ; Page
        int 0x10

        dec dl ; Go back a column

        ; Set cursor position
        mov ah, 2
        mov bh, 0 ; Page
        int 0x10

        ; Write char at cursor position
        mov ah, 0xa
        mov al, 0
        mov bh, 0 ; Page
        int 0x10

        jmp GetCommand


    .Continue:
        PrintChar al

        jmp GetCommand



; Compares the CommandBuffer with a given command
; Input:
;   - di = pointer to command string
; Output:
;   - ah = 0 - match, 1 - mismatch
;   - al = number of attributes
CompareCommand:
    push si ; Saves command buffer position

    mov cx, 64 ; How many bytes to compare
    mov si, CommandBuffer
    ; di is already set

    repe cmpsb
    jne .Mismatch

    ; Oh yes
    jmp .CheckForAttributes

    .Mismatch:
        cmp [si], byte 0
        jne .GoBack

        ; If di is 0 then it's a match
        cmp [di], byte 0
        je .CheckForAttributes

        .GoBack:
            pop si
            mov ah, 1

            ret

    .CheckForAttributes:
        xor cx, cx
        xor al, al

        .AttributesLoop:
            cmp si, byte 32
            je .Continue

            ; Not a space
            ; If not a 0 too
            cmp si, byte 0
            je CompareCommand.Exit

            add cx, byte 1 ; Character counter of attribute

            .Continue:
                cmp cx, byte 0
                je .NoAttribute

                ; Check if next character is space, if yes then increment attribute counter
                inc si
                cmp si, byte 32
                je .EndOfAttribute

                cmp si, byte 0
                jne .ResetSi

                add al, byte 1
                dec si
                jmp .Exit

                .ResetSi:
                    dec si
                    jmp .NoAttribute

                .EndOfAttribute:
                    add al, byte 1
                    dec si

                .NoAttribute:
                    inc si

                    jmp .AttributesLoop


    .Exit:
        pop si

        call ClearCommandBuffer
        xor ah, ah

        ret


; Sets every byte in the command buffer to 0
; Input:
;   si = command buffer position
ClearCommandBuffer:
    .Loop:
        cmp si, byte 0
        je .Exit

        mov [CommandBuffer + si], byte 0

        dec si

        jmp .Loop

    .Exit:
        ret


CommandNotFound:
    push si
    call PrintNewLine

    mov si, CommandNotFoundMessage
    call PrintString

    pop si
    ret





CommandBuffer: times 64 db 0

CommandThing: db "~ ", 0
InitShellMessage: db "Write 'help' to see command list", 10, 13, 10, 13, 0
CommandNotFoundMessage: db "Command not found", 0

; The commands have an extra letter at the end because if I remove it the command won't just run for some reason
clear: db "clearr", 0
help: db "helpp", 0
ls: db "lss", 0
edit: db "editt", 0
fetch: db "fetchh", 0
himom: db "himomm", 0
reboot: db "reboott", 0