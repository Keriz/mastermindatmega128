;MICROCONTROLEURS PROJET BA4
; main.asm
;
; Created: 4/25/2019 9:59:59 PM
; Author : guillaume.thivolet and fahradin.mujovi
;
;Entry point of the program, this file includes the main game loop.
.equ TIMER_NB_CNT = 0x01
.equ MAX_COLOR = 0x08
.equ MIN_COLOR = 0x00
.equ MAX_COLUMN = 0x04

.cseg
.org 0x0000			; memory (PC) location of reset handler
	rjmp reset
.org OVF2addr
	rjmp ovf2
.org OVF0addr
	rjmp ovf0

.include "msm.asm"
.include "lcd.asm"
.include "printf.asm"

.dseg
.org MATRIX_RAM ;defined in msm.asm
;value found in atmega128 datasheet page 19
; usage: https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_directives.html#avrassembler.wb_directives.ORG
;memory starts at location 0x100

matrix_colors:			.byte n_LEDS;defined in msm.asm
msm_code:				.byte 0x04	; code is composed of 4 colors
msm_code_result_flags:	.byte 0x04
num_move:				.byte 1		;save the number of the current move
random_num:				.byte 2
win:					.byte 1
color_plus_counter:		.byte 1
color_minus_counter:	.byte 1
column_minus_counter:	.byte 1
column_plus_counter:	.byte 1
validate_counter:		.byte 1
reset_counter:			.byte 1

.cseg
reset:
	LDSP	RAMEND
	rcall	ws2812b4_init
	OUTI	DDRD, 0x00 ; DDRD as input
	OUTI	DDRB, 0xff
	OUTI	PORTB, 0x00
	rcall	LCD_init

	;configure Timer 0 & 2 interrupt
	OUTI	TCCR0,	(0<<CS02)|(1<<CS01)|(1<<CS00)
	OUTI	TCCR0,	(0<<CS22)|(0<<CS21)|(1<<CS20)
	OUTI	ASSR,	(1<<AS0)
	OUTI	TIMSK,	(1<<TOIE0)|(1<<TOIE2)

	sei

	rcall	msm_clear_matrix
	rcall	msm_LED_disp

	ldi		XH, high(num_move)					;set move number to 0
    ldi		XL, low(num_move)
	ldi		a0, 0x00
	st		x, a0

	ldi		XH, high(msm_code_result_flags)		;init the result flags
    ldi		XL, low(msm_code_result_flags)
	ldi		a0, 0x00			
	st		x+, a0
	st		x+, a0
	st		x+,	a0
	st		x,	a0

	ldi		yh, 0x00 ; pointing to row 0
	ldi		yl, 0x00 ; pointing to column 0

	ldi		XH, high(validate_counter)
    ldi		XL, low(validate_counter)

	game_not_started:
	ldi		r17,0; TIMER_NB_CNT
	ld		r16, x ; check button validate 
	cp		r16, r17
	brlo	game_not_started
	ldi		r16, 0x00
	st		x, r16
	OUTI	TIMSK,	(1<<TOIE0)|(0<<TOIE2)		;deactivate number generation

