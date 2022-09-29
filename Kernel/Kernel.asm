[org 0x0]
[bits 16]
[cpu 8086]


cli ; No interruptions please
jmp KernelMain


; External programs get here when they finish
ProgramEndPoint:
    mov ax, 0x7e0
    mov ds, ax
    mov es, ax

    call VgaClearScreen
    ; call ClearAttributesBuffer

    jmp GetCommand.AddNewDoubleLine




; Kernel files
%include "./Kernel/Screen/VGA.asm"
%include "./Kernel/Screen/VESA.asm"
%include "./Kernel/Shell.asm"
%include "./Kernel/Disk.asm"
%include "./Kernel/String.asm"


LogoColor equ 0xe ; Yellow



KernelMain:
    ; Sets the segment again, so they won't error anything
    ; *THIS IS WHY Disk.asm DIDN'T FREAKING WORK.....
    mov ax, 0x7e0 ; Set every segment to where we are
    mov ds, ax
    mov es, ax
    ; mov fs, ax
    ; mov gs, ax

    ; Sets a 4KB stack below the boot sector
    mov ax, 0x687b
    mov ss, ax
    mov sp, 0x7bff

    ; Save the disk number
    mov byte [BootDisk], dl
    mov word [TotalMemory], cx

    cld ; Forward direction for string operations
    sti ; Now you can annoy me

    ; Masking interrupt 0x70 and 0x8 by setting bit 0 on I/O ports
    mov al, 1
    out 0x1a, al
    out 0x21, al

    call GetVesaInfo

    ; Sets VGA 80x25
    xor ax, ax
    mov al, 3
    int 0x10

    call VgaInit
    call VgaClearScreen ; Need to update values

    
    call PrintLogo

    ; Waits 4 seconds
    mov cx, 0x2d
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    call GetBdaInfo

    call VgaClearScreen


    ; --//  Actual useful stuff  \\--
    
    
    jmp InitShell

    cli
    hlt



; --//  Other labels  \\--



; Gets some useful information about the system fron BDA(Bios Data Area)
; BDA is at address 0x400. We will use this to determine if to use VGA or VESA
GetBdaInfo:
    ; The 0x89 byte contains VGA flags(also 0x8A)
    add byte [BdaMemAddress], 0x89
    mov bx, [BdaMemAddress]

    ; Bit 3 tells us if it's monocrome or colored
    test bx, 4
    jz .ColorVga

    .ColorVga:
        mov byte [SystemInfoByte], 1


    ret



; Macro to replace most of the PrintLogo bad code
; Input:
;   1 = string to print
%macro PrintLogoLine 1
    mov si, MascLogoSpace
    xor ah, ah
    call VgaPrintString

    mov si, %1
    mov ah, LogoColor
    call VgaPrintString

    mov al, 1
    call VgaNewLine

%endmacro



; *TRASH CODE WARNING! CONTINUE AT YOUR OWN RISK
PrintLogo:
    xor cx, cx

    ; Padding to the top
    mov al, 6
    call VgaNewLine


    .Logo:
        ; Now it's way cleaner
        PrintLogoLine MascLogo
        PrintLogoLine MascLogo1
        PrintLogoLine MascLogo2
        PrintLogoLine MascLogo3

        ; Welcome message
        mov si, WelcomeSpace
        xor ah, ah
        call VgaPrintString

        mov si, WelcomeMessage
        xor ah, ah
        call VgaPrintString

        ret




BdaMemAddress: db 0x400
SystemInfoByte: db 0
TotalMemory: dw 0

; Logo stuff
MascLogoSpace: db "                    ", 0
MascLogo: db "  \  |                      _ \   ___|", 0
MascLogo1: db " |\/ |   _` |   __|   __|  |   |\___ \", 0
MascLogo2: db " |   |  (   | \__ \  (     |   |      |", 0
MascLogo3: db "_|  _| \__._| ____/ \___| \___/ _____/", 0
WelcomeSpace: db 10, 13, "                         ", 0
WelcomeMessage: db "Welcome to MascOS! Loading...", 0