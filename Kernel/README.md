# Kernel


Simple kernel that shows a logo, launches a **scuffed shell** and can perform basic tasks.

The kernel sets up some custom interrupts in the IVT, can interact with the disk(only reading for now), has a custom **VGA driver**, CMOS and RTC handlers, pc speaker driver, serial and parallel ports drivers and more. MS DOS programs can *theoretically* run on the os but are not fully compatible due to missing interrupt implementations, and I didn't try to run one on the operating system.

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
 - run
 - files, simple file manager
 - sound