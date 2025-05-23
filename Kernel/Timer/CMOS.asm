[bits 16]
[cpu 8086]



; I found out that I can use the RTC(Real Time Clock) to get system time and wait some seconds, instead of using the PIT, yay
; https://wiki.osdev.org/RTC
; https://wiki.osdev.org/CMOS
; https://wiki.osdev.org/NMI

; Also thanks to Joshua-Riek code from his repository x86-kernel
; https://github.com/Joshua-Riek/x86-kernel/blob/master/src/cmos.asm



CmosAddressPort equ 0x70
CmosDataPort equ 0x71

RtcCentury equ 0x32
RtcMonth equ 0x08
RtcDayOfMonth equ 0x07
RtcHours equ 0x04
RtcMinutes equ 0x02
RtcSeconds equ 0x00

NmiDisableBit equ 0x01
NmiEnableBit equ 0x00



; Read a CMOS register
; Input:
;   ah = CMOS address to read
; Output:
;   al = stuff you wanted to read
CmosRead:
    cli

    ; Disable NMI
    or ah, NmiDisableBit << 7 ; Bit 7
    mov al, ah
    out CmosAddressPort, al

    ; RTC expects a read/write after writing to port 0x70, soooo
    in al, CmosDataPort
    push ax

    ; Enable NMI
    mov al, NmiEnableBit << 7 ; Bit 7
    out CmosAddressPort, al

    pop ax
    sti

    ret



; Gets the system date from CMOS and stores the values into 3 variables
; Output:
;   bx = year
;   ah = month
;   al = day
CmosGetSystemDate:
    push cx

    ; For now we don't check if the century register is present or not, we assume it is
    ; I have no will-power to check at the moment

    ; Century
    mov ah, RtcCentury
    call CmosRead
    call BinaryToBcd

    xor ah, ah
    cmp al, byte 80 ; Checks if we are in the 1980s or 2000s
    jl .NextCentury

    ; 1980s
    add ax, word 1900 ; We aren't in 80 d.C.
    jmp .GetMonth

    .NextCentury:
        add ax, word 2005

    .GetMonth:
        mov bx, ax

        mov ah, RtcMonth
        call CmosRead
        call BinaryToBcd
        mov cl, al

        ; Day
        mov ah, RtcDayOfMonth
        call CmosRead
        call BinaryToBcd

        mov ah, cl ; Get the month back
        pop cx
        ret



; Gets system time and returns obtained values
; Output:
;   al = minutes
;   ah = hours
;   bl = seconds
CmosGetSystemTime:
    ; Hours
    mov ah, RtcHours
    call CmosRead
    call BinaryToBcd
    mov bl, al

    ; Minutes
    mov ah, RtcMinutes
    call CmosRead
    call BinaryToBcd

    mov ah, bl
    push ax

    ; Seconds
    mov ah, RtcSeconds
    call CmosRead
    call BinaryToBcd

    mov bl, al
    pop ax

    ret

