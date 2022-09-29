[bits 16]
[cpu 8086]


; TODO: Now clear works by using "clearr" as the command string, FIX IT


; *General notes
; * Scan code of enter is 13
; * Scan code of backspace is 8
; * Scan code of space is 32


CommandThingColor equ 0xa



; Just waits till a key is pressed
;
; Output:
;   al = character
;   ah = BIOS scan code
%macro WaitForKeyPress 0
    xor ax, ax

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

    cmp al, byte 13
    je .Enter
    cmp al, byte 8
    je .Backspace

    ; Saves the character
    mov [CommandBuffer + si], al
    inc si

    jmp .Continue

    .Enter:
        test si, si
        je .AddNewLine

        .ExecCommand:
            mov di, help
            call CompareCommand
            test ah, ah
            je Help

            mov di, clear
            call CompareCommand
            test ah, ah
            je Clear

            mov di, ls
            call CompareCommand
            test ah, ah
            je Ls

            mov di, edit
            call CompareCommand
            test ah, ah
            je Edit

            mov di, fetch
            call CompareCommand
            test ah, ah
            je Fetch

            mov di, reboot
            call CompareCommand
            test ah, ah
            je Reboot

            mov di, himom
            call CompareCommand
            test ah, ah
            je Himom

            call CommandNotFound
            call ClearCommandBuffer

        .AddNewLine:
            mov al, 1
            call VgaNewLine
            jmp .SkipNewLine

        .AddNewDoubleLine:
            mov al, 2
            call VgaNewLine
            
        .SkipNewLine:
            mov si, CommandThing
            mov ah, CommandThingColor
            call VgaPrintString

            xor si, si ; Resets the command buffer position

            jmp GetCommand


    .Backspace:
        test si, si
        je GetCommand

        dec si
        mov [CommandBuffer + si], byte 0

        ; We decrese CurrentColumn by 2 because then VgaPrintChar increments it
        sub byte [CurrentColumn], 2
        sub word [CursorPos], 2

        mov al, 32
        VgaPrintChar al, 0

        ; Again because VgaPrintChar adds 2 to CursorPos
        sub word [CursorPos], 2

        jmp GetCommand


    .Continue:
        VgaPrintChar al, 0

        jmp GetCommand



; Compares the CommandBuffer with a given command
; Input:
;   - di = pointer to command string
; Output:
;   - ah = 0 - match, 1 - mismatch
;   - al = number of attributes
CompareCommand:
    push si ; Saves command buffer position

    mov cx, 32 ; How many bytes to compare
    mov si, CommandBuffer
    ; di is already set

    repe cmpsb
    jne .Mismatch

    ; Oh yes
    jmp .CheckForAttributes

    .Mismatch:
        ; If it's a space then check for attributes
        cmp [si], byte 32
        je .CheckForAttributes

        cmp [si], byte 0
        jne .GoBack

        ; If di is 0 then it's a match
        cmp [di], byte 0
        je .Exit

        .GoBack:
            pop si
            mov ah, 1
            xor al, al

            ret


    .CheckForAttributes:
        mov di, AttributesBuffer
        xor al, al

        .Loop:
            cmp [si], byte 32 ; 32 is a space
            je .Continue

        .CheckForEnd:
            cmp [si], byte 0
            je .Exit

        ; When we encounter a text character in our journey inside
        ; the roots of the jungle, this happens...
        .Attribute:
            cmp [si], byte 0
            je .AttributeEnd

            cmp [si], byte 32
            jne .YetAnotherChar

            ; END OF ATTRIBUTE
            inc al
            inc di
            inc byte [AttributesBufferPos]
            mov [di], byte 32 ; We separate attributes with a space

            jmp .Continue

            .YetAnotherChar:
                ; Moves character to buffer
                mov bl, byte [si]
                mov byte [di], bl

                inc si
                inc di
                inc byte [AttributesBufferPos]
                jmp .Attribute

        .Continue:
            inc si
            jmp .Loop


    .AttributeEnd:
        inc al

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
        test si, si
        je .Exit

        mov [CommandBuffer + si], byte 0
        dec si

        jmp .Loop

    .Exit:
        ret



; Sets every byte in attributes buffer to 0
ClearAttributesBuffer:
    push si
    mov si, [AttributesBufferPos]

    .Loop:
        test si, si
        je .Exit

        mov [AttributesBuffer + si], byte 0
        dec si

        jmp .Loop

    .Exit:
        pop si
        mov byte [AttributesBufferPos], 0

        ret


CommandNotFound:
    push si

    mov al, 1
    call VgaNewLine

    mov si, CommandNotFoundMessage
    xor ah, ah
    call VgaPrintString

    pop si
    ret





CommandBuffer: times 32 db 0
AttributesBuffer: times 64 db 0
AttributesBufferPos: db 0

CommandThing: db "-> ", 0
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


%include "./Kernel/ShellCommands.asm"