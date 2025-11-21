ASM_FLAGS := -f elf64 -g -F dwarf

example: hashmap.o strhash.o main.o
	# link all object files into an executable called example
	ld -o $@ $^
	# Remove object files
	rm -f $^

hashmap.o: hashmap.asm
	nasm ${ASM_FLAGS} $^

strhash.o: strhash.asm
	nasm ${ASM_FLAGS} $^

main.o: main.asm
	nasm ${ASM_FLAGS} $^
