[bits 16]
[cpu 8086]



; Macro that "cleans" the below code
; Input:
;   1 = string to print
%macro PrintFetchLogo 1
    lea si, %1
    mov al, byte [NormalColour]
    call VgaPrintString

    lea si, FetchSpace
    mov al, byte [NormalColour]
    call VgaPrintString

%endmacro

; Another macro that "cleans" the code below
; Input:
;   1 = value name to print
;   2 = value string
%macro PrintFetchText 2
    lea si, %1
    ; al already set
    call VgaPrintString

    lea si, %2
    mov al, byte [NormalColour]
    call VgaPrintString

    mov al, 1
    call VgaNewLine

%endmacro



; It's ugly to put this into InitShell
InitShellCommands:
    ; Converts the amount of ram to text for the fetch command
    lea si, FetchTextRam
    mov ax, word [TotalMemory]
    call IntToString
    mov byte [si], byte "K"
    inc si
    mov byte [si], byte "B"

    ret



; --//  Actual code for shell commands  \\--



HelpCmd:
    mov al, 1
    call VgaNewLine

    lea si, HelpText
    mov al, byte [NormalColour]
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



ClearCmd:
    call VgaClearScreen

    ; We don't want an empty line on the top of the screen
    jmp GetCommand.SkipNewLine



LsCmd:
    mov al, 1
    call VgaNewLine

    push es
    mov ax, word RootDirMemLocation
    mov es, ax
    xor di, di
    mov ch, byte [NormalColour]

    .CheckAndPrint:
        cmp byte [es:di], byte 0
        jz .Finished

        ; Copies the file name to LsDummyFileName
        mov bx, di
        lea si, LsDummyFileName
        call GetFileName

        lea si, LsDummyFileName
        mov al, ch
        call VgaPrintString
        add di, word 32 ; Next entry

        jmp .CheckAndPrint

    .Finished:
        pop es
        jmp GetCommand.AddNewDoubleLine



FilesCmd:
    mov bx, word ProgramSeg
    mov es, bx

    mov bx, 2
    mov word [es:bx], word RootDirMemLocation

    lea si, FilesProgramFileName
    call LoadProgram

    jmp GetCommand.AddNewLine
        


touchCmd:
    or ah, ah
    jz .NoArg

    lea si, FileNameBuffer
    mov bl, byte [NormalColour]
    xor cl, cl

    .NextChar:
        cmp cl, 11 ; 11 is the maximum file name lenght
        jge .CarriageReturn

        xor ax, ax
        int 0x16

        cmp al, byte 13
        je .CarriageReturn

        call VgaPrintChar
        mov byte [ds:si], al ; Move char to buffer
        inc cl
        inc si

        jmp .NextChar

    .CarriageReturn:
        ; If the name is shorter than 4 bytes throw an error
        cmp bl, byte 4
        jl .NameTooShort

        ; call CreateFile


    .NameTooShort:
        lea si, TouchNameTooShort
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

        jmp GetCommand.AddNewLine

    .NoArg:
        lea si, TouchNoArg
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

        jmp GetCommand.AddNewLine



; Note: I could do: jmp 0xffff:0, but I preffer using int 0x19
RebootCmd:
    xor ax, ax
    int 0x19



ShutdownCmd:
    call ApmSystemShutdown
    jmp GetCommand.AddNewLine


StandbyCmd:
    call ApmStandby
    jmp GetCommand.AddNewLine


; Why not, I mean
HimomCmd:
    mov al, 1
    call VgaNewLine

    lea si, HimomText
    mov al, byte [NormalColour]
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



; Prints system time and date
TimeCmd:
    mov al, byte 1
    call VgaNewLine

    call CmosGetSystemTime

    ; Hours
    push ax
    xor al, al
    xchg al, ah
    lea si, TimeString
    call IntToString

    mov byte [si], byte ":"
    inc si

    ; Minutes
    pop ax
    xor ah, ah
    call IntToString

    call CmosGetSystemDate

    ; Day
    push ax
    xor ah, ah
    lea si, TimeString + 7
    call IntToString

    mov byte [si], byte "/"
    inc si

    ; Month
    pop ax
    xor al, al
    xchg al, ah
    call IntToString

    mov byte [si], byte "/"
    inc si

    ; Year
    mov ax, bx
    call IntToString

    ; And finally print the whole thing
    lea si, TimeString
    mov al, byte [NormalColour]
    call VgaPrintString

    jmp GetCommand.AddNewLine



SoundCmd:
    mov bx, word 500
    call PlaySound

    mov cx, 0x1
    mov dx, 0x3000
    mov ah, 0x86
    int 0x15

    jmp GetCommand.AddNewLine


