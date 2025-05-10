[bits 16]
[cpu 8086]


; Converts a normal binary number into a Binary Coded Decimal value
; Input:
;   al = number to convert
; Output:
;   al = converted number
BinaryToBcd:
    push bx
    push dx
    push cx

    xor ah, ah
    push ax

    ; Get high BCD bits
    and ax, 0xf0
    mov cl, byte 4
    shr al, cl

    xor dx, dx
    mov bl, byte 10
    mul bl

    ; Get low BCD bits
    pop bx
    and bx, 0x0f

    add ax, bx

    pop cx
    pop dx
    pop bx

    ret



; Pseudo Random Number Generator(PRNG) following the Linear Feedback Shift Register Model(LFSR)
; Output:
;   dx = random number
; GetRandomNumber:
;     ; Get random seed from the CMOS clock(RTC)
;     mov ah, RtcHours
;     call CmosRead
;     call BinaryToBcd
;     mov bl, al

;     mov ah, RtcMinutes
;     call CmosRead
;     call BinaryToBcd
;     mov ah, bl

;     ; Seed mustn't be 0
;     or ax, ax
;     jz GetRandomNumber
;     mov bx, ax
;     mov cx, ax
;     xor dx, dx

;     .LFSR:
;         ; XOR some bits
;         xor bx >> 0, bx >> 2
;         xor bx >> 2, bx >> 3
;         xor bx >> 3, bx >> 5
;         inc bx

;         or cx >> 1, bx >> 15

;         inc dx

;         cmp cx, ax
;         je .LSFR


;     ret