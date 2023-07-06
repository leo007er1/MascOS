[bits 16]
[cpu 8086]


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
    call InitShellCommands

    mov si, InitShellMessage
    mov al, byte [NormalColour]
    call VgaPrintString

    mov si, CommandThing
    mov al, byte [AccentColour]
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
    mov byte [CommandBuffer + si], al
    inc si

    jmp .Continue

    .Enter:
        test si, si
        je .AddNewLine

        .ExecCommand:
            lea di, helpCmdStr
            call CompareCommand
            jnc HelpCmd

            lea di, clearCmdStr
            call CompareCommand
            jnc ClearCmd

            lea di, lsCmdStr
            call CompareCommand
            jnc LsCmd

            lea di, timeCmdStr
            call CompareCommand
            jnc TimeCmd

            lea di, trashVimCmdStr
            call CompareCommand
            jnc TrashVimCmd

            lea di, runCmdStr
            call CompareCommand
            jnc RunCmd

            lea di, fetchCmdStr
            call CompareCommand
            jnc FetchCmd

            lea di, touchCmdStr
            call CompareCommand
            jnc touchCmd

            lea di, rebootCmdStr
            call CompareCommand
            jnc RebootCmd

            lea di, colourCmdStr
            call CompareCommand
            jnc ColourCmd

            lea di, himomCmdStr
            call CompareCommand
            jnc HimomCmd

            lea di, shutdownCmdStr
            call CompareCommand
            jnc ShutdownCmd

            lea di, standbyCmdStr
            call CompareCommand
            jnc StandbyCmd

            lea di, soundCmdStr
            call CompareCommand
            jnc SoundCmd

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
            call ClearAttributesBuffer

            lea si, CommandThing
            mov al, byte [AccentColour]
            call VgaPrintString

            xor si, si ; Resets the command buffer position

            jmp GetCommand


    .Backspace:
        test si, si
        jz GetCommand

        dec si
        mov byte [CommandBuffer + si], byte 0

        ; We decrese CurrentColumn by 2 because then VgaPrintChar increments it
        sub byte [CurrentColumn], 2
        sub word [CursorPos], 2

        mov al, byte 32
        mov cl, byte [NormalColour]
        VgaPrintCharMacro al, cl

        ; Again because VgaPrintChar adds 2 to CursorPos
        sub word [CursorPos], 2
        VgaSetCursor

        jmp GetCommand


    .Continue:
        mov cl, byte [NormalColour]
        VgaPrintCharMacro al, cl
        VgaSetCursor

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
    lea si, CommandBuffer
    ; di is already set

    repe cmpsb
    jnz .Mismatch

    ; Oh yes
    jmp .Exit

    .Mismatch:
        dec di
        dec si

        ; If it's a space then check for attributes
        cmp byte [si], byte 32
        je .CheckForAttributes

        ; If di is 0xff(end of command name) then it's a match
        cmp byte [di], byte 0xff
        je .Exit

        cmp byte [si], byte 0
        jne .GoBack

        .GoBack:
            pop si
            xor al, al
            stc

            ret


    .CheckForAttributes:
        lea di, AttributesBuffer
        xor ah, ah
        xor cl, cl

        .Loop:
            mov al, byte [si]
            cmp al, byte " "
            je .Continue

        .CheckForEnd:
            or al, al
            jz .Exit

        ; When we encounter a text character in our journey inside
        ; the roots of the jungle, this happens...
        .Attribute:
            lodsb
            or al, al
            jz .AttributeEnd

            ; cmp byte [si], byte " "
            ; jne .YetAnotherChar
            jmp .YetAnotherChar

            ; END OF ATTRIBUTE
            ; inc ah
            ; inc di
            ; mov byte [di], byte 0xff ; We separate attributes with 0xff
            ; add byte [AttributesBufferPos], byte 2
            ; inc di

            ; jmp .Continue

            .YetAnotherChar:
                mov byte [di], al ; Moves character to buffer

                inc di
                inc cl
                jmp .Attribute

        .Continue:
            inc si
            jmp .Loop


    .AttributeEnd:
        inc ah
        mov byte [AttributesCounter], ah
        mov byte [AttributesBufferPos], cl

    .Exit:
        pop si

        call ClearCommandBuffer
        clc

        ret



; Returns in si the pointer in the AttributesBuffer of the selected attribute
; Input:
;   al = attribute number
; Output:
;   carry flag = set for error, clear for success
;   si = pointer to attribute in AttributesBuffer
GetAttribute:
    ; If al is greater the given number is invalid. Stupid (joking)
    cmp al, byte [AttributesCounter]
    jng .CheckForZero

    stc
    ret

    .CheckForZero:
        test al, al
        jnz .FindAttribute

        lea si, AttributesBuffer
        ret

    .FindAttribute:
        lea si, AttributesBuffer

        .Loop:
            test al, al
            jz .GetOut

            cmp byte [si], byte 0xff
            je .NextAttribute
            inc si

            jmp .Loop

            .NextAttribute:
                dec al
                jmp .Loop

    .GetOut:
        clc
        ret



; Sets every byte in the command buffer to 0
; Input:
;   si = command buffer position
ClearCommandBuffer:
    .Loop:
        or si, si
        jz .Exit

        mov byte [CommandBuffer + si], byte 0
        dec si
        jmp .Loop

    .Exit:
        ret



; Sets every byte in attributes buffer to 0
ClearAttributesBuffer:
    push si
    xor bh, bh
    mov bl, byte [AttributesBufferPos]

    .Loop:
        or bl, bl
        jz .Exit

        mov byte [AttributesBuffer + bx], byte 0
        dec bl
        jmp .Loop

    .Exit:
        pop si
        mov byte [AttributesBufferPos], byte 0
        mov byte [AttributesCounter], byte 0

        ret


CommandNotFound:
    push si

    mov al, byte 1
    call VgaNewLine

    lea si, CommandNotFoundMessage
    mov al, byte [NormalColour]
    call VgaPrintString

    pop si
    ret





CommandBuffer: times 32 db 0
AttributesBuffer: times 64 db 0
AttributesBufferPos: db 0
AttributesCounter: db 0

CommandThing: db "-> ", 0
InitShellMessage: db "Write 'help' to see command list", 10, 13, 10, 13, 0
CommandNotFoundMessage: db "Command not found", 0

; The commands have an extra letter at the end because if I remove it the command won't just run for some reason
clearCmdStr: db "clear", 0xff
helpCmdStr: db "help", 0xff
lsCmdStr: db "ls", 0xff
touchCmdStr: db "touch", 0xff
trashVimCmdStr: db "edit", 0xff
fetchCmdStr: db "fetch", 0xff
himomCmdStr: db "himom", 0xff
rebootCmdStr: db "reboot", 0xff
soundCmdStr: db "sound", 0xff
colourCmdStr: db "colour", 0xff
timeCmdStr: db "time", 0xff
shutdownCmdStr: db "shutdown", 0xff
standbyCmdStr: db "standby", 0xff
runCmdStr: db "run", 0xff


%include "./Kernel/ShellCommands.asm"