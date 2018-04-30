%include "/root/Assembly_Piano/libraries/asm_io.inc"


; the file that stores the initial state
%define BOARD_FILE 'piano.txt'

; the size of the game screen in characters
%define HEIGHT 12
%define WIDTH 53
%define WALL_CHAR '#'

;starting position for printing out letter on keys
%define STARTX 1
%define STARTY 1

; these keys do things
%define EXITCHAR 'x'

%define DURATION 250

%define TICK 10000

; these keys are piano keys
%define BLACKD 'q'
%define LOWE 'a'
%define LOWF 's'
%define BLACKF 'e'
%define LOWG 'd'
%define BLACKG 'r'
%define AKEY 'f'
%define BLACKA 't'
%define BKEY 'g'
%define MIDCKEY 'h'
%define BLACKC 'u'
%define DKEY 'j'
%define BLACKMIDD 'i'
%define EKEY 'k'
%define FKEY 'l'
%define BLACKMIDF 'p'
%define GKEY ';'
%define BLACKMIDG '['

%define FLAT 'b'



segment .data

	; used to fopen() the board file defined above
	board_file			db BOARD_FILE,0

	; used to change the terminal mode
	mode_r				db "r",0
	raw_mode_on_cmd		db "stty raw -echo",0
	raw_mode_off_cmd	db "stty -raw echo",0

	; called by system() to clear/refresh the screen
	clear_screen_cmd	db "clear",0

	; things the program will print
	help_str			db	13,10,"Put your hands on the Home row of the keyboard, ", \
							"thumbs go on 'g' and 'h', and begin to play. ",13,10, \
							"Middle C is the 'h' key.",13,10, \
							"To quit, press the 'x' key.",13,10,10,0

segment .bss

	; this array stores the current rendered gameboard (HxW)
	board	resb	(HEIGHT * WIDTH)

	;these variables store the current duration and frequency
	dur	resd	1
	freq	resd	1
	key	resd	10
	count	resd	1
	note	resd	1
	flat	resd	1
	flag	resd	1
	octup	resd	1
	octdown	resd	1


	xpos	resd	1
	ypos	resd	1

segment .text

	global	asm_main
	global  raw_mode_on
	global  raw_mode_off
	global  init_board
	global  render

	extern	system
	extern	putchar
	extern	getchar
	extern	printf
	extern	fopen
	extern	fread
	extern	fgetc
	extern	fclose
	extern	beep
	extern	usleep
	extern	fcntl

asm_main:
	enter	0,0
	pusha
	;***************CODE STARTS HERE***************************

	; How to use Beep
;	push 500 	; 1 sec = 1000 ms
;	push 262	; frequency
;	call beep
;	add esp, 8


	; put the terminal in raw mode so the game works nicely
	call	raw_mode_on

	; read the game board file into the global variable
	call	init_board

	; set starting position
	mov DWORD[xpos], STARTX
	mov DWORD[ypos], STARTY
	mov DWORD[note], ' '
	mov DWORD[flat], FLAT
	mov DWORD[flag], 0

	; the game happens in this loop
	; the steps are...
	;   1. render (draw) the current board
	;   2. get a character from the user
	;	3. store current xpos,ypos in esi,edi
	;	4. update xpos,ypos based on character from user
	;	5. check what's in the buffer (board) at new xpos,ypos
	;	6. if it's a wall, reset xpos,ypos to saved esi,edi
	;	7. otherwise, just continue! (xpos,ypos are ok)
	game_loop:

		; draw the game board
		call	render

		; get an action from the user
		call	getchar
	;	call	nonblocking_getchar

	;	cmp	al, -1
	;	jne	got_char

		; we didn't get a character.  sleep and loop again
		; Note: if we don't sleep here it scrolls too fast
		; and ends up looking weird

		; usleep(TICK)
	;	push	TICK
	;	call	usleep
	;	add		esp, 4



		got_char:
		;store key
		mov		DWORD[key], eax
		mov		DWORD[dur], DURATION

		; choose what to do
		cmp		DWORD[key], EXITCHAR
		je		game_loop_end
		cmp		DWORD[key], BLACKD
		je		playBlackD
		cmp		DWORD[key], LOWE
		je		playE
		cmp		DWORD[key], LOWF
		je		playF
		cmp		DWORD[key], BLACKF
		je		playBlackF
		cmp		DWORD[key], LOWG
		je		playG
		cmp		DWORD[key], BLACKG
		je		playBlackG
		cmp		DWORD[key], AKEY
		je		playA
		cmp		eax, BLACKA
		je		playBlackA
		cmp		eax, BKEY
		je		playB
		cmp		eax, MIDCKEY
		je		playC
		cmp		eax, BLACKC
		je		playBlackC
		cmp		eax, DKEY
		je		playD
		cmp		eax, BLACKMIDD
		je		playBlackD
		cmp		eax, EKEY
		je		playE
		cmp		eax, FKEY
		je		playF
		cmp		eax, BLACKMIDF
		je		playBlackF
		cmp		eax, GKEY
		je		playG
		cmp		eax, BLACKMIDG
		je		playBlackG

		mov DWORD[freq], 0