main:
	ldi		XH, high(color_plus_counter)
    ldi		XL, low(color_plus_counter)
	ldi		r17, 0;TIMER_NB_CNT

	ld		r16, x ; check button color_plus ; maybe we should do a macro
	cp		r16, r17
	brlo	no_color_plus
	ldi		r16, 0x00
	st		x, r16
	rcall	color_plus
	no_color_plus:

	inc		xl ; check button color_minus 
	ld		r16, x
	cp		r16, r17
	brlo	no_color_minus
	ldi		r16, 0x00
	st		x, r16
	rcall	color_minus
	no_color_minus:

	ldi		r17, 0x00 ;0.5s to switch columns & validate
	inc		xl ; check button column_minus 
	ld		r16, x
	cp		r16, r17
	brlo	no_column_minus
	ldi		r16, 0x00
	st		x, r16
	rcall	column_minus
	no_column_minus:
	
	inc xl ; check button column_plus
	ld		r16, x
	cp		r16, r17
	brlo	no_column_plus
	ldi		r16, 0x00
	st		x, r16
	rcall	column_plus
	no_column_plus:

	inc		xl ;check button validate
	ld		r16, x
	cp		r16, r17
	brlo	no_validate
	ldi		r16, 0x00
	st		x, r16
	rcall	validate
	no_validate:

	WAIT_US 1000

	;disable timer
	cli
	rcall	msm_LED_disp
	sei
	
	;if validate button is on and wasnt on before (no interrupt)
		;compute the comparison
		;set the result in the game matrix
		;display game matrix
		;if coup=derniercoup (7)
			;LCD string indice = GAGNE OU PERDU
			;display LCD string
		;wait for the next validate input press to start the game again and rjmp to reset
		;else
			;LCD string = coup num: X
			;display LCD string

    rjmp main

ovf2:
	ldi		XH, high(random_num)
    ldi		XL, low(random_num)
	ld		r16, x
	inc		r16
	st		x+, r16
	ld		r16, x
	inc		r16
	st		x, r16
reti

ovf0:
	;save SREG and registers
	in _sreg, SREG
	push a0
	push a1
	push a2
	push xl
	push xh
	;too many instructions maybe
	;for loop to be added

	;random number (1-7) generation

	in a1, PIND
	ldi XH, high(color_plus_counter)
    ldi XL, low(color_plus_counter)
	
	ld a0, x
	ldi a2, 0x01;button state wanted
	andi a1, 0x01
	cpse a1, a2
	inc a0
	ldi a2, 0x00
	cpse a1, a2
	ldi a0, 0x00
	st x+, a0
	
	in a1, PIND
	ld a0, x
	ldi a2, 0x02;button state wanted
	andi a1, 0x02;mask
	cpse a1, a2
	inc a0
	ldi a2, 0x00
	cpse a1, a2
	ldi a0, 0x00
	st x+, a0

	in a1, PIND
	ld a0, x
	ldi a2, 0x04
	andi a1, 0x04
	cpse a1, a2
	inc a0
	ldi a2, 0x00
	cpse a1, a2
	ldi a0, 0x00
	st x+, a0

	in a1, PIND
	ld a0, x
	ldi a2, 0x08
	andi a1, 0x08
	cpse a1, a2
	inc a0
	ldi a2, 0x00
	cpse a1, a2
	ldi a0, 0x00
	st x+, a0

	in a1, PIND
	ld a0, x
	ldi a2, 0x10 ;=16
	andi a1, 0x10
	cpse a1, a2
	inc a0
	ldi a2, 0x00
	cpse a1, a2
	ldi a0, 0x00
	st x, a0
	
	pop xh
	pop xl
	pop a2
	pop a1
	pop a0
	out SREG,_sreg
reti

color_plus:
	;save sreg??
	push r16
	push XL
	push XH
	ldi XH, high(MATRIX_RAM)
    ldi XL, low(MATRIX_RAM)
	add xl, yl				; add offset
	ld r16, x
	dec r16
	cpi r16, 0xff
	brne black
	ldi r16, MAX_COLOR - 1
	black:
	cpi r16, 0x00
	brne next_plus
	ldi r16, MAX_COLOR - 1
	next_plus:
	st x, r16
	pop XH
	pop XL
	pop r16
ret

color_minus:
	;save sreg? & working registers
	push r16
	push XL
	push XH
	ldi XH, high(MATRIX_RAM);
    ldi XL, low(MATRIX_RAM);
	add xl, yl; switch column
	;TODO add row offset
	ld r16, x;
	inc r16
	cpi r16, MAX_COLOR
	brne next_minus
	ldi r16, MIN_COLOR + 1
	next_minus:
	st X, r16
	pop XH
	pop XL
	pop r16
ret

column_minus:
	;save sreg? & working registers
	dec yl
	cpi yl, 0xff ; MIN COLUMN - 1
	brne next_colu_minus
	ldi yl, MAX_COLUMN - 1 ;starts at 0
	next_colu_minus:
