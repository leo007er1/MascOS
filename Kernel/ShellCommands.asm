[bits 16]


Help:
    call PrintNewLine
    mov si, HelpText
    call PrintString

    jmp GetCommand.AddNewDoubleLine



Clear:
    ; Clears the screen
    mov ah, 0x0
    mov al, 0x3
    int 0x10

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



; Why not.
; *NOTE: takes up a bunch of space, maybe too much
Fetch:
    call PrintNewLine

    ; IT IS THE ONLY WAY, OK?

    mov si, FetchLogo0
    call PrintString
    mov si, FetchSpace
    call PrintString
    mov si, FetchText0
    call PrintString

    call PrintNewLine

    mov si, FetchLogo1
    call PrintString
    mov si, FetchSpace
    call PrintString
    mov si, FetchText1
    call PrintString

    call PrintNewLine

    mov si, FetchLogo2
    call PrintString
    mov si, FetchSpace
    call PrintString
    mov si, FetchText2
    call PrintString

    call PrintNewLine

    mov si, FetchLogo3
    call PrintString
    mov si, FetchSpace
    call PrintString
    mov si, FetchText3
    call PrintString

    call PrintNewLine

    mov si, FetchLogo4
    call PrintString

    call PrintNewLine

    mov si, FetchLogo5
    call PrintString

    jmp GetCommand.AddNewDoubleLine



Time:
    ; http://www.ctyme.com/intr/rb-2271.htm
    ; Get system time
    mov ah, 0
    int 0x1a

    jmp GetCommand.AddNewDoubleLine



HelpText: db "  clear = clears the terminal", 10, 13, "  ls = list all files", 10, 13, "  reboot = reboots the system", 10, 13, "  fetch = show system info", 10, 13, "  himom = ???", 0
HimomText: db "Mom: No one cares about you, honey", 10, 13, "Thanks mom :(", 0
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

LsNoFiles: db "No files to list", 0
LsFileNameSpace: db "    ", 0
KernelName: db "KERNEL  BIN", 0
TestName: db "TEST    TXT", 0