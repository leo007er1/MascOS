[bits 16]
[cpu 8086]

; ! DRUM ROOL.........
; * This is a hello world program for MascOS
; * Take it as an example to learn how to interact with the os interrupts


; Get colours
; mov ah, byte 8
; int 0x23
; mov word [NormalColour], bx ; Sets AccentColour too

; New line
mov ah, byte 2
mov al, byte 2
int 0x23

; Print "Hello world!"
mov ah, byte 0x9
; mov al, byte [AccentColour]
lea dx, string
int 0x21

; Exit program
int 0x20


string: db "Hello world!", 0
NormalColour: db 0
AccentColour: db 0