Asm := nasm

BuildDir := Build
BootloaderDir := Bootloader
KernelDir := Kernel
BootloaderDirStable := Stable/Bootloader
KernelDirStable := Stable/Kernel

BootloaderFlags := -IBootloader/
KernelFlags := -IKernel/


all: CreateBuildDir CreateOsImage Main


Main:
	@echo -e "\n\e[0;32m==> Compiling bootloader...\e[0m"
	$(Asm) -f bin $(BootloaderFlags) $(BootloaderDir)/Bootloader.asm -o $(BuildDir)/Bootloader.bin

	@echo -e "\n\e[0;32m==> Compiling kernel...\e[0m"
	$(Asm) -f bin $(KernelFlags) $(KernelDir)/Kernel.asm -o $(BuildDir)/Kernel.bin

	@echo -e "\n\n\e[0;32m==> Finishing up...\e[0m"
	dd status=noxfer conv=notrunc if=$(BuildDir)/Bootloader.bin of=$(BuildDir)/MascOS.flp
	dd status=noxfer conv=notrunc seek=2 if=$(BuildDir)/Kernel.bin of=$(BuildDir)/MascOS.flp


stable:
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

CreateOsImage:
	@rm -f $(BuildDir)/MascOS.flp

	@echo -e "\e[0;32m==> Creating os image...\e[0m"
	mkdosfs -C $(BuildDir)/MascOS.flp 1440

clean:
	rm -rf $(BuildDir)/*