;MICROCONTROLEURS PROJET BA4
; main.asm
;
; Created: 4/25/2019 9:59:59 PM
; Author : guillaume.thivolet and fahradin.mujovi
;
;Entry point of the project, this file includes the main game loop.
.equ SHORT_PRESS = 0x01
.equ LONG_PRESS = 0x02
.equ MAX_COLOR = 0x08
.equ MIN_COLOR = 0x00
.equ MAX_COLUMN = 0x04

.cseg
.org 0x0000			; memory (PC) location of reset handler
	rjmp reset		;in the datasheet, the use of jmp (not rjmp) is recommenced; should we modify it?
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

matrix_colors:			.byte n_LEDS	;defined in msm.asm
msm_code:				.byte 4			; code is composed of 4 colors
msm_code_result_flags:	.byte 4
num_move:				.byte 1			;save the number of the current move
random_num:				.byte 2
win:					.byte 1
color_plus_counter:		.byte 1
color_minus_counter:	.byte 1
column_plus_counter:	.byte 1
column_minus_counter:	.byte 1
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
	OUTI	TCCR2,	(0<<CS22)|(0<<CS21)|(1<<CS20)
	OUTI	ASSR,	(1<<AS0)
	OUTI	TIMSK,	(0<<TOIE0)|(0<<TOIE2)	;init done, start the timers
	
	rcall	msm_clear_matrix
	rcall	msm_LED_disp

	LDIX	num_move						;set move number to 1
	ldi		a0, 0x01
	st		x, a0

	LDIX	win								;int win flag to 0
	ldi		a0, 0x00
	st		x, a0

	rcall	reset_flags

	ldi		yh, 0x00						; pointing to row 0
	ldi		yl, 0x00						; pointing to column 0

	LDIX	validate_counter

	rcall	LCD_clear		
	PRINTF	LCD_putc
	.db		"PRESS VALID. TO",0
	ldi		a0, 0x40						;point to second LCD row
	rcall	LCD_pos
	PRINTF	LCD_putc
	.db		"START THE GAME ",0

	sei
	OUTI	TIMSK,	(1<<TOIE0)|(1<<TOIE2)	;init done, start the timers!

	game_not_started:
	ldi		r17, LONG_PRESS
	ld		r16, x							; check if button validate was pressed
	cp		r16, r17
	brlo	game_not_started
	ldi		r16, 0x00
	st		x, r16

	OUTI	TIMSK,	(1<<TOIE0)|(0<<TOIE2)	;deactivate rand_num generation

	rcall	msm_clear_matrix
	rcall	msm_LED_disp
	rcall	extract_random_num

	rcall	LCD_clear		
	PRINTF	LCD_putc
	.db		"Move Num:1 ",0

main: 
	LDIX	color_plus_counter
	ldi		r17, SHORT_PRESS

	ld		r16, x ; check button color_plus ; maybe we should do a macro
	cp		r16, r17
	brlo	no_color_plus
	ldi		r16, 0x00
	st		x, r16
	rcall	color_plus
	no_color_plus:

	inc		xl				 ; check button color_minus 
	ld		r16, x
	cp		r16, r17
	brlo	no_color_minus
	ldi		r16, 0x00
	st		x, r16
	rcall	color_minus
	no_color_minus:

	inc		xl				; check button column_plus
	ld		r16, x
	cp		r16, r17
	brlo	no_column_plus
	ldi		r16, 0x00
	st		x, r16
	rcall	column_plus
	no_column_plus:

	inc		xl				; check button column_minus 
	ld		r16, x
	cp		r16, r17
	brlo	no_column_minus
	ldi		r16, 0x00
	st		x, r16
	rcall	column_minus
	no_column_minus:

	ldi		r17, LONG_PRESS
	inc		xl				;check button validate
	ld		r16, x
	cp		r16, r17
	brlo	no_validate
	ldi		r16, 0x00
	st		x, r16
	rcall	validate
	no_validate:
	
	inc		xl ;check button reset
	ld		r16, x
	cp		r16, r17
	brlo	no_reset
	ldi		r16, 0x00
	st		x, r16
	rjmp	reset	
	no_reset:
	
	WAIT_US 1000

	cli
	rcall	msm_LED_disp
	sei

    rjmp	main

