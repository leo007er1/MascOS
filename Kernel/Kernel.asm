[org 0x0]
[bits 16]
[cpu 8086]


cli ; No interruptions please
jmp KernelMain


; External programs get here when they finish
ProgramEndPoint:
    call VgaClearScreen
    ; call ClearAttributesBuffer

    jmp GetCommand.AddNewDoubleLine




; Kernel files
%include "./Kernel/Screen/VGA.asm"
%include "./Kernel/Screen/VESA.asm"
%include "./Kernel/Shell.asm"
%include "./Kernel/Disk.asm"
%include "./Kernel/Timer/PIT.asm"
%include "./Kernel/IO/Sound.asm"
%include "./Kernel/IO/Serial.asm"
%include "./Kernel/IO/Parallel.asm"
%include "./Kernel/String.asm"
%include "./Kernel/IVT.asm"


LogoColor equ 0xe ; Yellow
BdaMemAddress equ 0x40 ; Divided by 16 because it will be moved to es



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

    cld ; Forward direction for string operations
    sti ; Now you can annoy me

    ; Masking interrupt 0x70 and 0x8 by setting bit 0 on I/O ports
    mov al, byte 1
    out 0x1a, al
    out 0x21, al

    ; Sets VGA 80x25
    xor ax, ax
    mov al, 3
    int 0x10

    call VgaInit
    call VgaClearScreen ; Need to update values

    call GetBdaInfo
    call SetNewInterrupts
    call InitSound
    call SerialInit
    ; call VesaInit
    
    call PrintLogo

    ; Waits 4 seconds
    mov cx, 0x2d
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    call VgaClearScreen


    ; --//  Actual useful stuff  \\--
    
    
    jmp InitShell

    cli
    hlt



; --//  Other labels  \\--



; Gets some useful information about the system from BDA(Bios Data Area)
; BDA is at address 0x400
GetBdaInfo:
    mov ax, word 0x40
    mov es, ax

    ; Get equipment word
    mov si, word 0x10
    mov ax, word [es:si]
    mov word [BiosEquipmentWord], ax

    ; Get I/O address of serial ports
    xor si, si
    mov ax, word [es:si]
    mov word [SerialPorts], ax
    mov ax, word [es:si + 2]
    mov word [SerialPorts + 2], ax
    mov ax, word [es:si + 4]
    mov word [SerialPorts + 4], ax

    ; Get I/O address of parallel ports
    mov si, word 8
    mov ax, word [es:si]
    mov word [ParallelPorts], ax
    mov ax, word [es:si + 2]
    mov word [ParallelPorts + 2], ax
    mov ax, word [es:si + 4]
    mov word [ParallelPorts + 4], ax

    ; Get the amount of KB before EBDA
    mov si, word 0x13
    mov ax, word [es:si]
    mov word [TotalMemory], ax

    mov ax, 0x7e0
    mov es, ax

    ret



; Macro to replace most of the PrintLogo bad code
; Input:
;   1 = string to print
%macro PrintLogoLine 1
    lea si, MascLogoSpace
    xor al, al
    call VgaPrintString

    mov si, %1
    mov al, LogoColor
    call VgaPrintString

    mov al, byte 1
    call VgaNewLine

%endmacro



; *TRASH CODE WARNING! CONTINUE AT YOUR OWN RISK
PrintLogo:
    xor cx, cx

    ; Padding to the top
    mov al, byte 6
    call VgaNewLine


    .Logo:
        ; Now it's way cleaner
        PrintLogoLine MascLogo
        PrintLogoLine MascLogo1
        PrintLogoLine MascLogo2
        PrintLogoLine MascLogo3

        ; Welcome message
        lea si, WelcomeSpace
        xor al, al
        call VgaPrintString

        lea si, WelcomeMessage
        xor al, al
        call VgaPrintString

        ret




TotalMemory: dw 0
BiosEquipmentWord: dw 0 ; Are there any serial, parallel ports and other stuff

; Ports info
ParallelPorts: times 3 dw 0
SerialPorts: times 3 dw 0

; Logo stuff
MascLogoSpace: db "                    ", 0
MascLogo: db "  \  |                      _ \   ___|", 0
MascLogo1: db " |\/ |   _` |   __|   __|  |   |\___ \", 0
MascLogo2: db " |   |  (   | \__ \  (     |   |      |", 0
MascLogo3: db "_|  _| \__._| ____/ \___| \___/ _____/", 0
WelcomeSpace: db 10, 13, "                         ", 0
WelcomeMessage: db "Welcome to MascOS! Loading...", 0