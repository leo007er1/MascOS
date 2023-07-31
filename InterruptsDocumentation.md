# Custom interrupts
MascOS uses some custom interrupts to allow external programs to use useful stuff like printing a string or colouring a line. Here's the list of the interrupts and what they do.


## Int 0x20
End of program interrupt.
This interrupt gets invoked whenever an external program ends it's job and wants to **pass control to the kernel**. Doesn't expect any input, just call the interrupt.

## Int 0x21
This is the same interrupt as the MS DOS one. You can find the list of the functions of this interrupt online. Here's the [first one I found online.](http://spike.scu.edu.au/~barry/interrupts.html)

I only have implemented the functions for ah set to 0x1 to 0xa exluding 0x5, then 0xd, 0x19, 0x2a, 0x2c, 0x4c, 0x56.

## Int 0x22
Disk routines for searching, loading files by messing with the FAT12 file system.

### Search a file
Finds a file in the root directory of FAT12, returning the pointer of the entry.

`ah` = 0<br>
`ds:si` = pointer to file name. Needs to be a zero terminated string of 11 characters.

**Output**<br>
`carry flag` = clear for success, set for error<br>
`si` = pointer to entry in root dir

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
`dx` = remainder in bytes

## Rename file
Renames a file including the extension. To rename a file you need a valid FAT12 file name, so 8 bytes for the name and 3 for the extension.

`ah` = 4<br>
`ds:si` = pointer to file to rename<br>
`es:di` = pointer to new file name

**Output**<br>
`carry flag` = set for invalid file name, clear for success


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
`bl` = attribute byte

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

### Paint buffer
Changes the attribute byte of a specified chunk of screen estate.

`ah` = 5<br>
`al` = attribute byte, colour<br>
`cx` = how many columns to change colour to<br>
`bh` = y position(max 24)<br>
`bl` = x position(max 80)

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

### Goto position
Changes the cursor position to the specified position onto the screen.

`ah` = 9<br>
`bh` = y position(max 24)<br>
`bl` = x position(max 80)

## Int 0x24
Used to play and stop sound using the pc speaker.

### Play sound
Plays a sound of the specified frequency.

`ah` = 0<br>
`bx` = frequency(minimum 80 or you won't hear anything) 

## Play track
Plays a series of frequencies to mimic a music track. The track must be null-terminated. A single frequency is 2 bytes large.

`ah` = 1<br>
`ds:si` = pointer to null-terminated track.

### Stop sound
Shuts up the pc speaker.

`ah` = 2

## Int 0x25
This is only used to launch a program from another one, so one doesn't need to pass control again to the kernel when switching programs.

`si` = pointer to file name, must be 11 characters with the last 3 being the extension