ovf2:
	in		_sreg, SREG
	push	r16
	PUSHX

	LDIX	random_num
	ld		r16, x
	inc		r16
	st		x+, r16
	cpi		r16, 0x00		;maybe ovf flag is set in the previous inc, just to be sure
	brne    ovf_rand
	ld		r16, x
	inc		r16
	st		x, r16
	ovf_rand:

	POPX
	pop		r16
	out		SREG,_sreg
reti

ovf0:
	;save SREG and registers
	in		_sreg, SREG
	push	a0
	push	a1
	push	a2
	PUSHX
	;too many instructions maybe
	;for loop to be added

	LDIX	color_plus_counter

	in		a1, PIND			;could do a macro
	ld		a0, x
	ldi		a2, 0x01			;button state wanted
	andi	a1, 0x01
	cpse	a1, a2
	inc		a0
	ldi		a2, 0x00
	cpse	a1, a2
	ldi		a0, 0x00
	st		x+, a0
	
	in		a1, PIND
	ld		a0, x
	ldi		a2, 0x02;button state wanted
	andi	a1, 0x02;mask
	cpse	a1, a2
	inc		a0
	ldi		a2, 0x00
	cpse	a1, a2
	ldi		a0, 0x00
	st		x+, a0

	in		a1, PIND
	ld		a0, x
	ldi		a2, 0x04
	andi	a1, 0x04
	cpse	a1, a2
	inc		a0
	ldi		a2, 0x00
	cpse	a1, a2
	ldi		a0, 0x00
	st		x+, a0

	in		a1, PIND
	ld		a0, x
	ldi		a2, 0x08
	andi	a1, 0x08
	cpse	a1, a2
	inc		a0
	ldi		a2, 0x00
	cpse	a1, a2
	ldi		a0, 0x00
	st		x+, a0

	in		a1, PIND
	ld		a0, x
	ldi		a2, 0x10 ;=16
	andi	a1, 0x10
	cpse	a1, a2
	inc		a0
	ldi		a2, 0x00
	cpse	a1, a2
	ldi		a0, 0x00
	st		x+, a0
	
	in		a1, PIND
	ld		a0, x
	ldi		a2, 0x20 ;=32
	andi	a1, 0x20
	cpse	a1, a2
	inc		a0
	ldi		a2, 0x00
	cpse	a1, a2
	ldi		a0, 0x00
	st		x, a0
	
	POPX
	pop		a2
	pop		a1
	pop		a0
	out		SREG,_sreg
reti

color_plus:
	;save sreg??
	push	r16
	PUSHX

	LDIX	MATRIX_RAM
	add		xl, yl					; column offset
	ADD8T	xl, yh					; add row offset

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

	POPX
	pop r16
ret

color_minus:
	;save sreg? & working registers
	push	r16
	PUSHX

	LDIX	MATRIX_RAM
	add		xl, yl					; column offset
	ADD8T	xl, yh					; add row offset

	ld		r16, x
	inc		r16
	cpi		r16, MAX_COLOR
	brne	next_minus
	ldi		r16, MIN_COLOR + 1
	next_minus:
	st		x, r16

	POPX
	pop		r16
ret

column_minus:
	;save sreg?
	dec		yl
	cpi		yl, 0xff			;MIN COLUMN - 1
	brne	next_colu_minus
	ldi		yl, MAX_COLUMN - 1	;starts at 0
	next_colu_minus:
ret

column_plus:
	;save sreg?
	inc		yl
	cpi		yl, MAX_COLUMN 
	brne	next_colu_plus
	ldi		yl, 0x00
	next_colu_plus:
ret