ColourCmd:
    or ah, ah
    jz .NoArg

    lea si, AttributesBuffer
    lea di, ColourResetString
    call StringCompare
    jc .GetColours

    mov al, VgaDefaultColour
    mov bl, 0x0a
    jmp .ResetScreen

    .GetColours:
        lea si, AttributesBuffer
        call StringHexToInt
        mov al, ch
        mov bl, cl

    .ResetScreen:
        call VgaPaintScreen
        jmp .BackToShell

    .NoArg:
        lea si, ColourNoArg
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

    .BackToShell:
        jmp GetCommand.AddNewLine



; Probably the coolest command for now
; *NOTE: takes up a bunch of space, maybe too much
FetchCmd:
    mov al, 1
    call VgaNewLine

    ; Ok now it's a little better

    ; Line with root
    PrintFetchLogo FetchLogo0
    mov al, byte [NormalColour] ; Light red
    and al, 0xfc
    PrintFetchText FetchText0, FetchSpace

    ; Line with os
    PrintFetchLogo FetchLogo1
    mov al, byte [NormalColour] ; Light red
    and al, 0xfc
    PrintFetchText FetchLabel1, FetchText1

    ; Line with ver
    PrintFetchLogo FetchLogo2
    mov al, byte [NormalColour] ; Light cyan
    and al, 0xfb
    PrintFetchText FetchLabel2, FetchText2

    ; Line with ram
    PrintFetchLogo FetchLogo3
    mov al, byte [NormalColour]
    and al, 0xfa ; Light green
    PrintFetchText FetchLabel3, FetchText3

    lea si, FetchLogo4
    mov al, byte [NormalColour]
    call VgaPrintString

    mov al, 1
    call VgaNewLine

    lea si, FetchLogo5
    mov al, byte [NormalColour]
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



TrashVimCmd:
    or ah, ah
    jz .Error

    ; Checks and gets pointer to entry in just 4 lines, cool!
    lea si, AttributesBuffer
    call SearchFile
    jc .BadArgument

    ; Saves the pointer to file entry
    mov bx, word ProgramSeg
    mov es, bx
    mov bx, 2
    mov word [es:bx], si

    lea si, TrashVimProgramFileName
    call LoadProgram
    jc .Error

    .BadArgument:
        mov al, byte 1
        call VgaNewLine

        lea si, TrashVimProgramBadArgument
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

    .Error:
        jmp GetCommand.AddNewLine


RunCmd:
    or ah, ah
    jz TrashVimCmd.Error

    lea si, AttributesBuffer
    call SearchFile
    jc .BadArgument

    lea si, AttributesBuffer
    call LoadProgram
    jc .Error

    .BadArgument:
        mov al, byte 1
        call VgaNewLine

        lea si, TrashVimProgramBadArgument
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

    .Error:
        jmp GetCommand.AddNewLine


; --//  Commands data  \\--



HelpText: db "  clear = clears the terminal", NewLine, "  ls = list all files", NewLine, "  files = launch the file manager", NewLine, "  time = show time and date", NewLine, \
"  edit = edit text files", NewLine, "  run = execute a program", NewLine, "  reboot = reboots the system", NewLine, "  shutdown = shutdown the computer", NewLine, \
"  standby = put system in standby", NewLine, "  fetch = show system info", NewLine, "  colour = change screen colours", NewLine, "  sound = test the pc speaker playing a sound", NewLine, "  himom = ???", 0
HimomText: db "Mom: No one cares about you, honey", NewLine, "Thanks mom :(", 0

TimeString: times 16 db 32
db 0

; Fetch command data
FetchSpace: db "      ", 0
FetchText0: db "root", 0
FetchLabel1: db "os    ", 0
FetchLabel2: db "ver   ", 0
FetchLabel3: db "ram   ", 0
FetchText1: db "MascOS", 0
FetchText2: db "0.2.1", 0
FetchText3: db "21.86KB / " ; I'm a genious, I removed the 0 here so it prints FetchTextRam too
FetchTextRam: times 6 db 0
FetchLogo0: db "  _  ,/|    ", 0
FetchLogo1: db " '\`o.O'   _", 0
FetchLogo2: db "  =(_*_)= ( ", 0
FetchLogo3: db "    )U(  _) ", 0
FetchLogo4: db "   /   \(   ", 0
FetchLogo5: db "  (/`-'\)   ", 0

ColourNoArg: db NewLine, "Insert background and foreground colors in hexadecimal, or type reset to use def", NewLine, "ault colours. ", "Example: 0x818a", 0
ColourResetString: db "reset", 0

LsDummyFileName: times 11 db 0
db "   ", 0

FilesProgramFileName: db "FILEMANACOM", 0

; Touch command
TouchNoArg: db NewLine, "No file name inserted", 0
TouchNameTooShort: db NewLine, "File name must be at least 4 characters(file extension included)", 0

; TrashVim program stuff
TrashVimProgramFileName: db "TRASHVIMCOM", 0
TrashVimProgramBadArgument: db "File doesn't exist", 0