%include "/usr/share/csc314/asm_io.inc"


segment .data


segment .bss


segment .text
	global  asm_main

asm_main:
	enter	0,0
	pusha
	;***************CODE STARTS HERE***************************

	

	;***************CODE ENDS HERE*****************************
	popa
	mov	eax, 0
	leave
	ret