;		cmp DWORD[flag], 1
;		je other
		mov DWORD[note], ' '
;		jmp cont

;		other:
;		mov DWORD[note], '#'

;		cont:
		jmp		input_end			; or just do nothing

		; move the player according to the input character
		playA:
			mov eax, 28		;base freq
			mov DWORD[note], 'A'		; 0 means no flat
			mov DWORD[flag], 0

			mov DWORD[xpos], 18
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], AKEY
			je Top_Of_Loop

		playB:
			mov eax, 31		;base freq
			mov DWORD[note], 'B'
			mov DWORD[flag], 0

			mov DWORD[xpos], 23
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], BKEY
			je Top_Of_Loop

		playC:
			mov eax, 33		;base freq
			mov DWORD[note], 'C'
			mov DWORD[flag], 0

			mov DWORD[xpos], 28
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], MIDCKEY
			je Top_Of_Loop

		playD:
			mov eax, 37		;base freq
			mov DWORD[note], 'D'
			mov DWORD[flag], 0

			mov DWORD[xpos], 33
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], DKEY
			je Top_Of_Loop

		playE:
			mov eax, 41		;base freq
			mov DWORD[note], 'E'
			mov DWORD[flag], 0

			mov DWORD[xpos], 2
			mov DWORD[ypos], 9
			mov esi, 2
			cmp DWORD[key], LOWE
			je Top_Of_Loop

			mov DWORD[xpos], 38
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], EKEY
			je Top_Of_Loop

		playF:
			mov eax, 44		;base freq
			mov DWORD[note], 'F'
			mov DWORD[flag], 0

			mov DWORD[xpos], 8
			mov DWORD[ypos], 9
			mov esi, 2
			cmp DWORD[key], LOWF
			je Top_Of_Loop

			mov DWORD[xpos], 43
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], FKEY
			je Top_Of_Loop

		playG:
			mov eax, 49		;base freq
			mov DWORD[note], 'G'
			mov DWORD[flag], 0

			mov DWORD[xpos], 13
			mov DWORD[ypos], 9
			mov esi, 2
			cmp DWORD[key], LOWG
			je Top_Of_Loop

			mov DWORD[xpos], 48
			mov DWORD[ypos], 9
			mov esi, 3
			cmp DWORD[key], GKEY
			je Top_Of_Loop

		playBlackA:
			mov eax, 29		;base freq
			mov DWORD[note], 'B'
			mov DWORD[flag], 1		; 1 means flat

			mov DWORD[xpos], 20
			mov DWORD[ypos], 3
			mov esi, 3
			cmp DWORD[key], BLACKA
			je Top_Of_Loop

		playBlackC:
			mov eax, 35		;base freq
			mov DWORD[note], 'D'
			mov DWORD[flag], 1

			mov DWORD[xpos], 30
			mov DWORD[ypos], 3
			mov esi, 3
			cmp DWORD[key], BLACKC
			je Top_Of_Loop

		playBlackD:
			mov eax, 39		;base freq
			mov DWORD[note], 'E'
			mov DWORD[flag], 1

			mov DWORD[xpos], 1
			mov DWORD[ypos], 3
			mov esi, 2
			cmp DWORD[key], BLACKD
			je Top_Of_Loop

			mov DWORD[xpos], 35
			mov DWORD[ypos], 3
			mov esi, 3
			cmp DWORD[key], BLACKMIDD
			je Top_Of_Loop

		playBlackF:
			mov eax, 46		;base freq
			mov DWORD[note], 'G'
			mov DWORD[flag], 1

			mov DWORD[xpos], 10
			mov DWORD[ypos], 3
			mov esi, 2
			cmp DWORD[key], BLACKF
			je Top_Of_Loop

			mov DWORD[xpos], 45
			mov DWORD[ypos], 3
			mov esi, 3
			cmp DWORD[key], BLACKMIDF
			je Top_Of_Loop

		playBlackG:
			mov eax, 52		;base freq
			mov DWORD[note], 'A'
			mov DWORD[flag], 1

			mov DWORD[xpos], 15
			mov DWORD[ypos], 3
			mov esi, 2
			cmp DWORD[key], BLACKG
			je Top_Of_Loop

			mov DWORD[xpos], 50
			mov DWORD[ypos], 3
			mov esi, 3
			cmp DWORD[key], BLACKMIDG
			je Top_Of_Loop

		Top_Of_Loop:
		mov edi, 2
		mov DWORD[count], 0
			Little_Loop:
			cmp DWORD[count], esi
			je End_Of_Loop
			mul edi
			inc DWORD[count]
			jmp Little_Loop
			End_Of_Loop:
		mov DWORD[freq], eax
		jmp input_end

		;beep here????


		input_end:


	jmp		game_loop
	game_loop_end:

	; restore old terminal functionality
	call raw_mode_off

	;***************CODE ENDS HERE*****************************
	popa
	mov		eax, 0
	leave
	ret

