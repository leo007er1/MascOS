[bits 16]
[cpu 8086]


; *APM driver
; Manages power to individual devices of the computer, also used to shutdown the computer

; *APM power states
; 1 = standby
; 2 = suspend
; 3 = off

; *Useful links:
; https://www.ctyme.com/intr/rb-1394.htm
; https://wiki.osdev.org/APM



ApmInit:
    ; Installation check
    mov ah, byte 0x53
    xor al, al
    xor bx, bx ; Devide Id. 0 is BIOS
    int 0x15
    jc .ApmError

    ; If APM version is 1.1+ we are all good
    cmp al, byte 1
    jnl .ConnectInterface
    call .OldVersion

    .ConnectInterface:
        mov byte [ApmMinorVersion], al

        ; Connect to Real Mode interface
        mov ah, byte 0x53
        mov al, byte 1
        xor bx, bx
        int 0x15
        jnc .GetDriverVer
        call .ApmError

    .GetDriverVer:
        ; Get driver version
        ; We want APM 1.1+ since with version 1.0 we can't shutdown the computer
        mov ah, byte 0x53
        mov al, byte 0xe
        xor bx, bx
        mov ch, byte 1 ; Major driver version in BCD format
        mov cl, byte 1 ; Minor driver version in BCD format
        int 0x15
        jnc .EnablePower
        call .ApmError

    .EnablePower:
        ; Enables APM power management for all devices
        mov ah, byte 0x53
        mov al, byte 0x8
        mov bx, 1 ; All devices
        mov cx, 1 ; State, 1 = on
        int 0x15
        jc .ApmError

        ret


    .OldVersion:
        lea si, ApmOldVerMessage
        mov al, byte 0xc ; Red
        call VgaPrintString

        ret

    .ApmError:
        lea si, ApmGeneralError
        mov al, byte 0xc ; Red
        call VgaPrintString

        mov byte [ApmErrorByte], 1

        ret


; Sets the power state of all devices to off
ApmSystemShutdown:
    cmp byte [ApmErrorByte], byte 1
    jge .NoShutdown

    cmp byte [ApmMinorVersion], byte 1
    jl .NoShutdown

    mov ah, byte 0x53
    mov al, byte 0x7
    mov bx, 1 ; All devices
    mov cx, 3 ; Off
    int 0x15
    jc .Error

    ret

    .NoShutdown:
        lea si, ApmShutdownError
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

        ret

    .Error:
        cli
        hlt


ApmStandby:
    cmp byte [ApmErrorByte], byte 1
    jge .NoStandby

    cmp byte [ApmMinorVersion], byte 1
    jl .NoStandby

    mov ah, byte 0x53
    mov al, byte 0x7
    mov bx, 1 ; All devices
    mov cx, 1 ; Standby
    int 0x15
    jc ApmSystemShutdown.Error

    ret

    .NoStandby:
        lea si, ApmShutdownError
        mov al, byte [AccentColour]
        and al, 0xfc ; Red
        call VgaPrintString

        ret

ApmGeneralError: db 10, 13, "APM error while running ApmInit", 0
ApmOldVerMessage: db "Old APM version: v1.0", 0
ApmShutdownError: db 10, 13, "Can't shutdown computer: APM version 1.0 or ApmInit error", 0
ApmErrorByte: db 0
ApmMinorVersion: db 0