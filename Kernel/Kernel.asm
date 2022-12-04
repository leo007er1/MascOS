[org 0x0]
[bits 16]
[cpu 8086]


cli ; No interruptions please
jmp KernelMain



LogoColor equ 0xe ; Yellow
BdaMemAddress equ 0x40 ; Divided by 16 because it will be moved to es



KernelMain:
    ; Sets the segment again, so they won't error anything
    ; *THIS IS WHY Disk.asm DIDN'T FREAKING WORK.....
    mov ax, word KernelSeg ; Set every segment to where we are
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
    call ApmInit
    ; call VesaInit
    
    call PrintLogo

    ; Waits cx:dx microseconds
    mov cx, 0x19
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    call VgaClearScreen


    ; --//  Actual useful stuff  \\--
    
    
    jmp InitShell

    ; If you get here you are a dumb guy, shell did some strange stuff
    cli
    hlt



; --//  Other labels  \\--


; Loads a program and jumps to it in memory
; Input:
;   si = pointer to file name, must be 11 characters with the last 3 being the extension
; Output:
;   ! If operation fails it will return
;   carry flag = set
LoadProgram:
    push cx
    push dx

    call SearchFile
    jc .NoSendBadValues

    ; We need to know how CHUNCKY it is
    mov bx, cx ; Cx is contains the pointer to entry in root directory
    call GetFileSize

    ; If ax = 0, the file is smaller than a KB, so add 1 to ax
    test ax, ax
    jnz .LoadIt

    inc ax

    .LoadIt:
        ; xor dx, dx
        ; mov bx, word 1024 ; If you have alzheimer 1024 bytes is a KB. What did I just say? Do I even exist?
        ; mul bx

        ; push ax

        ; mov di, cx ; Get back the pointer to the entry
        ; mov bx, word [ProgramOffset] ; Offset
        ; call LoadFile
        
        ; ; Bx / 16
        ; xor dx, dx
        ; xchg ax, bx
        ; mov bx, word 16
        ; div bx

        ; add ax, ProgramBaseOffset

        ; ; Don't forget to
        ; pop bx
        ; add word [ProgramOffset], bx

        ; ; Now we got the value to set cs, ds, es to
        ; xor bx, bx
        ; mov ds, ax
        ; mov es, ax

        ; pop dx
        ; pop cx

        ; ; Far jump to program
        ; push ax
        ; push bx
        ; retf

        ; ---------------------------------------

        ; How many sectors my dear?
        ; x * 1024 / 512 = x * 2
        ; xor dx, dx
        ; mov bx, word 2
        ; mul bx

        ; push ax

        mov bx, word ProgramSeg
        mov es, bx
        mov di, cx ; Get back the pointer to the entry
        xor bx, bx ; Offset
        call LoadFile

        mov ax, word ProgramSeg
        mov ds, ax
        mov es, ax
        xor bx, bx

        pop dx
        pop cx

        ; Far jump to program
        push ax
        push bx
        retf


    .NoSendBadValues:
        stc
        ret
    


; External programs get here when they finish
ProgramEndPoint:
    ; Let's pop off the values that the int instruction put to the stack
    pop ax
    pop bx

    mov ax, word KernelSeg
    mov ds, ax
    mov es, ax

    call VgaClearScreen
    ; call ClearAttributesBuffer


    jmp GetCommand.AddNewLine



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

    mov ax, KernelSeg
    mov es, ax

    ret



; Macro to replace most of the PrintLogo bad code
; Input:
;   1 = string to print
%macro PrintLogoLine 1
    lea si, MascLogoSpace
    mov al, byte [NormalColour]
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

        lea si, WelcomeMessage
        mov al, byte [NormalColour]
        call VgaPrintString

        ret



; Kernel files
%include "./Bootloader/Common.inc"
%include "./Kernel/IVT.asm"
%include "./Kernel/Screen/VGA.asm"
%include "./Kernel/Screen/VESA.asm"
%include "./Kernel/Shell.asm"
%include "./Kernel/Disk.asm"
%include "./Kernel/Timer/PIT.asm"
%include "./Kernel/Timer/CMOS.asm"
%include "./Kernel/IO/Sound.asm"
%include "./Kernel/IO/Serial.asm"
%include "./Kernel/IO/Parallel.asm"
%include "./Kernel/APM.asm"
%include "./Kernel/String.asm"



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
WelcomeMessage: db 10, 13, "                         Welcome to MascOS! Loading...", 0