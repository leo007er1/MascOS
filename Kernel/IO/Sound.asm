[bits 16]
[cpu 8086]

; https://wiki.osdev.org/PC_Speaker
; https://forum.osdev.org/viewtopic.php?f=13&t=17293


PitIrqOffset equ 0x20 ; Offset in IVT


; Sets IRQ0 to our code
InitSound:
    cli

    xor ax, ax
    mov es, ax
    mov bx, word KernelSeg

    mov word [es:PitIrqOffset], Irq0Isr
    mov word [es:PitIrqOffset + 2], bx

    mov es, bx

    ; call InitPitSound

    sti
    ret


; Plays a sound with the given frequency
; Input:
;   bx = frequency divided by 1193180
PlaySound:
    mov ax, 0x34dd
    mov dx, 0x0012
    cmp dx, bx
    jnc .End

    div bx
    mov bx, ax
    
    ; Get the position of speaker from bit 1 of port 0x61 of keyboard controller
    in al, 0x61
    test al, byte 3
    jnz .a99

    or al, 3
    out 0x61, al
    
    ; Reprogram PIT channel 2 to be a square wave generator 
    mov al, byte 0xb6
    out 0x43, al

    .a99:
        mov al, bl
        out 0x42, al
        mov al, bh
        out 0x42, al

    .End:
        ret



StopSound:
    in al, 0x61
    and al, 11111100b
    out 0x61, al

    ret
