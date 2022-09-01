
# Thanks wiki.osdev.org, for being a thing
# https://wiki.osdev.org/Loopback_Device
# https://wiki.osdev.org/Bootable_Disk

Asm := nasm

BuildDir := Build
BootloaderDir := Bootloader
KernelDir := Kernel
BootloaderDirStable := Stable/Bootloader
KernelDirStable := Stable/Kernel

BootloaderFlags := -IBootloader/
KernelFlags := -IKernel/


all: CreateBuildDir main


# Non-stable version
main:
	@echo -e "\n\e[0;32m==> Compiling bootloader...\e[0m"
	$(Asm) -f bin $(BootloaderFlags) $(BootloaderDir)/Bootloader.asm -o $(BuildDir)/Bootloader.bin


	@echo -e "\n\e[0;32m==> Compiling kernel...\e[0m"
	$(Asm) -f bin $(KernelFlags) $(KernelDir)/Kernel.asm -o $(BuildDir)/Kernel.bin


	@echo -e "\n\e[0;32m==> Creating image...\e[0m"
	rm -rf $(BuildDir)/MascOS.flp
	dd if=/dev/zero of=$(BuildDir)/MascOS.flp bs=512 count=2880


	@echo -e "\n\e[0;32m==> Mount and format image...\e[0m"
	losetup /dev/loop7 $(BuildDir)/MascOS.flp
	mkdosfs -F 12 /dev/loop7
	mount /dev/loop7 /mnt -t msdos -o "fat=12"


	@echo -e "\n\e[0;32m==> Copying kernel and files to image...\e[0m"
	cp $(BuildDir)/Kernel.bin /mnt
	cp Test.txt /mnt


	@echo -e "\n\e[0;32m==> Unmount image...\e[0m"
	umount /mnt
	losetup -d /dev/loop7

	
	@echo -e "\n\e[0;32m==> Copying bootloader to image...\e[0m"
	dd status=noxfer conv=notrunc count=1 if=$(BuildDir)/Bootloader.bin of=$(BuildDir)/MascOS.flp

	


# Stable version
stable: CreateBuildDir
	@echo -e "\n\e[0;32m==> Compiling bootloader...\e[0m"
	$(Asm) -f bin $(BootloaderFlags) $(BootloaderDirStable)/Bootloader.asm -o $(BuildDir)/Bootloader.bin

	@echo -e "\n\e[0;32m==> Compiling kernel...\e[0m"
	$(Asm) -f bin $(KernelFlags) $(KernelDirStable)/Kernel.asm -o $(BuildDir)/Kernel.bin

	@echo -e "\n\n\e[0;32m==> Finishing up...\e[0m"
	cat $(BuildDir)/Bootloader.bin $(BuildDir)/Kernel.bin > $(BuildDir)/MascOS.img
	qemu-system-i386 -fda "Build/MascOS.img" -M smm=off -no-shutdown -no-reboot -d int -full-screen



# If not already there we create the Build directory
CreateBuildDir:
	@mkdir -p $(BuildDir)/
	mkdosfs -C $(BuildDir)/MascOS.flp 1440



clean:
	rm -rf $(BuildDir)/*