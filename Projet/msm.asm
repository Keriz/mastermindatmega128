/*
 * msm.asm
 *
 *  Created: 5/3/2019 7:31:33 PM
 *   Author: guillaume.thivolet
 */ 

.include "ws2b3_driver.asm"

.equ MATRIX_RAM = 0x100

.equ n_LEDS = 0x40 ;( 8x8 = 64 pixels to work with)

;msm_LED_disp		; arg: void; used: TODO
; purpose: display the game state to the LED matrix
msm_LED_disp:
	ldi b0, n_LEDS ; for loop i < 64 ;maybe r20 is not good because used as b0 later
	ldi XH, high(MATRIX_RAM)
	ldi XL, low(MATRIX_RAM)
;for loop over the memory (matrix_colors) (FROM END TO BEGINNING)
;load color from lookup (ws2812b4_ld_colors)
msm_LED_loop:
	ld a0, x+
	rcall ws2812b4_ld_colors
	rcall ws2812b4_byte3wr
	dec b0
	brne msm_LED_loop
	
	rcall ws2812b4_reset ;display the matrix
ret

;msm_comp_colors	; arg: r18, r19, r20, r21 (=input colors); used: r22, r23, r24, r25 (w) (=output)
;purpose: Compares the input color combination (each in GRB) and outputs the games results (right side of the matrix).
msm_comp_colors:
	;the output has to be put directly into the SRAM at the right spot
ret

msm_clear_matrix:
	ldi b0, n_LEDS
	ldi a0, 0x00 ; black
	ldi XH, high(MATRIX_RAM)
    ldi XL, low(MATRIX_RAM)
;for loop over the matrix and set everything to black
msm_clear_loop:
	st X+, a0
	dec b0
	brne msm_clear_loop
ret
