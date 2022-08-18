Asm := nasm

BuildDir := Build
BootloaderDir := Bootloader
KernelDir := Kernel


all: Main


Main:
	@echo -e "\e[0;32m==> Compiling bootloader...\e[0m"
	$(Asm) -f bin $(BootloaderDir)/Bootloader.asm -o $(BuildDir)/Bootloader.bin

	@echo -e "\e[0;32m==> Compiling kernel...\e[0m"
	$(Asm) -f bin $(KernelDir)/Kernel.asm -o $(BuildDir)/Kernel.bin

	@echo -e "\n\n\e[0;32m==> Finishing up...\e[0m"
	cat $(BuildDir)/Bootloader.bin $(BuildDir)/Kernel.bin > $(BuildDir)/MascOS.img


clean:
	rm -rf $(BuildDir)/*