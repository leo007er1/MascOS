
# Thanks wiki.osdev.org, for being a thing
# https://wiki.osdev.org/Loopback_Device
# https://wiki.osdev.org/Bootable_Disk

Asm := nasm

BuildDir := Build/
BootloaderDir := Bootloader/
KernelDir := Kernel/
ProgramsDir := Programs/
FilesDir := Files/

OsFiles := $(shell find -L $(FilesDir) -type f)
OsPrograms := $(shell find -L $(ProgramsDir) -type f -name "*.asm")
OsProgramsObjs := $(patsubst %.asm, %.bin, $(subst $(ProgramsDir), $(BuildDir), $(OsPrograms)))

BootloaderDirStable := Stable/Bootloader/
KernelDirStable := Stable/Kernel/

BootloaderFlags := -IBootloader/
KernelFlags := -IKernel/


all: CheckUser CreateBuildDir main


# Non-stable version
main:
	@echo -e "\n\e[0;32m==> Compiling bootloader...\e[0m"
	$(Asm) -f bin $(BootloaderFlags) $(BootloaderDir)Bootloader.asm -o $(BuildDir)Bootloader.bin

	@echo -e "\n\e[0;32m==> Compiling kernel and programs...\e[0m"
	$(Asm) -f bin $(KernelFlags) $(KernelDir)Kernel.asm -o $(BuildDir)Kernel.bin
	$(Asm) -f bin $(ProgramsDir)TrashVim.asm -o $(BuildDir)TrashVim.bin
	$(Asm) -f bin $(ProgramsDir)Hi.asm -o $(BuildDir)Hi.bin

	@echo -e "\n\e[0;32m==> Creating image...\e[0m"
	rm -rf $(BuildDir)/MascOS.flp
	dd if=/dev/zero of=$(BuildDir)/MascOS.flp bs=512 count=2880

	@echo -e "\n\e[0;32m==> Mount and format image...\e[0m"
	losetup /dev/loop7 $(BuildDir)MascOS.flp
	mkdosfs -F 12 /dev/loop7
	mount /dev/loop7 /mnt -t msdos -o "fat=12"

	@echo -e "\n\e[0;32m==> Copying kernel and files to image...\e[0m"
	cp $(BuildDir)/Kernel.bin /mnt
	cp $(OsFiles) $(OsProgramsObjs) /mnt

	@echo -e "\n\e[0;32m==> Unmount image...\e[0m"
	umount /mnt
	losetup -d /dev/loop7
	
	@echo -e "\n\e[0;32m==> Copying bootloader to image...\e[0m"
	dd status=noxfer conv=notrunc count=1 if=$(BuildDir)Bootloader.bin of=$(BuildDir)MascOS.flp


debug:
	qemu-system-i386 -fda $(BuildDir)MascOS.flp -M smm=off -no-shutdown -no-reboot -d int -monitor stdio -D ./QemuLog.log \
 -cpu 486 -audiodev alsa,driver=alsa,id=audio0 -machine pcspk-audiodev=audio0
	

run:
	qemu-system-i386 -fda $(BuildDir)MascOS.flp -M smm=off -no-shutdown -no-reboot -d int -cpu 486 -audiodev alsa,driver=alsa,id=audio0 -machine pcspk-audiodev=audio0


# Stable version
stable: CheckUser CreateBuildDir
	@echo -e "\n\e[0;32m==> Compiling bootloader...\e[0m"
	$(Asm) -f bin $(BootloaderFlags) $(BootloaderDirStable)Bootloader.asm -o $(BuildDir)Bootloader.bin

	@echo -e "\n\e[0;32m==> Compiling kernel...\e[0m"
	$(Asm) -f bin $(KernelFlags) $(KernelDirStable)Kernel.asm -o $(BuildDir)Kernel.bin

	@echo -e "\n\n\e[0;32m==> Finishing up...\e[0m"
	cat $(BuildDir)Bootloader.bin $(BuildDir)Kernel.bin > $(BuildDir)MascOS.img
	qemu-system-i386 -fda "Build/MascOS.img" -M smm=off -no-shutdown -no-reboot -d int -full-screen



# If not already there we create the Build directory and the .flp image
CreateBuildDir:
	@mkdir -p $(BuildDir)

	test -f $(BuildDir)MascOS.flp || mkdosfs -C $(BuildDir)MascOS.flp 1440
	

# Checks if the user has permissions to mount an image
CheckUser:
	@if ! [ "$(shell id -u)" = 0 ]; then \
		echo -e "\e[0;31mYou need to be root to mount the image.\n\e[0mUse \"sudo su\" to give yourself permission or add a \"sudo\" before your command\n"; \
		exit 1; \
	fi


clean:
	rm -rf $(BuildDir)/*