extract_random_num:
	;no need to push, pop: only called in reset
	LDIX	random_num

	ld		r17, x+
	ldi		r18, color_white		;could do a macro
	mov		r16, r17
	andi	r16, 0b00000111
	cpse	r16, r18
	inc		r16						; -> be sure that it wont be black
	mov		a0, r16					;assign first code color

	mov		r16, r17
	DIV8	r16						;take bits from 3 to 6
	andi	r16, 0b00000111
	cpse	r16, r18
	inc		r16						; -> be sure that it wont be black
	mov		a1, r16					;assign second code color

	ld		r17, x						;use byte 2
	mov		r16, r17
	andi	r16, 0b00000111
	cpse	r16, r18
	inc		r16							; -> be sure that it wont be black
	mov		a2, r16						;assign third code color

	mov		r16, r17
	DIV8	r16							;take bits from 3 to 6
	andi	r16, 0b00000111
	cpse	r16, r18
	inc		r16							; -> be sure that it wont be black
	mov		a3, r16						;assign first code color

	LDIX	msm_code
	st		x+, a0
	st		x+, a1
	st		x+,	a2
	st		x,	a3
	
ret

;compute flags
;check if player won
;display game matrix
;if coup=derniercoup (7)
	;LCD string indice = GAGNE OU PERDU
	;display LCD string
;wait for the next validate input press to start the game again and rjmp to reset
;else
	;LCD string = coup num: X
	;display LCD string
validate:
	;save sreg? & working registers
	PUSHX
	push	r16
	push	r17

	rcall	msm_comp_colors				;set flags in memory
	rcall	set_win
	rcall	reset_flags					;for the next move, if any
	
	LDIX	win
	ld		r17, x
	cpi		r17, 0x00					;compare if not win yet
	breq	game_notover

	rcall	LCD_clear		
	PRINTF	LCD_putc
	.db		"WIN,PRESS RESET", 0					;display win

freeze_game:
	rcall print_code

	cli									;no timer interrupt while displaying colors
	rcall	msm_LED_disp
	sei

	LDIX	reset_counter
	ldi		r17, 0x02 ; 0.5s

	no_reset_endgame:
	ld		r16, x						; check button reset
	cp		r16, r17
	brlo	no_reset_endgame
	ldi		r16, 0x00
	st		x, r16
	rjmp	reset

game_notover:
	LDIX	num_move
	ld		r16, x			
	cpi		r16, 0x08					;if move == last (8)
	brne	game_continue
	rcall	LCD_clear
	PRINTF	LCD_putc
	.db		"LOST,PRESS RESET ", 0
	rjmp	freeze_game

game_continue:
	push	a0							;not necessarily needed
	push	a1
	LDIX	num_move
	ld		a0, x
	inc		a0
	rcall	LCD_clear	
	PRINTF	LCD_putc
	.db		"Move Num:", FDEC2, a, 0	;display num_move
	st		X, a0
	inc		yh							;go to next row
	pop		a1
	pop		a0

	pop		r17
	pop		r16
	POPX
ret

set_win:
	PUSHX
	PUSHY
	push	r16
	push	b0
	push	b1
	push	b2
	push	b3

	LDIY	msm_code_result_flags		;result flags for color comparison output
	ld		b0, y
	ldd		b1, y+1	
	ldd		b2, y+2
	ldd		b3, y+3

	cpi		b0, color_green
	brne	not_win
	cpi		b1, color_green
	brne	not_win
	cpi		b2, color_green
	brne	not_win
	cpi		b3, color_green
	brne	not_win
	LDIX	win
	ldi		r16, 0x01					;boolean
	st		x, r16

	not_win:

	pop		b3
	pop		b2
	pop		b1
	pop		b0
	pop		r16
	POPY
	POPX
ret

print_code:
	;save registers and sreg?
	ldi		a0, 0x40					;point to second LCD row
	rcall	LCD_pos
	PRINTF	LCD_putc
	.db		"CODE:  ",0
	LDIX	msm_code		
	ld		a0, x+
	PRINTF	LCD
	.db		" ",FDEC,a,0
	ld		a0, x+
	PRINTF	LCD
	.db		" ",FDEC,a,0	
	ld		a0, x+
	PRINTF	LCD
	.db		" ",FDEC,a,0
	ld		a0, x	
	PRINTF	LCD
	.db		" ",FDEC,a,0
ret

reset_flags:
	LDIX	msm_code_result_flags
	ldi		a0, 0x00			
	st		x+, a0
	st		x+, a0
	st		x+,	a0
	st		x,	a0
ret