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
Irq0Offset equ 8 * 4


PitInit:
    cli ; We are doing other important stuff, ok?

    mov bx, word KernelSeg
    xor ax, ax
    mov es, ax

    mov word [Irq0Offset], Irq0Isr
    mov word [Irq0Offset + 2], bx

    mov es, bx

    sti
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
    mov al, byte 0x20
    out 0x20, al

    iret