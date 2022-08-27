[org 0x8000]
[bits 16]

jmp Main

; This will work for now
%include "./Bootloader/Print.asm"
%include "./Kernel/Shell.asm"


Main:
    ; Clears the screen
    mov ah, 0
    mov al, 3
    int 0x10
    
    jmp InitShell

    jmp $


; Fills 8 sectors
times 4096 db 0