[bits 16]
[cpu 8086]




; *Serial ports driver

; *COM ports list
; * NOTE: ports can have different I/O ports, check BDA for port address
;
; | Port | I/O port |
;   COM1 |  0x3F8
;   COM2 |	0x2F8
;   COM3 |  0x3E8
;   COM4 |  0x2E8
;   COM5 |  0x5F8
;   COM6 |  0x4F8
;   COM7 |  0x5E8
;   COM8 |  0x4E8 




; Sets baud rate divisor and checks if the serial port is good or not good
; DAD, THIS CODE DOESN'T WORK AAAA
; Output:
;   ah = 0 for success, 1 for faulty port, 2 for no serial ports avaiable
SerialInit:
    ; Is there a serial port?
    mov ah, byte [BiosEquipmentWord + 1]
    test ah, ah
    jz .NoPort

    mov dx, word [SerialPorts] ; COM1

    ; Sets baud rate divisor to the controller
    ; 115200 / 3 = 38400 baud
    inc dx
    xor al, al
    out dx, al ; Disable interrupts

    add dx, word 2
    mov al, byte 0x80
    out dx, al ; Tell Line control register to enable DLAB bit

    sub dx, word 3
    mov al, byte 3 ; Divisor
    out dx, al ; Divisor low byte

    inc dx
    xor al, al
    out dx, al ; Divisor hight byte

    ; Set data bits
    add dx, word 2
    mov al, byte 3
    out dx, al ; 8 bits, one stop bit, no parity

    ; Enable FIFO control registers
    dec dx
    mov al, byte 0xc7
    out dx, al

    ; Mess with modem control register
    add dx, word 2
    mov al, byte 0xb ; Set RTS, DSR and hardware pin out 2, which enables IRQ
    out dx, al

    mov al, byte 0x1e
    out dx, al ; Sets loopback mode to test UART?

    ; Test serial chip by sending a byte and checking the returned one
    sub dx, word 4
    mov al, byte 0xae

    ; Is it the same George?
    in al, dx
    cmp al, byte 0xae
    jne .Error

    ; Disables loopback mode with both out pins being used and IRQ
    add dx, word 4
    mov al, byte 0x0f
    out dx, al

    xor ah, ah
    ret

    .Error:
        mov ah, byte 1
        ret

    .NoPort:
        mov ah, byte 2
        ret


; Gets a value from serial port when receives signal
; Output:
;   al = value from serial port
SerialIn:
    .CheckReceived:
        call SerialCheckReceived
        test al, al
        jnz .CheckReceived

    mov dx, word 0x3f8
    in al, dx

    ret


; Writes to a serial port
SerialOut:
    push ax

    .CheckTransmit:
        call SerialCheckTransmit
        test al, al
        jnz .CheckTransmit

    pop ax
    mov dx, word 0x3f8
    out dx, al

    ret



; Checks serial port for receive signal
; Output:
;   al = receive signal
SerialCheckReceived:
    mov dx, word 0x3f8
    add dx, word 5

    in al, dx
    and al, byte 1

    ret



; Checks if the transmit status is clear or not
; Output:
;   al = value Line status register
SerialCheckTransmit:
    mov dx, word 0x3f8
    add dx, word 5

    in al, dx
    and al, byte 0x20

    ret