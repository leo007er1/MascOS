[bits 16]
[cpu 286]

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
    push es
    mov di, VesaInfo.Data
    mov ax, 0x4f00
    int 0x10
    pop es

    ; If al = 0x4f then function is supported
    cmp al, 0x4f
    jne .Error

    ; Status
    cmp ah, 0
    je .Exit

    .Error:
        mov si, .VesaInfoError
        call PrintString

    .Exit:
        mov ax, 0xe
        mov gs, word [VesaInfo.Data + ax]
        add ax, 2
        mov bx, word [VesaInfo.Data + ax]

        ret



GetVesaModeInfo:



    ret


.VesaInfoError: db 10, 13, "VESA error", 0

; How much space do you want VESA??

VesaInfo:
    .Signature: db "VESA"
    .Data: resb 512 - 4

VesaModeInfo: resb 256