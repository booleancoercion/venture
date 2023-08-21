.PHONY: default
default: venture.iso

.PHONY: clean
clean:
	-rm boot.o kernel.o venture.bin venture.iso
	-rm -rf isodir

.PHONY: check
check:
	@if grub2-file --is-x86-multiboot venture.bin; then \
		echo multiboot confirmed; \
	else \
		echo the file is not multiboot; \
	fi

.PHONY: test
test:
	qemu-system-i386 -cdrom venture.iso

boot.o: boot.s
	i686-elf-as boot.s -o boot.o

kernel.o: kernel.c
	i686-elf-gcc -c kernel.c -o kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra

venture.bin: boot.o kernel.o
	i686-elf-gcc -T linker.ld -o venture.bin -ffreestanding -O2 -nostdlib boot.o kernel.o -lgcc

venture.iso: venture.bin grub.cfg
	mkdir -p isodir/boot/grub
	cp venture.bin isodir/boot/venture.bin
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub2-mkrescue -o venture.iso isodir
