# How to write a program for MascOS

> **NOTE**:
> For now this file is a remainder for me on how to create programs for MascOS. Many features may be buggy or just bad.


## Program structure
You first need to know some stuff first, such as how a program gets loaded and how it gets terminated. You can use Assembly to create your thing. Fun fact: you can use C in 16-bits, but not here because I need to implement standard library.

The general layout of a program is this:
```x86asm
[bits 16]
[org 0x100]
[cpu 8086]


; We are here when we jump from the kernel
ProgramEntryPoint::
    ; Code....
    ; Your cool code here


    ; Stop the program
    int 0x20

```

## Load and execute a program in memory
It's surprisingly simple, here's how:<br>
you need to call the `LoadProgram` label, and give it the **pointer to the file name**, it can be outside the root directory too, it doesn't change anything, it just needs to point to an 11 byte valid FAT12 file name. After calling the label it will load the program in memory and **directly jumps to it**, you don't need to do anything else.

> Important note: `LoadProgram` WILL RETURN if the operation failed, setting the carry flag. So ALWAYS handle the case that it failed to execute your program.

Here's a code example:
```x86asm
ProgramFileName: db "SOMENAMEBIN"

; Loads a program
lea si, ProgramFileName
call LoadProgram

; if we are here it failed the operation(carry flag is set)
cli
hlt
```

The location in memory of the program is decided by the os, but like in MS DOS the **actual file is loaded at offset 0x100**, this is why the `org` directive *must* be set to 0x100. Don't use the memory area before that address.

<!-- Basically to run a program you first need to **load it in memory**, and for this you can call `int 0x22` with `ah = 1` and pass the required values, [check the interrupts documentation out](InterruptsDocumentation.md). Then you can maybe safely jump to your programs code in memory, just do a **far jump** like this one. In this case we loaded the program at `0x9600`. 

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
Did you check the [interrupts documentation](InterruptsDocumentation.md)? Or do you just don't have a brain? Joking obviously. You just add your offset to the kernel one and divide by 16 since you use this value as a base for the far jump. Better explanation in the interrupts documentation. -->


## Exit program
When you have done your thing it would be cool to exit from the program, right? To do that you can just call `int 0x20`, nothing more nothing less. It is a **much** cleaner way than doing it the old way, which involed doing a far jump to a specific location in the kernel, you can see that this was prone to bugs, right?
Here's an example if you really need it:

```x86asm
; Exit and go back to shell
int 0x20
```

This interrupt doesn't expect any input.

Alternatively you can use MS DOS interrupt 0x21 with ah set to 0x4c.
```x86asm
; Exit and go back to shell
mov ah, byte 0x4c
int 0x21
```

## Interrupts
MS DOS interrupt 0x21(int 0x21) is present, but the kernel also adds custom interrupts to the IVT(Interrupt Vector Table), so external programs can utilize VGA functions, disk functions and more, which allows to print strings, load files in memory, find a file and much more. To see the complete list of interrupts you can head to the [interrupts documentation](InterruptsDocumentation.md).