[bits 16]
[cpu 286]


; Macro that "cleans" the below code
; Input:
;   1 = string to print
%macro PrintFetchLogo 1
    mov si, %1
    call PrintString

    mov si, FetchSpace
    call PrintString

%endmacro

; Another macro that "cleans" the code below
; Input:
;   1 = string to print
%macro PrintFetchText 1
    mov si, %1
    call PrintString

    call PrintNewLine

%endmacro



; --//  Actual code for shell commands  \\--



Help:
    call PrintNewLine
    mov si, HelpText
    call PrintString

    jmp GetCommand.AddNewDoubleLine



Clear:
    call VgaClearScreen

    ; We don't want an empty line on the top of the screen
    jmp GetCommand.SkipNewLine


; It's ugly for now, but I might have an idea to just use a loop
Ls:
    call PrintNewLine

    mov si, KernelName
    call SearchFile
    cmp ah, byte 1
    je .Skip
    call .PrintName

    mov si, TestName
    call SearchFile
    cmp ah, byte 1
    je .Skip
    call .PrintName

    jmp .Finished

    .PrintName:
        mov si, dx
        call PrintString

        mov si, LsFileNameSpace
        call PrintString

        ret

    .Skip:
        mov si, LsNoFiles
        call PrintString

    .Finished:
        jmp GetCommand.AddNewDoubleLine
        

    ; This one is gonna be heavy
    ; .Loop:
    ;     call SearchFile


    ;     jmp .Loop



; Note: I could do: jmp 0xffff:0, but I preffer using int 0x19
Reboot:
    mov ax, 0
    int 0x19



; Why not, I mean
Himom:
    call PrintNewLine
    mov si, HimomText
    call PrintString

    jmp GetCommand.AddNewDoubleLine



; Probably the coolest command for now
; *NOTE: takes up a bunch of space, maybe too much
Fetch:
    call PrintNewLine

    ; Ok now it's a little better

    ; Line with root
    PrintFetchLogo FetchLogo0
    PrintFetchText FetchText0

    ; Line with os
    PrintFetchLogo FetchLogo1
    PrintFetchText FetchText1

    ; Line with ver
    PrintFetchLogo FetchLogo2
    PrintFetchText FetchText2

    ; Line with ram
    PrintFetchLogo FetchLogo3
    PrintFetchText FetchText3

    mov si, FetchLogo4
    call PrintString

    call PrintNewLine

    mov si, FetchLogo5
    call PrintString

    jmp GetCommand.AddNewDoubleLine



Edit:
    mov si, EditProgramFileName
    call SearchFile

    cmp ah, byte 1
    je Edit.Error

    ; di already set
    ; mov bx, 0x400 ; 1KB
    ; call LoadFile
    ; jmp 0x400
    call EditProgram

    .Error:
        jmp GetCommand.AddNewDoubleLine



; --//  Commands data  \\--



HelpText: db "  clear = clears the terminal", 10, 13, "  ls = list all files", 10, 13, "  edit = edit text files", 10, 13, "  reboot = reboots the system", 10, 13, "  fetch = show system info", 10, 13, "  himom = ???", 0
HimomText: db "Mom: No one cares about you, honey", 10, 13, "Thanks mom :(", 0
EditProgramFileName: db "EDIT    BIN", 0

; Fetch command data
FetchSpace: db "      ", 0
FetchText0: db "root", 0
FetchText1: db "os    MascOS", 0
FetchText2: db "ver   0.1.4", 0
FetchText3: db "ram   14.25KB / 639KB", 0
FetchLogo0: db "  _  ,/|    ", 0
FetchLogo1: db " '\`o.O'   _", 0
FetchLogo2: db "  =(_*_)= ( ", 0
FetchLogo3: db "    )U(  _) ", 0
FetchLogo4: db "   /   \(   ", 0
FetchLogo5: db "  (/`-'\)   ", 0

; Ls command data
LsNoFiles: db "No files to list", 0
LsFileNameSpace: db "    ", 0
KernelName: db "KERNEL  BIN", 0
TestName: db "TEST    TXT", 0

%include "./Programs/Edit.asm"