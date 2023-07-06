[bits 16]
[cpu 8086]

; *Byte to insert in Mode/Command register at I/O port 0x43:
; Bits 7-6: channel             00
; Bits 5-4: access mode         11
; Bits 3-1: operating mode      011
; Bit 0: BCD or binary mode     0
;
; Which gives us: 00110110

; https://wiki.osdev.org/Pit
; I don't understand anything about this

PitSoundReloadValue equ 27 ; Frequency: 44192
TimerCountdown: dw 0
Irq0PlaySound: db 0


InitPitSound:
    ; ; Reprogram channel 2 to be a square wave generator 
    ; mov al, 0xb6 ; Channel 2
    ; out 0x43, al

    ; ; We want a frequency of 44192Hz, so the reload value is 27, because 27 * 44192 = 1193184Hz
    ; mov ax, word PitSoundReloadValue
    ; out 0x42, al
    ; mov al, ah ; Hight byte
    ; out 0x42, al

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


Irq0Isr:
    cmp byte [Irq0PlaySound], 1
    jne .Exit

    mov bx, 0x1000
    call PlaySound

    .Exit:
        ; Send EOI to the PIC
        mov al, 0x20
        out 0x20, al

        iret