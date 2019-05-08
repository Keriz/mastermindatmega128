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
.org OVF0addr
	rjmp ovf0

.include "msm.asm"


.dseg
.org MATRIX_RAM ;defined in msm.asm
;value found in atmega128 datasheet page 19
; usage: https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_directives.html#avrassembler.wb_directives.ORG
;memory starts at location 0x100

matrix_colors: .byte n_LEDS ;defined in msm.asm
msm_code: .byte 0x04; code is composed of 4 colors
num_move: .byte 1;save the number of the current move
color_plus_counter: .byte 1
color_minus_counter: .byte 1
column_minus_counter: .byte 1
column_plus_counter: .byte 1

.cseg
reset:
	LDSP	RAMEND
	rcall	ws2812b4_init
	OUTI DDRD, 0x00 ; DDRD as input
	OUTI DDRB, 0xff

	; Set Interrupt to trigger when rising edge
	ldi r16, (0<<ISC31)|(0<<ISC30)|(0<<ISC21)|(0<<ISC20)|(0<<ISC11)|(0<<ISC10)|(0<<ISC01)|(0<<ISC00)
	sts EICRA, r16			 

	ldi r16, (0<<INT0)|(0<<INT1)|(0<<INT2)|(0<<INT3)
	out EIMSK, r16

	ldi r16, 0x00
	sts EIFR, r16

	
	;configure Timer 0 interrupt
	OUTI TCCR0,(0<<CS02)|(1<<CS01)|(1<<CS00)
	OUTI ASSR, (1<<AS0)
	OUTI TIMSK, (1<<TOIE0)

	; enable interrupt flag
	sei

	rcall msm_clear_matrix
	rcall msm_LED_disp

	ldi XH, high(num_move)
    ldi XL, low(num_move)
	ldi a0, 0x00 ;move number 0
	st x, a0

	ldi yh, 0x00 ; pointing to row 0
	ldi yl, 0x00 ; pointing to column 0

main:
	; test the different colors

	/*ldi a0, 0x00
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	rcall ws2812b4_reset*/
	ldi XH, high(color_plus_counter)
    ldi XL, low(color_plus_counter)
	ldi r17, TIMER_NB_CNT

	ld r16, x ; check button color_plus ; maybe we should do a macro
	cp r16, r17
	brlo no_color_plus
	ldi r16, 0x00
	st x, r16
	rcall color_plus
	no_color_plus:

	inc xl ; check button color_minus 
	ld r16, x
	cp r16, r17
	brlo no_color_minus
	ldi r16, 0x00
	st x, r16
	rcall color_minus
	no_color_minus:

	inc xl ; check button column_minus 
	ld r16, x
	cp r16, r17
	brlo no_column_minus
	ldi r16, 0x00
	st x, r16
	rcall column_minus
	no_column_minus:

	inc xl ; check button column_plus
	ld r16, x
	cp r16, r17
	brlo no_column_plus
	ldi r16, 0x00
	st x, r16
	rcall column_plus
	no_column_plus:

	WAIT_US 1000

	;disable timer
	cli
	rcall msm_LED_disp
	sei

	;if validate button is on and wasnt on before (no interrupt)
	;waslowbefore=false
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

	;if validate button is low
	;waslowbefore=true

    rjmp main

ovf0:
	;save SREG and registers
	push a0
	push a1
	push a2
	push xl
	push xh
	;too many instructions maybe
	;for loop to be added

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
	st x, a0

	pop xh
	pop xl
	pop a2
	pop a1
	pop a0
reti

color_plus:
	;save sreg??
	push r16
	push XL
	push XH
	ldi XH, high(MATRIX_RAM)
    ldi XL, low(MATRIX_RAM)
	add xl, yl; add offset
	ld r16, x
	cpi r16, MIN_COLOR
	brne next_plus
	ldi r16, MAX_COLOR
	next_plus:
	dec r16
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
	ldi yl, MAX_COLUMN
	next_colu_minus:
ret

column_plus:
	;save sreg? & working registers
	inc yl
	cpi yl, MAX_COLUMN + 1
	brne next_colu_plus
	ldi yl, 0x00
	next_colu_plus:
ret
