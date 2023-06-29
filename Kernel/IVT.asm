[bits 16]
[cpu 8086]


; *This file creates custom interrupts in the IVT

; *IVT structure
; It starts at 0x0:0x0 and goes to 0x0:0x400.
; The values before 0x0:0x80 are some reserved and some we don't care about, we are gonna leave them untouched.
; Every "interrupt" is 4 bytes.
;
;* Offset       |  Int         |  Description
;  0x0 - 0x78   |  0x0 - 0x1f  |  Stuff, look online for more details
;  0x80 - 0x400 |  0x1f - 0xff |  Interrupts we can set



; Sets the os own interrupts into the IVT
SetNewInterrupts:
    cli ; Yeah, we are doing important stuff, ok?

    xor ax, ax
    mov es, ax
    mov cx, 4 ; Number of Ints
    mov bx, word 0x80 ; Offset for the IVT
    lea si, IntTable

    .Loop:
        lodsw ; Get the offset for the interrupt

        mov word [es:bx], ax
        add bx, word 2

        ; Base
        mov word [es:bx], word KernelSeg
        add bx, word 2

        loop .Loop


    mov ax, KernelSeg
    mov es, ax
    sti

    ret



IntTable:
    dw ProgramEndPoint ; Int 0x20
    dw DosInt21 ; Int 0x21
    dw DiskIntHandler ; Int 0x22
    dw VgaIntHandler ; Int 0x23