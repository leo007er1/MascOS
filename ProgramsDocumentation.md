# How to write a program for MascOS

### NOTE
For now this file is a remainder for me on how to create programs for MascOS. Many features may be buggy and just bad.


## Create a program
You first need to know some stuff first, such as how a program gets loaded and how it gets terminated. You can use Assembly to create stuff, even C if you want. Yes, you can use C in 16-bits.

The layout of a program is this:
```
[bits 16]
[cpu 8086]


; Where the RunProgram label brings us to
EditProgram:
    ; Code....



    ; Stop the program
    mov ax, 0x7e0
    mov bx, 4
    push ax
    push bx

    retf

```


Basically to run it you need to first call the `RunProgram` label, and give it the location in memory where the program is loaded divided by 16. You may ask why, and the reason is this:
to execute your code, the **segment registers** need to be set to the right value; `RunProgram` fills these registers for you. To call the program we use **segmentation** which allows us to get to larger memory locations than just using a single register like `ax`. To do this we use two values, `base` and `offset`. The `base` is the value that goes into the segment registers, and when you use segmentation this value get's multiplied by 16. On the other you **don't** need to worry about the offset, which is added to the base, because `RunProgram` assumes it's 0.

It's **very important** that the first line of code is a label, if you add data before it or include something it will instead try to execute that code. After the label you can do your thing, just don't destroy something : ). When you wanna stop your program and pass control to the kernel you do a **far return** with the last 3 lines of the code above. It's **important**, again, that you use those values, or else you will go somewhere else and make a mess.