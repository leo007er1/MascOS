[bits 16]
[cpu 8086]

; *NOTE
; * For now we don't support VESA 2.0

; *Useful links:
; https://www.ctyme.com/intr/rb-0273.htm
; https://www.ctyme.com/intr/rb-0274.htm
; https://www.ctyme.com/intr/rb-0275.htm



; Gets VESA information from BIOS and stores it into a buffer
; ES:DI is the buffer
; Output:
;   
GetVesaInfo:
    mov di, VesaInfo.Data
    mov ax, 0x4f00
    int 0x10

    ; If al = 0x4f then function is supported
    cmp al, byte 0x4f
    jne .Error

    ; Status
    cmp ah, byte 0
    je .Exit

    .Error:
        ret

    .Exit:
        mov ax, 0xe

        ret



GetVesaModeInfo:



    ret


.VesaInfoError: db 10, 13, "VESA error", 0

; How much space do you want VESA??

VesaInfo:
    .Signature: db "VESA"
    .Data: times 508 db 0

VesaModeInfo: times 256 db 0