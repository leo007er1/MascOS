[bits 16]
[cpu 8086]




; Converts a number(intiger) to a string
; Input:
;   ax = number
; Output:
;   si = pointer to string
IntToString:
    ; We divide by 10 till the quotient is 0. If it's 0 then we arrived to the end of the number
    ; * For now we store the output in a temporany string

    push bx
    push cx
    push dx

    mov si, IntToStringOutput
    xor cx, cx ; Counter
    mov bx, 10

    .GetRemainders:
        xor dx, dx
        div bx

        push dx ; DX is the remainder
        inc cx

        test ax, ax ; If 0
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


IntToStringOutput: times 8 db 0