[bits 16]
[cpu 8086]

; *Serial ports driver
; * NOTE: ports can have different I/O ports, check BDA for port address


COM1 equ 0x3f8
COM2 equ 0x2f8
COM3 equ 0x3e8


; Sets baud rate divisor and checks if the serial port is good or not good
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
    out COM1 + 1, al ; Disable interrupts

    mov al, byte 0x80
    out COM1 + 3, al ; Tell Line control register to enable DLAB bit

    mov al, byte 3
    out COM1, al; Divisor low byte

    xor al, al
    out COM1 + 1, al ; Divisor hight byte

    ; Set data bits
    mov al, byte 3
    out COM1 + 3, al ; 8 bits, one stop bit, no parity

    ; Enable FIFO control registers
    mov al, byte 0xc7
    out COM1 + 2, al

    ; Mess with modem control register
    mov al, byte 0xb ; Set RTS, DSR and hardware pin out 2, which enables IRQ
    out COM1 + 4, al

    mov al, byte 0x1e
    out COM1 + 4, al ; Sets loopback mode to test UART?

    ; Test serial chip by sending a byte and checking the returned one
    mov al, byte 0xae
    out COM1, al

    in al, COM1
    cmp al, byte 0xae
    je .SameByte

    mov ah, byte 1
    ret

    ; Disables loopback mode with both out pins being used and IRQ
    .SameByte:
        mov al, byte 0x0f
        out COM1 + 4, al
        xor ah, ah
        ret

    .NoPort:
        cli
        hlt

        mov ah, byte 2
        ret


; Gets a value from serial port when receives signal
; Output:
;   al = value from serial port
SerialRead:
    .CheckReceived:
        in al, COM1 + 5
        and al, byte 1 ; Is there data that can be read?
        
        or al, al
        jz .CheckReceived


    in al, COM1
    ret



; Writes to a serial port
; Input:
;   al = value to send
SerialWrite:
    push ax

    .CheckTransmit:
        in al, COM1 + 5 ; Check the Line Control Register
        and al, byte 0x20

        or al, al
        jz .CheckTransmit

    ; Uh the transmitter isn't doing anything
    pop ax
    out COM1, al ; Send the byte

    ret