; === FUNCTION ===
raw_mode_on:

	push	ebp
	mov		ebp, esp

	push	raw_mode_on_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
raw_mode_off:

	push	ebp
	mov		ebp, esp

	push	raw_mode_off_cmd
	call	system
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
init_board:

	push	ebp
	mov		ebp, esp

	; FILE* and loop counter
	; ebp-4, ebp-8
	sub		esp, 8

	; open the file
	push	mode_r
	push	board_file
	call	fopen
	add		esp, 8
	mov		DWORD [ebp-4], eax

	; read the file data into the global buffer
	; line-by-line so we can ignore the newline characters
	mov		DWORD [ebp-8], 0
	read_loop:
	cmp		DWORD [ebp-8], HEIGHT
	je		read_loop_end

		; find the offset (WIDTH * counter)
		mov		eax, WIDTH
		mul		DWORD [ebp-8]
		lea		ebx, [board + eax]

		; read the bytes into the buffer
		push	DWORD [ebp-4]
		push	WIDTH
		push	1
		push	ebx
		call	fread
		add		esp, 16

		; slurp up the newline
		push	DWORD [ebp-4]
		call	fgetc
		add		esp, 4

	inc		DWORD [ebp-8]
	jmp		read_loop
	read_loop_end:

	; close the open file handle
	push	DWORD [ebp-4]
	call	fclose
	add		esp, 4

	mov		esp, ebp
	pop		ebp
	ret

