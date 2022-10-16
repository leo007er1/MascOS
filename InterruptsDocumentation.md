# Custom interrupts
MascOS uses some custom interrupts to allow external programs to use useful stuff like printing a string or colouring a line. Here's the list of the interrupts and what they do.


## Int 0x21
Screen output throught VGA driver.

### Print string
Prints a string at cursor position. Automatically scrolls if the text goes out of the screen.

`ah` = 0<br />
`si` = pointer to string<br />
`al` = attribute(foreground and background colour), clear to use default colour

### Print character
Prints a single character at cursor position.

`ah` = 1<br />
`al` = character to print<br />
`cl` = attribute byte, set to 0 to use default colour

### New line
Adds the specified number of new lines, changing the cursor position.

`ah` = 2<br />
`al` = number of new lines

### Go to line
Moves the cursor to a specified line.

`ah` = 3<br />
`al` = line to go to

### Clear line
Clears out a single line, attribute byte too.

`ah` = 4<br />
`al` = line to clear

### Paint line
Changes the attribute byte of the specified line.

`ah` = 5<br />
`al` = attribute byte, colour<br />
`cl` = line

### Clear screen
Yup, it clears the screen.

`ah` = 6

### Backspace
Deletes the last character. Added this because it was needed by Edit program, the text editor.

`ah` = 7


## Int 0x22
Disk routines for searching, loading files by messing with the FAT12 file system.

### Search a file
Finds a file in the root directory of FAT12, returning the pointer of the entry.

`ah` = 0<br />
`si` = pointer to file name. Needs to be a zero terminated string of 11 characters.

**Output**<br />
`ah` = for success, 1 for error<br />
`dx` = the given value in `si`<br />
`cx` = pointer to entry in root dir

### Load a file
Loads a file at the specified offset in memory. Offset is relative to the kernel, so if you say 0 the file will be loaded just right after the kernel. To get the absolute memory address do: `0x7e00 + KernelOffset + yourFileOffset`. `0x7e00` is the kernel position in memory, `KernelOffset` is a constant at line 18 of `Disk.asm` file inside the Kernel folder, this value is used as a padding from kernel position, so you don't mistakenly(or on purpose?) write over the kernel.

`ah` = 1<br />
`di` = pointer to entry in root dir<br />
`bx` = offset to read to(offset is relative to kernel position)