# How to write a program for MascOS

### NOTE
For now this file is a remainder for me on how to create programs for MascOS. Many features may be buggy and just bad.


## Program structure
You first need to know some stuff first, such as how a program gets loaded and how it gets terminated. You can use Assembly to create stuff. Fun fact: you can use C in 16-bits, but not here because I need to implement standard library.

The general layout of a program is this:
```x86asm
[bits 16]
[cpu 8086]


; We are here when we jump from the kernel
ProgramEntryPoint::
    ; Code....
    ; Your cool code here


    ; Stop the program
    jmp 0x7e0:0x4

```

## Load and execute program in memory
Basically to run a program you first need to **load it in memory**, and for this you can call `int 0x22` with `ah = 1` and pass the required values, [check the interrupts documentation out](InterruptsDocumentation.md). Then you can maybe safely jump to your programs code in memory, just do a **far jump** like this one. In this case we loaded the program at `0x9600`. 

```x86asm
; Search program
xor ah, ah
lea si, FileNameHere
int 0x22
cmp ah, byte 1 ; Did the operation fail?
je Error

; Load program
mov ah, byte 1
mov bx, 0x400 ; 1KB offset
mov di, cx ; Pointer to entry in root directory
int 0x22

; 0x9600 / 16 = 0x960
; Your offset can be different too, do what you want
jmp 0x960:0x0
```

Wait Leo! How do I know where to jump to?
Did you check the [interrupts documentation](InterruptsDocumentation.md)? Or do you just don't have a brain? Joking obviously. You just add your offset to the kernel one and divide by 16 since you use this value as a base for the far jump. Better explanation in the interrupts documentation.


## Exit program
When you have done your thing it would be cool to exit from the program, right? To do that you can just jump back to a specific location in the kernel, which is `0x7e0:0x4`. Why that? Because I'm not creative, I might add an interrupt to close the program instead of making you jump to the kernel. Here's the example.

> NOTE: It's important to set CS back to 0x7e0 and the offset to be 0x4

```x86asm
; Exit and go back to shell
, DO NOT jump to a different location
jmp 0x7e0:0x4
```