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


com1 equ 0x3f8



; Sets baud rate divisor and checks if the serial port is good or not good
; * DAD, THIS CODE DOESN'T WORK AAAA
; Output:
;   ah = 0 for success, 1 for faulty port, 2 for no serial ports avaiable
SerialInit:
    ; Is there a serial port?
    mov ah, byte [BiosEquipmentWord + 1]
    test ah, ah
    jz .NoPort

    ; Sets baud rate divisor to the controller
    ; 115200 / 3 = 38400 baud
    xor al, al
    out com1 + 1, al ; Disable interrupts

    mov al, byte 0x80
    out com1 + 3, al ; Tell Line control register to enable DLAB bit

    mov al, byte 3 ; Divisor
    out com1, al ; Divisor low byte
    xor al, al
    out com1 + 1, al ; Divisor hight byte

    ; Set data bits
    mov al, byte 3
    out com1 + 3, al ; 8 bits, one stop bit, no parity

    ; Enable FIFO control registers
    mov al, byte 0xc7
    out com1 + 2, al

    ; Mess with modem control register
    mov al, byte 0xb ; Set RTS, DSR and hardware pin out 2, which enables IRQ
    out com1 + 4, al
    mov al, byte 0x1e
    out com1 + 4, al ; Sets loopback mode to test UART?

    ; Test serial chip by sending a byte and checking the returned one
    mov al, byte 0xae
    out com1, al

    ; Is it the same George?
    in al, com1
    cmp al, byte 0xae
    jne .Different

    ; Disables loopback mode with both out pins being used and IRQ
    mov al, byte 0x0f
    out com1 + 4, al
    xor ah, ah
    ret

    .Different:
        mov ah, byte 1
        ret

    .NoPort:
        mov ah, byte 2
        ret


; Gets a value from serial port when receives signal
; Output:
;   al = value from serial port
SerialRead:
    ; This loop is boring if we are waiting, right?
    .CheckReceived:
        in al, com1 + 5
        and al, byte 1 ; Is there data that can be read?
        
        test al, al
        jnz .CheckReceived

    ; Wait there's data?!?!!??
    in al, com1
    ret



; Writes to a serial port
; Input:
;   al = value to send
SerialWrite:
    push ax

    ; Be annoyed in this loop while the transmit is doing stuff
    .CheckTransmit:
        in al, com1 + 5
        and al, byte 0x20

        test al, al
        jnz .CheckTransmit

    ; Yay the transmitter isn't doing anything
    pop ax
    out com1, al ; Send the byte

    ret

