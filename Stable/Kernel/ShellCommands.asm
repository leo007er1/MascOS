[bits 16]


Help:
    call PrintNewLine
    mov si, HelpText
    call PrintString

    jmp GetCommand.AddNewLine


Clear:
    ; Clears the screen
    mov ah, 0x0
    mov al, 0x3
    int 0x10

    jmp GetCommand.AddNewLine


; Note: I could do: jmp 0xffff:0, but I preffer using int 0x19
Reboot:
    mov ax, 0
    int 0x19


Time:
    ; http://www.ctyme.com/intr/rb-2271.htm
    ; Get system time
    mov ah, 0
    int 0x1a

    jmp GetCommand.AddNewLine



HelpText: db "  clear = clears the terminal", 10, 13, "  reboot = reboots the system", 10, 13, 0