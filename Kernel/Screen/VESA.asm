[bits 16]
[cpu 8086]

; *NOTE
; * For now we don't support VESA 2.0, only VESA 1.x
; I know I shouldn't assume video modes but for now i just use video mode 0x100, I will check if it supported in the future


; *Video mode used
; * 0x100, which is 640x400, 256 colours and 1 byte per pixel
;   0   1   0000100000000
;  DM  LFB   Mode number
;
; DM bit tells the BIOS to not clear the screen, should always be 0
; LFB bit set if we use a linear framebuffer, clear to use bank switching

; * Framebuffer pointer is fd00, seems reasonable

; *Useful links:
; https://www.ctyme.com/intr/rb-0273.htm
; https://www.ctyme.com/intr/rb-0274.htm
; https://www.ctyme.com/intr/rb-0275.htm



; Gets VESA information from BIOS and stores it into a buffer
; ES:DI is the buffer
VesaInit:
    lea di, VesaInfo
    mov ax, 0x4f00
    int 0x10

    call CheckVesaError

    ; Gets information about specified VESA video mode afrom BIOS and sets it into VesaModeInfo
    ; Sets VesaVideoPointer to the framebuffer pointer
    .GetVesaModeInfo:
        mov ax, 0x4f01
        lea di, VesaModeInfo
        mov cx, 0x100 ; 640x400 with 256 colours. 1 byte per pixel
        int 0x10

        call CheckVesaError

        ; Get the framebuffer pointer
        lea si, VesaModeInfo
        lea di, VesaVideoPointer
        add si, 0x28 ; VesaModeInfo + 40 is the position of the framebuffer pointer

        lodsw
        mov [di], ax
        add di, 2

        lodsw
        mov [di], ax

    ; Sets a VESA video mode with BIOS
    .SetVesaMode:
        mov ax, 0x4f02
        mov bx, 0x2100 ; Video mode and DM and LFB bits
        int 0x10

        call CheckVesaError

        ret



CheckVesaError:
    ; If al = 0x4f then function is supported
    cmp al, byte 0x4f
    jne .Error

    ; Status
    cmp ah, byte 0
    jne .Error

    .Exit:
        ret

    .Error:
        cli
        hlt




; -- //  Cool code here  \\ --



VesaPutPixel:
    mov si, VesaVideoPointer
    mov ax, [si + 2] ; Get the offset
    mov cl, 4
    shr ax, cl
    mov es, ax

    xor bx, bx
    mov cl, 64

    .loop:
        test cl, cl
        jz .Exit

        mov byte [es:bx], 0x6060
        add bx, 2

        dec cl
        jmp .loop
        

    .Exit:
        cli
        hlt

        ret




VesaVideoPointer: dq 0

; How much space do you want VESA??

VesaInfo:
    .Signature: db "VESA"
    .Data: times 252 db 0

VesaModeInfo: times 256 db 0