[org 0x7c00]
[bits 16]


; Skips the includes
jmp Start

%include "./Bootloader/Print.asm"
%include "./Bootloader/Disk.asm"
%include "./Bootloader/Memory.asm"


; Some BIOSes jump to the boot sector with 0x07c0:0x0000 or 0x0000:0x7c00 and other ways so we set CS to 0
Start:
    cli
    jmp 0x0000:Main
    nop


Main:
    ; Saves the number of the drive where we currently are
    mov [BootDisk], dl

    ; Segments setup
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Stack setup
    mov ss, ax
    mov sp, 0x7c00

    sti

    call GetMemoryAvaiable
    call ReadDisk

    ; Clears the screen
    mov ah, 0
    mov al, 3
    int 0x10

    call PrintLogo

    ; Waits 4 seconds
    mov cx, 0x2d
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    ; Jumps to kernel
    jmp 0x100:0x0



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




; Don't kill me pls
MascLogoSpace: db "                    ", 0
MascLogo: db "  \  |                      _ \   ___|", 10, 13, 0
MascLogo1: db " |\/ |   _` |   __|   __|  |   |\___ \", 10, 13, 0
MascLogo2: db " |   |  (   | \__ \  (     |   |      |", 10, 13, 0
MascLogo3: db "_|  _| \__._| ____/ \___| \___/ _____/", 10, 13, 10, 13, 0
WelcomeSpace: db "                         ", 0
WelcomeMessage: db "Welcome to MascOS! Loading...", 0


; Fills the rest of the sector with 0s and boot signature
times 510-($-$$) db 0
dw 0xaa55