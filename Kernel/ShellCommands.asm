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
    call VgaPrintNewLine

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
    call VgaPrintNewLine

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
    call VgaPrintNewLine

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
    jz .InvalidName

    ; * I impressed myself with this piece of code. BEHOLD

    lea si, AttributesBuffer
    call StringLenght

    cmp cx, word 11 ; If the name is shorter than 11 bytes throw an error
    jb .InvalidName
    jg .InvalidName

    ; Copy file name into FileFcb
    lea di, FileFcb + 1
    rep movsb

    lea dx, FileFcb
    call CreateFile

    jmp GetCommand.AddNewLine

    .InvalidName:
        lea si, TouchNameInvalid
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

        jmp GetCommand.AddNewLine


renameCmd:
    or ah, ah
    lea si, TouchNameInvalid
    jz .Invalid

    lea si, AttributesBuffer
    call StringLenght

    cmp cx, word 23
    lea si, TouchNameInvalid
    jb .Invalid
    jg .Invalid

    lea di, AttributesBuffer
    lea si, AttributesBuffer + 12
    call RenameFile
    lea si, TrashVimProgramBadArgument
    jnc GetCommand.AddNewLine

    .Invalid:
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
    call VgaPrintNewLine

    lea si, HimomText
    mov al, byte [NormalColour]
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



; Prints system time and date
TimeCmd:
    mov al, byte 1
    call VgaPrintNewLine

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
    lea si, SoundPlayTrack
    call PlayTrack

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
    call VgaPrintNewLine

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
    call VgaPrintNewLine

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
    push es
    mov bx, word ProgramSeg
    mov es, bx
    mov bx, 2
    mov word [es:bx], si
    pop es

    lea si, TrashVimProgramFileName
    call LoadProgram
    jc .Error

    .BadArgument:
        lea si, TrashVimProgramBadArgument
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

    .Error:
        jmp GetCommand.AddNewLine


RunCmd:
    or ah, ah
    jz GetCommand.AddNewLine

    lea si, AttributesBuffer
    call LoadProgram

    .BadArgument:
        lea si, TrashVimProgramBadArgument
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

        jmp GetCommand.AddNewLine


; --//  Commands data  \\--



HelpText: db "  clear = clears the terminal", NewLine, "  ls = list all files", NewLine, "  touch = create a file", NewLine, "  rename = renames a file", NewLine, "  files = launch the file manager", NewLine, \
"  time = show time and date", NewLine, "  edit = edit text files", NewLine, "  run = execute a program", NewLine, "  reboot = reboots the system", NewLine, "  shutdown = shutdown the computer", NewLine, \
"  standby = put system in standby", NewLine, "  fetch = show system info", NewLine, "  colour = change screen colours", NewLine, "  sound = test the pc speaker playing a short track", NewLine, "  himom = ???", 0
HimomText: db "Mom: No one cares about you, honey", NewLine, "Thanks mom :(", 0

SoundPlayTrack: dw 6000, 6800, 6300, 5900, 5000, 0

TimeString: times 16 db 32
db 0

; Fetch command data
FetchSpace: db "      ", 0
FetchText0: db "root", 0
FetchLabel1: db "os    ", 0
FetchLabel2: db "ver   ", 0
FetchLabel3: db "ram   ", 0
FetchText1: db "MascOS", 0
FetchText2: db "0.2.2", 0
FetchText3: db "19.41KB / " ; I'm a genious, I removed the 0 here so it prints FetchTextRam too
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

FileFcb: db CurrentDisk ; Disk
times 11 db 0 ; File name
dw 0 ; Current block number
dw 0 ; Logical record size
dd 512 ; File size
TouchNameInvalid: db NewLine, "File name must be 11 characters(file extension included)", 0

; TrashVim program stuff
TrashVimProgramFileName: db "TRASHVIMCOM", 0
TrashVimProgramBadArgument: db NewLine, "File doesn't exist", 0