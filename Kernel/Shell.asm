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

    xor si, si ; si will be used for the command buffer position



; Waits for input and handles it
GetCommand:
    cmp si, word 32
    je .ExecCommand

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
        or si, si
        jz .AddNewLine

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

            lea di, filesCmdStr
            call CompareCommand
            jnc FilesCmd

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

            lea di, renameCmdStr
            call CompareCommand
            jnc renameCmd

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
            call VgaPrintNewLine
            jmp .SkipNewLine

        .AddNewDoubleLine:
            mov al, 2
            call VgaPrintNewLine
            
        .SkipNewLine:
            call ClearAttributesBuffer

            lea si, CommandThing
            mov al, byte [AccentColour]
            call VgaPrintString

            xor si, si ; Resets the command buffer position

            jmp GetCommand


    .Backspace:
        or si, si
        jz GetCommand

        dec si
        mov byte [CommandBuffer + si], byte 0

        ; We decrese CurrentColumn by 2 because then VgaPrintChar increments it
        sub byte [CurrentColumn], 2
        sub word [CursorPos], 2

        mov al, byte 32
        mov bl, byte [NormalColour]
        call VgaPrintChar

        ; Again because VgaPrintChar adds 2 to CursorPos
        sub word [CursorPos], 2
        call VgaSetCursor

        jmp GetCommand


    .Continue:
        mov bl, byte [NormalColour]
        call VgaPrintChar

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

        .GoBack:
            pop si
            xor ah, ah
            stc

            ret


    .CheckForAttributes:
        lea di, AttributesBuffer
        xor ah, ah
        xor cl, cl

        .Loop:
            lodsb
            cmp al, byte " "
            je .Loop

            dec si

        ; When we encounter a text character in our journey inside
        ; the roots of the jungle, this happens...
        .Attribute:
            lodsb
            or al, al
            jz .AttributeEnd

            cmp al, byte " "
            jne .YetAnotherChar

            inc ah

            .YetAnotherChar:
                mov byte [di], al ; Moves character to buffer

                inc di
                inc cl
                jmp .Attribute


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
;   ah = attribute number
; Output:
;   carry flag = set for error, clear for success
;   ds:si = pointer to attribute in AttributesBuffer
GetAttribute:
    cmp ah, byte [AttributesCounter]
    jg .Error

    lea si, AttributesBuffer
    xor cl, cl

    .Loop:
        cmp cl, ah
        jge .GetOut

        lodsb
        or al, al
        jz .Error
        cmp al, byte 32
        jne .Loop

        inc cl
        jmp .Loop

    .GetOut:
        clc
        ret

    .Error:
        stc
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
    xor bh, bh
    mov bl, byte [AttributesBufferPos]

    .Loop:
        or bl, bl
        jz .Exit

        mov byte [AttributesBuffer + bx], byte 0
        dec bl
        jmp .Loop

    .Exit:
        mov word [AttributesBufferPos], word 0
        ret


CommandNotFound:
    push si

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
InitShellMessage: db "Write 'help' to see command list", NewLine, NewLine, 0
CommandNotFoundMessage: db NewLine, "Command not found", 0

; The commands have an extra letter at the end because if I remove it the command won't just run for some reason
clearCmdStr: db "clear", 0xff
helpCmdStr: db "help", 0xff
lsCmdStr: db "ls", 0xff
touchCmdStr: db "touch", 0xff
renameCmdStr: db "rename", 0xff
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
filesCmdStr: db "files", 0xff


%include "./Kernel/ShellCommands.asm"