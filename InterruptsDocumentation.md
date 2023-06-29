# Custom interrupts
MascOS uses some custom interrupts to allow external programs to use useful stuff like printing a string or colouring a line. Here's the list of the interrupts and what they do.


## Int 0x20
End of program interrupt.
This interrupt gets invoked whenever an external program ends it's job and wants to **pass control to the kernel**. Doesn't expect any input, just call the interrupt.


## Int 0x23
Screen output throught VGA driver.

### Print string
Prints a string at cursor position. Automatically scrolls if the text goes out of the screen.

`ah` = 0<br>
`si` = pointer to string<br>
`al` = attribute(foreground and background colour)

### Print character
Prints a single character at cursor position.

`ah` = 1<br>
`al` = character to print<br>
`cl` = attribute byte

### New line
Adds the specified number of new lines, changing the cursor position.

`ah` = 2<br>
`al` = number of new lines

### Go to line
Moves the cursor to a specified line.

`ah` = 3<br>
`al` = line to go to

### Clear line
Clears out a single line, attribute byte too.

`ah` = 4<br>
`al` = line to clear

### Paint line
Changes the attribute byte of the specified line.

`ah` = 5<br>
`al` = attribute byte, colour<br>
`cl` = line

### Clear screen
Yup, it clears the screen.

`ah` = 6

### Backspace
Deletes the last character. Added this because it was needed by Edit program, the text editor.

`ah` = 7


### Get colours
This function will return the colours that are currently used for printing text and stuff.

`ah` = 8

**Output**<br>
`bl` = text colour, the one used for almost everything
`bh` = accent colour, for example this is used for the command prompt arrow thinghy


## Int 0x22
Disk routines for searching, loading files by messing with the FAT12 file system.

### Search a file
Finds a file in the root directory of FAT12, returning the pointer of the entry.

`ah` = 0<br>
`si` = pointer to file name. Needs to be a zero terminated string of 11 characters.

**Output**<br>
`carry flag` = clear for success, set for error<br>
`dx` = the given value in `si`<br>
`cx` = pointer to entry in root dir


### Load a file
Loads a file at the specified offset in memory. The offset is specified by `es:bx`.
Just don't write mistakenly(or on purpose?) write over the kernel or at any lower memory offset.

`ah` = 1<br>
`di` = pointer to entry in root dir<br>
`es:bx` = offset to read to


### Get a file name
Gets the name and file extension of a file, via the specified pointer to the entry in the root directory.

`ah` = 2<br>
`si` = pointer to string to output name to. Needs to be 12 characters because remember the 0 at the end.


### Get a file size
Gets the file size and returns the value in kilobytes(KB).

`ah` = 3<br>
`si` = pointer to entry in root directory

**Output**<br>
`ax` = file size in KB