[bits 16]
[cpu 8086]

; https://wiki.osdev.org/PC_Speaker
; https://forum.osdev.org/viewtopic.php?f=13&t=17293



SoundIntHandler:
    or ah, ah
    jnz .StopSound
    call PlaySound
    jmp .Exit

    .StopSound:
        cmp ah, byte 1
        jne .Exit
        call StopSound

    .Exit:
        mov al, byte 0x20
        out 0x20, al
        iret


; Plays a sound with the given frequency
; Input:
;   bx = frequency divided by 1193180
PlaySound:
    push ax

    ; Reprogram PIT channel 2 to be a square wave generator 
    mov al, byte 0xb6
    out 0x43, al

    mov ax, bx
    out 0x42, al
    mov al, ah
    out 0x42, al

    ; Get the position of speaker from bit 1 of port 0x61 of keyboard controller
    in al, 0x61
    or al, 3
    out 0x61, al

    pop ax
    ret



StopSound:
    push ax

    in al, 0x61
    and al, 11111100b
    out 0x61, al

    pop ax
    ret
