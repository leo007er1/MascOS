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

    mov dx, word [SerialPorts] ; COM1
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

    ; mov al, byte 0x1e
    ; out dx, al ; Sets loopback mode to test UART?

    ; ; Test serial chip by sending a byte and checking the returned one
    ; sub dx, word 4
    ; mov al, byte 0xae

    ; ; Is it the same George?
    ; in al, dx
    ; cmp al, byte 0xae
    ; jne .Error

    ; ; Disables loopback mode with both out pins being used and IRQ
    ; add dx, word 4
    ; mov al, byte 0x0f
    ; out dx, al

    ; xor ah, ah
    ret

    ; .Error:
    ;     mov ah, byte 1
    ;     ret

    .NoPort:
        mov ah, byte 2
        ret


; Gets a value from serial port when receives signal
; Output:
;   al = value from serial port
SerialRead:
    push dx
    mov dx, word [SerialPorts] ; COM 1
    add dx, word 5

    ; This loop is boring if we are waiting, right?
    .CheckReceived:
        in al, dx
        and al, byte 1 ; Is there data that can be read?
        
        test al, al
        jnz .CheckReceived

    ; Wait there's data?!?!!??
    sub dx, word 5
    in al, dx

    pop dx
    ret



; Writes to a serial port
; Input:
;   al = value to send
SerialWrite:
    push dx
    push ax

    mov dx, word [SerialPorts] ; COM 1
    add dx, word 5

    ; Be annoyed in this loop while the transmit is doing stuff
    .CheckTransmit:
        in al, dx
        and al, byte 0x20

        test al, al
        jnz .CheckTransmit

    ; Yay the transmitter isn't doing anything
    pop ax
    sub dx, word 5
    out dx, al ; Send the byte

    pop dx
    ret

