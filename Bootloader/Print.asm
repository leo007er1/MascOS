[bits 16]
[cpu 8086]



; Prints a given string
; Input:
;   si = pointer to string
PrintString:
    push ax
    mov ah, 0x0e ; Teletype mode

    .Loop:
        lodsb ; Loads the current byte into al

        cmp al, byte 0
        je .Exit

        int 0x10

        jmp .Loop

    .Exit:
        pop ax

        ret


; Yup, it does what it says
PrintNewLine:
    push ax
    mov ah, 0x0e ; Teletype mode

    ; Carriage return
    mov al, 10
    int 0x10

    ; New line
    mov al, 13
    int 0x10

    pop ax

    ret


