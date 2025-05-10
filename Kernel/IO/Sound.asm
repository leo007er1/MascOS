[bits 16]
[cpu 8086]

; https://wiki.osdev.org/PC_Speaker
; https://forum.osdev.org/viewtopic.php?f=13&t=17293



SoundIntHandler:
    or ah, ah
    jnz .PlayTrack
    call PlaySound
    jmp .Exit

    .PlayTrack:
        cmp ah, byte 1
        jne .StopSound
        call PlayTrack
        jmp .Exit

    .StopSound:
        cmp ah, byte 2
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

    ; Waits a few milliseconds
    xor cx, cx
    mov dx, 20000
    mov ah, 0x98
    int 0x15

    ; Stop sound
    in al, 0x61
    and al, 11111100b
    out 0x61, al

    pop ax
    ret


; Plays a sound with the given frequency
; Input:
;   ds:si = pointer to null-terminated track
PlayTrack:
    push ax
    push bx
    push cx
    push dx
    push si

    ; Reprogram PIT channel 2 to be a square wave generator 
    mov al, byte 0xb6
    out 0x43, al

    .NextFrequency:
        lodsw ; Get next frequency

        or ax, ax
        jz .End

        out 0x42, al
        mov al, ah
        out 0x42, al

        ; Get the position of speaker from bit 1 of port 0x61 of keyboard controller
        in al, 0x61
        or al, 3
        out 0x61, al

        mov cx, 0x1
        mov dx, 0x3000
        mov ah, 0x86
        int 0x15

        jmp .NextFrequency


    .End:
        in al, 0x61
        and al, 11111100b
        out 0x61, al

        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret



StopSound:
    push ax

    in al, 0x61
    and al, 11111100b
    out 0x61, al

    pop ax
    ret
