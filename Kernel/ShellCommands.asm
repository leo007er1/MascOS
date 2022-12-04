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


; It's ugly for now, but I might have an idea to just use a loop
LsCmd:
    mov al, 1
    call VgaNewLine

    mov ax, RootDirMemLocation
    mov es, ax
    xor di, di
    xor cx, cx

    .CheckAndPrint:
        cmp byte [es:di], byte 0
        je .Finished

        ; Copies the file name to LsDummyFileName
        mov bx, di
        lea si, LsDummyFileName
        call GetFileName

        call .PrintName
        add di, word 32 ; Next entry
        inc cx

        jmp .CheckAndPrint


    .PrintName:
        lea si, LsDummyFileName
        mov al, byte [NormalColour]
        call VgaPrintString

        lea si, LsFileNameSpace
        mov al, byte [NormalColour]
        call VgaPrintString

        ret


    .Finished:
        mov ax, KernelSeg
        mov es, ax

        jmp GetCommand.AddNewDoubleLine
        




; Note: I could do: jmp 0xffff:0, but I preffer using int 0x19
RebootCmd:
    xor ax, ax
    int 0x19



ShutdownCmd:
    call ApmSystemShutdown

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



; Mom, why doesn't this work?
SoundCmd:
    mov ax, word 20
    call PlaySound

    jmp GetCommand.AddNewLine



CatCmd:
    test al, al
    jz .Error

    ; Checks and gets pointer to entry in just 4 lines, cool!
    lea si, AttributesBuffer
    call SearchFile
    jc .BadArgument

    .Continue:
        mov bx, word ProgramSeg
        mov es, bx
        mov di, cx
        xor bx, bx
        call LoadFile

        mov al, byte 1
        call VgaNewLine

        mov si, word 0x1800
        mov al, byte [NormalColour]
        call VgaPrintString

        mov bx, word KernelSeg
        mov es, bx

        jmp GetCommand.AddNewDoubleLine

    .BadArgument:
        mov al, byte 1
        call VgaNewLine

        lea si, TrashVimProgramBadArgument
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

    .Error:
        jmp GetCommand.AddNewLine




ColourCmd:
    mov al, byte 0x71
    mov bl, byte 0x7e

    call VgaPaintScreen

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
    test al, al
    jz .Error

    ; Checks and gets pointer to entry in just 4 lines, cool!
    lea si, AttributesBuffer
    call SearchFile
    jc .BadArgument

    .Continue:
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




; --//  Commands data  \\--



HelpText: db "  clear = clears the terminal", 10, 13, "  ls = list all files", 10, 13, "  time = show time and date", 10, 13, "  cat = show file contents", 10, 13, "  edit = edit text files", 10, 13, "  reboot = reboots the system", 10, 13, "  shutdown = shutdown the computer", 10, 13, "  fetch = show system info", 10, 13, "  colour = change screen colours", 10, 13, "  himom = ???", 0
HimomText: db "Mom: No one cares about you, honey", 10, 13, "Thanks mom :(", 0

TimeString: times 16 db 32
db 0

; Fetch command data
FetchSpace: db "      ", 0
FetchText0: db "root", 0
FetchLabel1: db "os    ", 0
FetchLabel2: db "ver   ", 0
FetchLabel3: db "ram   ", 0
FetchText1: db "MascOS", 0
FetchText2: db "0.2.0", 0
FetchText3: db "18.11KB / " ; I'm a genious, I removed the 0 here so it prints FetchTextRam too
FetchTextRam: times 6 db 0
FetchLogo0: db "  _  ,/|    ", 0
FetchLogo1: db " '\`o.O'   _", 0
FetchLogo2: db "  =(_*_)= ( ", 0
FetchLogo3: db "    )U(  _) ", 0
FetchLogo4: db "   /   \(   ", 0
FetchLogo5: db "  (/`-'\)   ", 0

; Ls command data
LsNoFiles: db "File not found", 0
LsFileNameSpace: db "   ", 0
LsDummyFileName: times 12 db 0

; TrashVim program stuff
TrashVimProgramFileName: db "TRASHVIMBIN", 0
TrashVimProgramBadArgument: db "File doesn't exist", 0