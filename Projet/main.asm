;MICROCONTROLEURS PROJET BA4
; main.asm
;
; Created: 4/25/2019 9:59:59 PM
; Author : guillaume.thivolet and fahradin.mujovi
;
;Entry point of the program, this file includes the main game loop.
.cseg
.org 0x0000			; memory (PC) location of reset handler
	rjmp reset
.org INT0addr
	rjmp interrupt_color_minus
.org INT1addr
	rjmp interrupt_color_plus
.org INT2addr
	rjmp interrupt_column_minus
.org INT3addr
	rjmp interrupt_column_plus

.include "msm.asm"

;to implement; all the interrupts

.dseg
.org MATRIX_RAM ;defined in msm.asm
;value found in atmega128 datasheet page 19
; usage: https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_directives.html#avrassembler.wb_directives.ORG
;memory starts at location 0x100

matrix_colors: .byte n_LEDS ;defined in msm.asm
msm_code: .byte 0x04; code is composed of 4 colors
num_move: .byte 1;save the number of the current move

.cseg
reset:
	LDSP	RAMEND
	rcall	ws2812b4_init
	OUTI DDRD, 0x00 ; DDRD as input
	ldi r16, 0x00
	out DDRB, r16 ; DDRB as input
	sei ; enable interrupt flag

	; Set Interrupt to trigger when rising edge
	ldi r16, (0<<ISC31)|(0<<ISC30)|(0<<ISC21)|(0<<ISC20)|(0<<ISC11)|(0<<ISC10)|(0<<ISC01)|(0<<ISC00)
	sts EICRA, r16			 

	ldi r16, (1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
	sts EIMSK, r16

	rcall msm_clear_matrix
	rcall msm_LED_disp

	ldi XH, high(num_move)
    ldi XL, low(num_move)
	ldi a0, 0x00 ;move number 0
	st x, a0

main:
	; test the different colors
	ldi a0, 0x00
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x01
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x02
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x03
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x04
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x05
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x06
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	ldi a0, 0x07
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	/*ldi a0, 0x00
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr

	rcall ws2812b4_reset*/
	rcall msm_LED_disp

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

interrupt_column_plus:
	;save sreg & working registers

reti

interrupt_column_minus:
	;save sreg & working registers
	ldi XH, high(MATRIX_RAM)
    ldi XL, low(MATRIX_RAM)
	ldi a0, 0x01
	st X, a0
	ldi r16, 0xff
	out	PORTB,r16
reti

interrupt_color_plus:
	;save sreg & working registers

reti

interrupt_color_minus:
	;save sreg & working registers

reti

