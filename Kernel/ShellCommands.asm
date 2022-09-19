[bits 16]
[cpu 286]


FetchLogoColor equ 0x7



; Macro that "cleans" the below code
; Input:
;   1 = string to print
%macro PrintFetchLogo 1
    mov si, %1
    mov ah, FetchLogoColor
    call VgaPrintString

    mov si, FetchSpace
    xor ah, ah
    call VgaPrintString

%endmacro

; Another macro that "cleans" the code below
; Input:
;   1 = value name to print
;   2 = value string
%macro PrintFetchText 2
    mov si, %1
    ; ah already set
    call VgaPrintString

    mov si, %2
    xor ah, ah
    call VgaPrintString

    mov al, 1
    call VgaNewLine

%endmacro



; --//  Actual code for shell commands  \\--



Help:
    mov al, 1
    call VgaNewLine
    mov si, HelpText
    xor ah, ah
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



Clear:
    call VgaClearScreen

    ; We don't want an empty line on the top of the screen
    jmp GetCommand.SkipNewLine


; It's ugly for now, but I might have an idea to just use a loop
Ls:
    mov al, 1
    call VgaNewLine

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
        xor ah, ah
        call VgaPrintString

        mov si, LsFileNameSpace
        xor ah, ah
        call VgaPrintString

        ret

    .Skip:
        mov si, LsNoFiles
        mov ah, 0xc
        call VgaPrintString

    .Finished:
        jmp GetCommand.AddNewDoubleLine
        




; Note: I could do: jmp 0xffff:0, but I preffer using int 0x19
Reboot:
    mov ax, 0
    int 0x19



; Why not, I mean
Himom:
    mov al, 1
    call VgaNewLine
    mov si, HimomText
    xor ah, ah
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



; Probably the coolest command for now
; *NOTE: takes up a bunch of space, maybe too much
Fetch:
    mov al, 1
    call VgaNewLine

    ; Ok now it's a little better

    ; Line with root
    PrintFetchLogo FetchLogo0
    mov ah, 0xc ; Light red
    PrintFetchText FetchText0, FetchSpace

    ; Line with os
    PrintFetchLogo FetchLogo1
    mov ah, 0xc ; Light red
    PrintFetchText FetchLabel1, FetchText1

    ; Line with ver
    PrintFetchLogo FetchLogo2
    mov ah, 0xb ; Light cyan
    PrintFetchText FetchLabel2, FetchText2

    ; Line with ram
    PrintFetchLogo FetchLogo3
    mov ah, 0xa ; Light green
    PrintFetchText FetchLabel3, FetchText3

    mov si, FetchLogo4
    mov ah, FetchLogoColor
    call VgaPrintString

    mov al, 1
    call VgaNewLine

    mov si, FetchLogo5
    mov ah, FetchLogoColor
    call VgaPrintString

    jmp GetCommand.AddNewDoubleLine



Edit:
    mov si, EditProgramFileName
    call SearchFile

    cmp ah, byte 1
    je Edit.Error

    ; mov bx, 0x400 ; 1KB
    ; mov di, cx ; Pointer to entry
    ; call LoadFile
    ; jmp 0x7e0:0x1000
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
FetchLabel1: db "os    ", 0
FetchLabel2: db "ver   ", 0
FetchLabel3: db "ram   ", 0
FetchText1: db "MascOS", 0
FetchText2: db "0.1.5", 0
FetchText3: db "15.09KB / 639KB", 0
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