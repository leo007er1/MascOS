[bits 16]
[cpu 286]


MemoryAvaiable: dw 0


; Gets the ammount of KB avaiable to use
GetMemoryAvaiable:
    push ax

    int 0x12
    mov [MemoryAvaiable], ax ; Saves the number we got

    pop ax

    ret