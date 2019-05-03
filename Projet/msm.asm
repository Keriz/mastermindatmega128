/*
 * msm.asm
 *
 *  Created: 5/3/2019 7:31:33 PM
 *   Author: guillaume.thivolet
 */ 

.include ws2b3_driver.asm

;msm_LED_disp		; arg: void; used: TODO
; purpose: display the game state to the LED matrix
msm_LED_disp:
	;for loop over the memory (matrix_colors) (FROM END TO BEGINNING)
	;load color from lookup (ws2812b4_ld_colors)
	;display the color (rcall ws2812b4_byte3wr )
	rcall ws2812b4_reset ;display the matrix

;msm_comp_colors	; arg: r16, r17, r18, r19 (=input colors); used: r22, r23, r24, r25 (w) (=output)
;purpose: Compares the input color combination (each in GRB) and outputs the games results (right side of the matrix).
msm_comp_colors:
	;the output has to be put directly into the SRAM at the right spot
