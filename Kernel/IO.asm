[bits 16]
[cpu 286]



; Macro to print a single character
; I did this instead of a "function" because I would waste or ax or si
; *Note: I could just push ax and si to the stack but I don't care for now
%macro PrintChar 1
    push ax

    mov ah, 0x0e ; Teletype mode
    mov al, %1
    int 0x10

    pop ax

%endmacro



; Prints a given string
; Input:
;   si = pointer to string
PrintString:
    push ax

    mov ah, 0x0e ; Teletype mode

    .Loop:
        lodsb ; Loads the current byte into al

        cmp al, byte 0
        je .Exit

        int 0x10

        jmp .Loop

    .Exit:
        pop ax

        ret



; Yup, it does what it says
PrintNewLine:
    push ax
    mov ah, 0x0e ; Teletype mode

    ; Carriage return
    mov al, 10
    int 0x10

    ; New line
    mov al, 13
    int 0x10

    pop ax

    ret


; Yes, I didn't want to call PrintNewLine twice
PrintNewDoubleLine:
    push ax
    mov ah, 0x0e ; Teletype mode

    ; Carriage return
    mov al, 10
    int 0x10

    ; New line
    mov al, 13
    int 0x10

    ; Carriage return
    mov al, 10
    int 0x10

    ; New line
    mov al, 13
    int 0x10

    pop ax

    ret



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