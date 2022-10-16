[bits 16]
[cpu 8086]


; *Parallel ports driver




; *NOTE: hasn't been tested
; Sends a byte to the printer connected to the first parallel port
; Input:
;   al = byte to send
ParallelSendToPrinter:
    push ax
    mov dx, word [ParallelPorts]
    inc dx ; Status register

    .WaitForPrinter:
        in al, dx
        and al, byte 0x80 ; Checks the BUSY bit
        
        test al, al
        jz .Send

        ; TODO: Wait 10 milliseconds...

        jmp .WaitForPrinter

    .Send:
        pop ax
        dec dx ; Data register

        out dx, al

        ; Now we need to tell the printer that it can read the byte we sent
        add dx, word 2 ; Control register
        in al, dx
        mov bl, al
        or al, byte 1 ; STROBE bit

        ; TODO: Wait 10 milliseconds...

        mov al, bl
        out dx, al
        dec dx ; Control register


    .WaitPrinter:
        in al, dx
        and al, byte 0x80 ; Checks the BUSY bit
        
        test al, al
        jz .End

        ; TODO: Wait 10 milliseconds...

        jmp .WaitPrinter

    .End:
        ret