[bits 16]


KernelOffset equ 0x1000
BootDisk: db 0
ReadAttempts: db 0


ReadDisk:
    call ResetDisk

    clc

    ; Sets the buffer to read to: ES:BX
    mov bx, KernelOffset

    mov ah, 0x02 ; Read please
    mov al, 6 ; Sectors to read
    mov dl, [BootDisk]

    ; CHS addressing
    ; NOTE: In floppyes there are 18 sectors per track, with 2 heads and a total sectors count of 2880
    mov ch, 0x00 ; C (cylinder)
    mov dh, 0x00 ; H (head)
    mov cl, 0x02 ; S (sector). Starts from 1, not 0. Why?

    int 0x13
    jc .Check ; Carry flag set
    jmp .Exit
    
    ; Retryes the operation 3 times, if failed all 3 times outputs error, yay
    .Check:
        add [ReadAttempts], byte 1 ; If I use inc I get and error
        cmp [ReadAttempts], byte 3
        je ReadDiskError

    .Exit:
        ret


; Resets the disk: moves to sector 1
ResetDisk:
    mov ah, 0
    mov dl, [BootDisk]

    int 0x13
    jc ResetDisk ; Carry flag set!

    ret



ReadDiskError:
    mov si, ReadDiskErrorMessage
    call PrintString

    cli
    hlt




ReadDiskErrorMessage: db 10, 13, 10, 13, "Disk read error", 0