ret

column_plus:
	;save sreg? & working registers
	inc yl
	cpi yl, MAX_COLUMN 
	brne next_colu_plus
	ldi yl, 0x00
	next_colu_plus:
ret


extract_random_num:
	ldi		XH, high(random_num)
    ldi		XL, low(random_num)
	ld		r17, x

	mov r16, r17
	andi	r16, 0b00000111
	inc		r16						; -> be sure that it wont be black
	mov		a0, r16					;assign first code color

	mov r16, r17
	lsr r16
	lsr r16
	lsr r16
	andi	r16, 0b00000111
	inc		r16						; -> be sure that it wont be black
	andi	r16, 0b00000111
	mov		a0, r16					;assign first code color

	mov r16, r17
	andi	r16, 0b00000111
	inc		r16						; -> be sure that it wont be black
	andi	r16, 0b00000111			;remove possible overflow
	mov		a0, r16					;assign first code color

	mov r16, r17
	andi	r16, 0b00000111
	inc		r16						; -> be sure that it wont be black
	mov		a0, r16					;assign first code color

	ldi		a1, 0x02 ;move number 0
	ldi		a2, 0x03				;
	ldi		a3, 0x04				
	st		x+, a0
	st		x+, a1
	st		x+,	a2
	st		x,	a3

ret

validate:
	;save sreg? & working registers
	push	xl
	push	xh
	push	r16
	push	r17
	ldi		XH, high(num_move)
	ldi		XL, low(num_move)
	ld		r16, x
	rcall	msm_comp_colors ;fait rien pour le moment
	cpi		r16, 0x08	;if round == dernier (8)
	brne	game_notlose
	rcall	LCD_clear
	PRINTF	LCD_putc
	.db		"PERDU", 0
	;RESET GAME
	game_notlose:
	rcall	set_win
	ldi		XH, high(win)
	ldi		XL, low(win)
	ld		r17, x
	cpi		r17, 0x00 ;compare si pas encore win
	breq	game_notover
	rcall	LCD_clear	;ajouté
	PRINTF	LCD_putc
	.db		"GAGNE", 0	;display win
	;reset game after x time or x button pressed
	game_notover:
	;push	xl
	;push	xh
	push	a0
	push	a1
	ldi		XH, high(num_move)
	ldi		XL, low(num_move)
	ld		a0, x
	ldi		a1, 0x00
	rcall	LCD_clear	
	PRINTF	LCD_putc
	.db		"Move Num:", FDEC2,a, 0	;display num_move
	inc		a1
	st		X, a0		
	pop		a1
	pop		a0
	;pop	xh
	;pop	xl
	;inc	yh	;passe à la ligne d'après.
	pop		r17
	pop		r16
	pop		xh
	pop		xl
ret

set_win:
	push	xl
	push	xh
	push	r16
	push	r17

	ldi		yl, low(msm_code_result_flags)		;result flags for color comparison output
	ldi		yh, high(msm_code_result_flags)
	ld		b0, y
	ldd		b1, y+1
	ldd		b2, y+2
	ldd		b3, y+3

	cpi		b0, 0x06
	brne	not_win
	cpi		b1, 0x06
	brne	not_win
	cpi		b2, 0x06
	brne	not_win
	cpi		b3, 0x06
	brne	not_win
	ldi		XH, high(win)
	ldi		XL, low(win)
	ldi		r16, 0x01
	st		x, r16
	not_win:
	pop		r17
	pop		r16
	pop		xh
	pop		xl
ret
	;if validate button is on and wasnt on before (no interrupt)
		;compute the comparison
		;set the result in the game matrix
		;display game matrix
		;if coup=derniercoup (7)
			;LCD string indice = PERDU
			;display LCD string
		;elif win == 1
			;LCD string indice = GAGNE
			;display LCD string
		;wait for the next validate input press to start the game again and rjmp to reset
		;else
			;LCD string = coup num: X
			;display LCD string