[org 0x7e00]
[bits 16]
[cpu 8086]

; I put this code here because the logo didn't fit in the boot sector

jmp SecondStage



SecondStage:
    ; call PrintLogo

    ; ; Waits 4 seconds
    ; mov cx, 0x2d
    ; mov dx, 0x4240
    ; mov ah, 0x86
    ; int 0x15

    ; Jumps to kernel!
    ; jmp 0x800:0x0
    jmp $




; *TRASH CODE WARNING! CONTINUE AT YOUR OWN RISK
PrintLogo:
    xor cx, cx

    .Loop:
        cmp cx, byte 6
        je .Logo

        call PrintNewLine

        inc cx
        jmp .Loop

    .Logo:
        ; You didn't listen to the warning, ah?
        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo
        call PrintString

        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo1
        call PrintString

        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo2
        call PrintString

        mov si, MascLogoSpace
        call PrintString

        mov si, MascLogo3
        call PrintString

        ; Welcome message
        mov si, WelcomeSpace
        call PrintString

        mov si, WelcomeMessage
        call PrintString

    ret



%include "./Bootloader/Print.asm"



; Don't kill me pls
MascLogoSpace: db "                    ", 0
MascLogo: db "  \  |                      _ \   ___|", 10, 13, 0
MascLogo1: db " |\/ |   _` |   __|   __|  |   |\___ \", 10, 13, 0
MascLogo2: db " |   |  (   | \__ \  (     |   |      |", 10, 13, 0
MascLogo3: db "_|  _| \__._| ____/ \___| \___/ _____/", 10, 13, 10, 13, 0
WelcomeSpace: db "                         ", 0
WelcomeMessage: db "Welcome to MascOS! Loading...", 0


; Fills the rest of the sector with 0s
times 512-($-$$) db 0