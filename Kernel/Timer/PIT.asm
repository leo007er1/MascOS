[bits 16]
[cpu 8086]



; *Byte to insert in Mode/Command register at I/O port 0x43:
; Bits 7-6: channel             00
; Bits 5-4: access mode         11
; Bits 3-1: operating mode      010
; Bit 0: BCD or binary mode     0
;
; Which gives us: 00110100



; I don't understand anything about this

PitSoundReloadValue equ 27 ; Frequency: 44192
TimerCountdown: dw 0


InitPit:
    


    ret



InitPitSound:
    mov al, 00110100b
    out 0x43, al

    mov ax, word PitSoundReloadValue
    out 0x40, al
    mov al, ah
    out 0x40, al

    ret



; Waits the specified time of milliseconds
; Input:
;   ax = milliseconds to wait
TimerWait:
    mov word [TimerCountdown], ax

    cmp ax, word 0
    jbe .Exit

    ; TODO: Implement this function

    .Exit:
        ret



IrqTimer:
    push ax

    mov ax, word [TimerCountdown]
    test ax, ax
    jz .Exit

    dec ax
    mov word [TimerCountdown], ax

    .Exit:
        iret


; For sound
Irq0Isr:
    ; cmp al, 0x80
    ; jb StopSound

    mov al, byte 0x20
    out 0x20, al

    iret