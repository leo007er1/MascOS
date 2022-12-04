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


; Converts some numbers in a string an intiger
; Input:
;   si = pointer to string
;   al = how many characters to convert
; Output:
;   cx = intiger
;   ah = status
StringToInt:
    push bx
    push cx
    push dx

    mov bh, al
    xor ax, ax
    xor cx, cx

    .GetNextCharacter:
        test bh, bh
        jz .End

        lodsb

        sub al, byte "0" ; Converts it into a number
        cmp al, byte 9
        jg .Error

        ; What we do is this:
        ; cx * 10 + al
        push ax
        push bx
        xor dx, dx
        mov ax, cx
        mov bx, word 10
        mul bx

        pop bx
        pop dx
        add cx, dx

        dec bh
        jmp .GetNextCharacter

    .Error:
        cli
        hlt

    .End:
        pop dx
        pop cx
        pop bx
        ret