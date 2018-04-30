NAME=piano

all: piano

clean:
	rm -rf piano piano.o

piano: piano.asm
	nasm -f elf piano.asm
	gcc -g -m32 -o piano piano.o /root/Assembly_Piano/libraries/driver.c /root/Assembly_Piano/libraries/asm_io.o /root/Assembly_Piano/libraries/beep.o
