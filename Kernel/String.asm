[bits 16]
[cpu 8086]




; Converts a number(intiger) to a string
; Input:
;   ax = number
;   si = pointer to string to output result to
IntToString:
    ; We divide by 10 till the quotient is 0. If it's 0 then we arrived to the end of the number

    push bx
    push cx
    push dx

    xor cx, cx ; Counter
    mov bx, word 10

    .GetRemainders:
        xor dx, dx
        div bx

        push dx ; DX is the remainder
        inc cx

        test ax, ax ; If not 0
        jnz .GetRemainders


    .AssembleString:
        pop dx

        add dl, byte "0" ; We need to convert the number to a string
        mov [si], byte dl
        inc si
        dec cx

        test cx, cx
        jnz .AssembleString

    pop dx
    pop cx
    pop bx

    ret
