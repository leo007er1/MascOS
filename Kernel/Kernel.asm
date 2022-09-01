[org 0x0]
[bits 16]
[cpu 286]


cli ; No interruptions please
jmp KernelMain


%include "./Kernel/IO.asm"
%include "./Kernel/Shell.asm"
%include "./Kernel/Disk.asm"



KernelMain:
    ; Sets the segment again, so they won't error anything
    ; *THIS IS WHY Disk.asm DIDN'T FREAKING WORK.....
    mov ax, 0x7e0 ; Set every segment to where we are
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Sets a 4KB stack below the boot sector
    mov ax, 0x687b
    mov ss, ax
    mov sp, 0x7bff

    ; Save the disk number
    mov byte [BootDisk], dl
    mov word [TotalMemory], cx

    cld ; Forward direction for string operations
    sti ; Now you can annoy me

    call PrintLogo

    ; Waits 4 seconds
    mov cx, 0x2d
    mov dx, 0x4240
    mov ah, 0x86
    int 0x15

    ; Clears the screen
    mov ah, 0
    mov al, 3
    int 0x10


    ; --//  Actual useful stuff  \\--
    
    
    jmp InitShell

    cli
    hlt



TotalMemory: dw 0