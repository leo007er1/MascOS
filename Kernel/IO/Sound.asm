[bits 16]
[cpu 8086]


; *How we split 1193180 into dx:ax
; x = 1193180
; a = 1193  b = 180
;
; x = 16a + b
; -16a = -x + b
; 16a = x - b
; a = (x - b) / 16
; b = x - 16a
;
; Result:
; a = 74562   We ignore the decimal values
; b = 188


; *Byte to insert in Mode/Command register at I/O port 0x43:
; Bits 7-6: channel 2           10
; Bits 5-4: both bytes          11
; Bits 3-1: square wave gen     011
; Bit 0: binary mode            0
;
; Which gives us: 10110110


PitIrqOffset equ 0x20 ; Offset in IVT



; Sets IRQ0 to our code
InitSound:
    cli

    xor ax, ax
    mov es, ax
    mov bx, word 0x7e0

    mov word [es:PitIrqOffset], Irq0Isr
    mov word [es:PitIrqOffset + 2], bx

    mov es, bx

    call InitPitSound

    sti
    ret


; Plays a sound with the given frequency
; Input:
;   ax = frequency
PlaySound:
    push ax

    ; mov dx, word 74562 ; a
    ; mov ax, word 188 ; b
    ; ; BX already set
    ; div word bx

    ; Give the PIT the "stuff"
    mov al, byte ModeCommandRegisterByte
    out 0x43, al
    pop ax

    out 0x42, al
    xchg al, ah
    out 0x42, al

    ; Get the position of speaker from bit 1 of port 0x61 of keyboard controller
    in al, 0x61
    mov dl, al
    or dl, byte 3

    cmp al, dl
    jne .Different

    out 0x61, al
    jmp .End

    .Different:
        mov al, dl
        out 0x61, al

    .End:
        ret



StopSound:
    in al, 0x61
    and al, 0xfc

    out 0x61, al

    ret


ModeCommandRegisterByte: db 10110110b