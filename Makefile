bismuth: bismuth.asm
	nasm -g -f elf32 bismuth.asm
	ld -m elf_i386 bismuth.o -o bismuth

.PHONY: clean
clean:
	rm -f bismuth.o bismuth
