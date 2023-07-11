[bits 16]
[cpu 8086]



; Prints a given string
; Input:
;   si = pointer to string
PrintString:
    push ax
    mov ah, byte 0x0e ; Teletype mode

    .Loop:
        lodsb ; Loads the current byte into al

        or al, al
        jz .Exit

        int 0x10
        jmp .Loop

    .Exit:
        pop ax
        ret
