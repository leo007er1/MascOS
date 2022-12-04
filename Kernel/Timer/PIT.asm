[bits 16]
[cpu 8086]



; *Byte to insert in Mode/Command register at I/O port 0x43:
; Bits 7-6: channel             00
; Bits 5-4: access mode         11
; Bits 3-1: operating mode      011
; Bit 0: BCD or binary mode     0
;
; Which gives us: 00110110



; I don't understand anything about this

PitSoundReloadValue equ 27 ; Frequency: 44192
TimerCountdown: dw 0


InitPit:
    


    ret



InitPitSound:
    ; Tell the PIT how to behave via Mode/command register
    mov al, 10110110b ; Channel 2
    out 0x43, al

    ; We want a frequency of 44192Hz, so the reload value is 27, because 27 * 44192 = 1193184Hz
    mov ax, word PitSoundReloadValue
    out 0x42, al
    mov al, ah ; Hight byte
    out 0x42, al

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



; For sound
Irq0Isr:
    ; cmp al, 0x80
    ; jb StopSound

    mov al, byte 1
    out 0x61, al
    ; mov al, byte 0x20
    ; out 0x20, al

    iret