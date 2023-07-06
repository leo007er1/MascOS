[bits 16]
[cpu 8086]



; Gets the lenght of a string
; Input:
;   si = string
; Output:
;   cx = lenght of string
StringLenght:
    push ax
    push si
    xor cx, cx

    .NextChar:
        lodsb
        or al, al
        jz .Exit

        inc cx
        jmp .NextChar

    .Exit:
        pop si
        pop ax
        ret


; Compares 2 strings
; Input:
;   si = first string
;   di = second string
; Output:
;   carry flag = clear for identical strings, set for a mismatch
;   si and di = first mismatch in both strings
StringCompare:
    push cx

    cld

    push si
    call StringLenght
    pop si

    ; cx is how many bytes to compare
    .loop:
        mov al, byte [si]
        mov ah, byte [di]

        cmp al, ah
        jne .Mismatch

        inc si
        inc di
        loop .loop

    .NoMismatch:
        pop cx
        clc
        ret

    .Mismatch:
        pop cx
        stc
        ret


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


; Converts numbers in a string to an intiger
; Input:
;   si = pointer to string
; Output:
;   cx = intiger
StringToInt:
    push bx
    push dx

    xor ah, ah
    xor bx, bx ; bx stores our value
    call StringLenght
    ; cx is the lenght of the string

    .NextChar:
        test cx, cx
        jz .Exit

        lodsb
        or al, al
        jz .Exit

        cmp al, byte 0x39 ; "9"
        jg .Exit
        cmp al, byte 0x30 ; "0"
        jl .Exit

        sub al, byte 0x30 ; "0"

        ; bx * 10 + al
        push ax
        mov ax, bx
        mov dx, word 10
        mul dx

        pop dx
        add ax, dx
        mov bx, ax

        dec cx
        jmp .NextChar

    .Exit:
        mov cx, bx

        pop dx
        pop bx

        ret


; Converts a hex number(maximum lenght of 4) in a string to an int
; Input:
;   si = pointer to string
; Output:
;   cx = intiger
;   carry flag = set for invalid chars
StringHexToInt:
    push di

    xor cx, cx ; Counter
    lea di, StringHexToIntBuffer

    ; 0x3078 are two characters, "0x", we skip those if they're present
    cmp byte [si], byte 0x30
    jne .SkipChars

    inc si
    cmp byte [si], byte 0x78
    jne .ResetSi

    inc si
    jmp .SkipChars

    .ResetSi:
        ; There's "0" but not "x", so we need to count that "0"
        dec si

    .SkipChars:
        cmp cl, byte 4
        je .CalculateValue

        mov al, byte [si]

        or al, al
        jz .CalculateValue
        cmp al, byte 0x66 ; "f"
        jg .InvalidChar
        cmp al, byte 0x61 ; "a"
        jl .UpperCaseChars

        sub al, byte 0x57 ; "a" - 10
        jmp .NextChar

        .UpperCaseChars:
            cmp al, byte 0x46 ; "F"
            jg .InvalidChar
            cmp al, byte 0x41 ; "A"
            jl .Digits

            sub al, byte 0x37 ; "A" - 10
            jmp .NextChar

        .Digits:
            cmp al, byte 0x39 ; "9"
            jg .InvalidChar
            cmp al, byte 0x30 ; "0"
            jl .InvalidChar

            sub al, byte 0x30 ; "0"

        .NextChar:
            mov byte [di], al ; Save the digit
            inc si
            inc cl
            inc di

            jmp .SkipChars

    .CalculateValue:
        lea si, StringHexToIntBuffer
        xor bx, bx

        .CalculateDigit:
            or cx, cx
            jz .End
            dec cx

            mov ax, bx
            mov dx, word 16
            mul dx

            mov dl, byte [si]
            xor dh, dh
            add ax, dx
            mov bx, ax

            inc si
            jmp .CalculateDigit
        
        .End:
            mov cx, bx
            pop di
            ret

    .InvalidChar:
        stc
        pop di
        ret


StringHexToIntBuffer: times 5 db 0