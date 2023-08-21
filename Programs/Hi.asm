[bits 16]
[org 0x100]
[cpu 8086]

; ! DRUM ROOL.........
; * This is a hello world program for MascOS
; * Take it as an example to learn how to interact with the os interrupts


; Print "Hello world!"
mov ah, byte 0x9
lea dx, string
int 0x21

; Exit program
int 0x20


string: db "Hello world!", 0