; === FUNCTION ===
render:

	push	ebp
	mov		ebp, esp

	; two ints, for two loop counters
	; ebp-4, ebp-8
	sub		esp, 8

	; clear the screen
	push	clear_screen_cmd
	call	system
	add		esp, 4

	; print the help information
	push	help_str
	call	printf
	add		esp, 4



	; outside loop by height
	; i.e. for(c=0; c<height; c++)
	mov		DWORD [ebp-4], 0
	y_loop_start:
	cmp		DWORD [ebp-4], HEIGHT
	je		y_loop_end

		; inside loop by width
		; i.e. for(c=0; c<width; c++)
		mov		DWORD [ebp-8], 0
		x_loop_start:
		cmp		DWORD [ebp-8], WIDTH
		je 		x_loop_end

                        ; check if (xpos,ypos)=(x,y)
                        mov             eax, [xpos]
                        cmp             eax, DWORD [ebp-8]
                        jne             check_flat
                        mov             eax, [ypos]
                        cmp             eax, DWORD [ebp-4]
                        jne             check_flat
				mov eax, [note]
                                push    eax
                                jmp             print_end

			check_flat:
                        ; check if (xpos,ypos)=(x+1,y)
			mov eax, DWORD[flag]
			cmp eax, 1
			jne print_board

                        mov             eax, [xpos]
			mov 		ebx, DWORD[ebp-8]
			dec		ebx
                        cmp             eax, ebx
                        jne             print_board
                        mov             eax, [ypos]
                        cmp             eax, DWORD [ebp-4]
                        jne             print_board
                             ; if both were equal, print the player
				mov eax, [xpos]
				dec eax
				mov DWORD[xpos], eax
				mov eax, [flat]
				mov DWORD[flag], 0
                                push    eax
                               jmp             print_end

			print_board:
				; otherwise print whatever's in the buffer
				mov		eax, [ebp-4]
				mov		ebx, WIDTH
				mul		ebx
				add		eax, [ebp-8]
				mov		ebx, 0
				mov		bl, BYTE [board + eax]
				push	ebx
			print_end:
			call	putchar
			add		esp, 4

		end:
		inc		DWORD [ebp-8]
		jmp		x_loop_start
		x_loop_end:

		; write a carriage return (necessary when in raw mode)
		push	0x0d
		call 	putchar
		add		esp, 4

		; write a newline
		push	0x0a
		call	putchar
		add		esp, 4

	inc		DWORD [ebp-4]
	jmp		y_loop_start
	y_loop_end:


	push DWORD[dur]
	push DWORD[freq]
	call beep
	add esp, 8

;	push	note
;	call	printf
;	add		esp, 4

;	mov eax, DWORD[flag]
;	cmp eax, 1
;	jne new_line
;		push	flat
;		call	printf
;		add	esp, 4
;		mov DWORD[flag], 0

;	new_line:


	mov		esp, ebp
	pop		ebp
	ret





; === FUNCTION ===
nonblocking_getchar:

; returns -1 on no-data
; returns char on succes

; magic values
%define F_GETFL 3
%define F_SETFL 4
%define O_NONBLOCK 2048
%define STDIN 0

	push	ebp
	mov		ebp, esp

	; single int used to hold flags
	; single character (aligned to 4 bytes) return
	sub		esp, 8

	; get current stdin flags
	; flags = fcntl(stdin, F_GETFL, 0)
	push	0
	push	F_GETFL
	push	STDIN
	call	fcntl
	add		esp, 12
	mov		DWORD [ebp-4], eax

	; set non-blocking mode on stdin
	; fcntl(stdin, F_SETFL, flags | O_NONBLOCK)
	or		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	call	getchar
	mov		DWORD [ebp-8], eax

	; restore blocking mode
	; fcntl(stdin, F_SETFL, flags ^ O_NONBLOCK
	xor		DWORD [ebp-4], O_NONBLOCK
	push	DWORD [ebp-4]
	push	F_SETFL
	push	STDIN
	call	fcntl
	add		esp, 12

	mov		eax, DWORD [ebp-8]

	mov		esp, ebp
	pop		ebp
	ret


