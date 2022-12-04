# Kernel


Simple kernel that shows a logo, launches a **scuffed shell** and can perform basic tasks.

The kernel sets up some custom interrupts in the IVT, can interact with the disk(only reading for now), has a custom **VGA driver**, CMOS and RTC handlers and more. There are also serial and parallel ports drivers but are untested and incompleted. Also has a VESA driver, althought I don't know if I will fully support it.

I surprised myself with the shell because it "works" and isn't really that terrible. The shell supports **command line attributes** and for now has these commands:
 - help
 - clear
 - ls
 - fetch
 - reboot
 - himom
 - colour
 - edit, this is an external program, a very simple text editor
 - cat