[bits 16]



; Prints a given string
; Set si to the pointer of the string
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


; Macro to print a single character
; I did this instead of a "function" because I would waste or ax or si
; *Note: I could just push ax and si to the stack but I don't care for now
%macro PrintChar 1
    push ax

    mov ah, 0x0e ; Teletype mode
    mov al, %1
    int 0x10

    pop ax

%endmacro
