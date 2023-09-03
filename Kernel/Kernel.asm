[org 0x0]
[bits 16]
[cpu 8086]


cli ; No interruptions please
jmp KernelMain

%define NewLine 10, 13
LogoColor equ 0xe ; Yellow
BdaMemAddress equ 0x40 ; Divided by 16 because it will be moved to es


KernelMain:
    ; Sets the segment again, so they won't error anything
    ; *THIS IS WHY Disk.asm DIDN'T FREAKING WORK.....
    mov ax, word KernelSeg ; Set every segment to where we are
    mov ds, ax
    mov es, ax

    ; Sets a 4KB stack below the boot sector
    mov ax, 0x687b
    mov ss, ax
    mov sp, 0x7bff

    ; Save the disk number
    mov byte [CurrentDisk], dl

    cld ; Forward direction for string operations
    sti ; Now you can annoy me

    ; Masking interrupt 0x70 and 0x8 by setting bit 0 on I/O ports
    mov al, byte 1
    out 0x1a, al
    out 0x21, al

    ; Sets VGA 80x25
    xor ah, ah
    mov al, 3
    int 0x10

    call VgaInit
    mov word [CursorPos], 0 ; Need to update values
    mov word [CurrentRow], 0 ; Clears CurrentColumn too

    call GetBdaInfo
    call SetNewInterrupts
    call PitInit
    call SerialInit
    call ApmInit
    
    call PrintLogo

    ; Waits cx:dx microseconds
    mov cx, 15
    mov dx, 10000
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
;   ds:si = pointer to file name, must be 11 characters with the last 3 being the extension
; Output:
;   ! If operation fails it will return
;   carry flag = set
LoadProgram:
    call SearchFile
    jc .NoBadValues

    ; We need to know how CHUNCKY it is
    mov bx, si ; si is contains the pointer to entry in root directory
    call GetFileSize

    mov cl, 1
    shl ax, cl ; ax * 2

    ; If dx = 0, we need to count another sector
    or dx, dx
    jz .LoadIt

    inc ax

    .LoadIt:
        mov dx, word KernelSeg
        mov ds, dx
        mov dx, word ProgramSeg
        mov es, dx
        mov word [es:0], ax ; Save the file size

        ; Pointer to entry already set
        mov bx, word ProgramOffset ; Offset
        call LoadFile

    .CheckExtension:
        mov ax, word RootDirMemLocation
        mov ds, ax

        mov ax, word [si + 8]
        mov cl, byte [si + 10]
        
        cmp ax, word 0x4f43 ; "CO"
        cmp cl, 0x4d ; "M"
        je .ComProgram

        cmp ax, word 0x4942 ; "BI"
        cmp cl, byte 0x4e ; "N"
        jne .NoBadValues

        ; .BIN program
        xor bx, bx
        mov ax, word ProgramSeg + (ProgramOffset / 16)
        mov ds, ax
        mov es, ax
        jmp .JumpToProgram

    .ComProgram:
        mov bx, word 0x100
        mov ax, word ProgramSeg
        mov ds, ax
        mov es, ax

    .JumpToProgram:
        ; Far jump to program
        push ax
        push bx
        retf


    .NoBadValues:
        stc
        ret
    

; External programs get here when they finish
ProgramEndPoint:
    ; Let's pop off the values that the int instruction put to the stack
    pop ax
    pop bx
    call FreeProgram

    mov ax, word KernelSeg
    mov ds, ax
    mov es, ax

    ; call VgaClearScreen
    ; call ClearAttributesBuffer

    jmp GetCommand.AddNewLine


; Frees the memory occupied by a program
FreeProgram:
    mov bx, word ProgramSeg
    mov ds, bx
    add bx, word 0x10
    mov es, bx

    ; How many sectors to clear
    mov ax, word [ds:0] ; Get file size in KB
    mov cx, word 2
    mul cx

    mov dx, bx ; Where the program code starts

    .ClearSector:
        or ax, ax
        jz .Exit

        mov cx, word 256 ; Words per sector
        xor bx, bx

        .ZeroOutIt:
            mov word [es:bx], word 0
            add bx, 2

            loop .ZeroOutIt

        dec ax
        add dx, word 0x20 ; Next sector
        mov es, dx

        jmp .ClearSector

    .Exit:
        ret


EndProgramAndRunAnother:
    ; Let's pop off the values that the int instruction put to the stack
    pop ax
    pop bx
    call FreeProgram

    mov ax, word KernelSeg
    mov es, ax

    call LoadProgram
    
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



; Prints one line of the logo
; Input:
;   si = string to print
PrintLogoLine:
    push si
    lea si, MascLogoSpace
    mov al, byte [NormalColour]
    call VgaPrintString

    pop si
    mov al, LogoColor
    call VgaPrintString

    mov al, byte 1
    call VgaPrintNewLine

    ret


; *TRASH CODE WARNING! CONTINUE AT YOUR OWN RISK
PrintLogo:
    xor cx, cx

    ; Padding to the top
    mov al, byte 6
    call VgaPrintNewLine

    .Logo:
        ; Now it's way cleaner
        lea si, MascLogo
        call PrintLogoLine
        lea si, MascLogo1
        call PrintLogoLine
        lea si, MascLogo2
        call PrintLogoLine
        lea si, MascLogo3
        call PrintLogoLine

        lea si, WelcomeMessage
        mov al, byte [NormalColour]
        call VgaPrintString

        ret


; Kernel files
%include "./Bootloader/Common.inc"
%include "./Kernel/IVT.asm"
%include "./Kernel/Screen/VGA.asm"
%include "./Kernel/Shell.asm"
%include "./Kernel/Disk.asm"
%include "./Kernel/FAT12.asm"
%include "./Kernel/Timer/PIT.asm"
%include "./Kernel/Timer/CMOS.asm"
%include "./Kernel/IO/Sound.asm"
%include "./Kernel/IO/Serial.asm"
%include "./Kernel/IO/Parallel.asm"
%include "./Kernel/APM.asm"
%include "./Kernel/String.asm"
%include "./Kernel/DOS.asm"


TotalMemory: dw 0
BiosEquipmentWord: dw 0 ; Are there any serial, parallel ports and other stuff

; Ports info
ParallelPorts: times 3 dw 0

ComExtension: db "COM", 0
BinExtension: db "BIN", 0

; Logo stuff
MascLogoSpace: db "                    ", 0
MascLogo: db "  \  |                      _ \   ___|", 0
MascLogo1: db " |\/ |   _` |   __|   __|  |   |\___ \", 0
MascLogo2: db " |   |  (   | \__ \  (     |   |      |", 0
MascLogo3: db "_|  _| \__._| ____/ \___| \___/ _____/", 0
WelcomeMessage: db NewLine, "                         Welcome to MascOS! Loading...", 0