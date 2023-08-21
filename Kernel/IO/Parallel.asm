[bits 16]
[cpu 8086]


; *Parallel ports driver



; *NOTE: hasn't been tested
; Sends a byte to device connected to the first parallel port
; Input:
;   al = byte to send
ParallelSendByte:
    push ax

    xor cx, cx
    mov dx, word [ParallelPorts]
    inc dx ; Status register

    .WaitForDevice:
        in al, dx
        and al, byte 0x80 ; Checks the BUSY bit
        
        or al, al
        jz .Send

        ; Wait 10 milliseconds
        push dx
        mov dx, 0x2710 ; 10000 microseconds aka 10 milliseconds
        mov ah, byte 0x86
        int 0x15
        pop dx

        jmp .WaitForDevice

    .Send:
        pop ax
        dec dx ; Data register
        out dx, al

        ; Pulse STROBE line. Tells the device to read the byte we sent
        add dx, word 2 ; Control register
        in al, dx
        mov bl, al
        or al, 1 ; STROBE bit

        ; Wait 10 milliseconds
        push dx
        mov dx, 0x2710
        mov ah, byte 0x86
        int 0x15
        pop dx

        mov al, bl
        out dx, al
        dec dx ; Control register
        xor cx, cx

    .WaitDevice:
        in al, dx
        and al, byte 0x80 ; Checks the BUSY bit
        
        or al, al
        jz .End

        ; Wait 10 milliseconds
        push dx
        mov dx, 0x2710 ; 10000 microseconds aka 10 milliseconds
        mov ah, byte 0x86
        int 0x15
        pop dx

        jmp .WaitDevice

    .End:
        ret