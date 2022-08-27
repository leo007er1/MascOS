[org 0x1000]
[bits 16]

jmp Main

; This will work for now
%include "./Stable/Bootloader/Print.asm"
; %include "./Kernel/VGA.asm"
%include "./Stable/Kernel/Shell.asm"


Main:
    ; Clears the screen
    mov ah, 0
    mov al, 3
    int 0x10

    ; call VgaInit
    ; mov al, 67
    ; mov ah, 0
    ; call VgaPrintChar
    
    jmp InitShell

    jmp $


; Fills 6 sectors
times 3072 db 0