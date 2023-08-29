# Kernel


Simple kernel that shows a logo, launches a **scuffed shell** and can perform basic tasks.

The kernel sets up some custom interrupts in the IVT, can interact with the disk, has a custom **VGA driver**, CMOS and RTC handlers, pc speaker, serial and parallel ports drivers and more. MS DOS programs can run on the os but are not fully compatible due to missing interrupt implementations.

I surprised myself with the shell because it "works" and isn't really that terrible. It supports **command line attributes** and for now has some commands.