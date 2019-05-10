/*
 * msm.asm
 *
 *  Created: 5/3/2019 7:31:33 PM
 *   Author: guillaume.thivolet & fahradin.mujovi
 */ 

.include "ws2b3_driver.asm"

.equ MATRIX_RAM = 0x0100

.equ n_LEDS = 0x0040		;( 8x8 = 64 pixels to work with)

.equ CODE = 0x0140			;MATRIX_RAM + n_LEDS

.equ RESULTS = 0x0144		;MATRIX_RAM + n_LEDS + 0x04

.macro COMP_GREEN	; args: 
	push	r16
	push	r17
	push	r18
	push	r19
	mov		r16, YH					;keep track of row
	push	XL
	push	XH
	push	ZL
	push	ZH
	push	YL
	push	YH
	
	ldi		zl, low(CODE)			;z -> code
	ldi		zh, high(CODE)
	ldi		xl, low(MATRIX_RAM)
	ldi		xh, high(MATRIX_RAM)
	ldi		yl, low(RESULTS)
	ldi		yh, high(RESULTS)

	add		xl, r16				;offset row
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16

	subi	xl, -0x03
	subi	yl, -0x03
	subi	zl, -0x03

	ldi		r16, 0x03
	
comp_green_loop:
	ld		r18, z
	ld		r19, x
	cp		r18, r19				; compare code and user color
	brne	not_green
	ldi		r17, color_green
	st		y, r17					; put a green flag on this position
not_green:
	dec		zl
	dec		xl
	dec		yl
	dec		r16
	cpi		r16, 0xff
	brne	comp_green_loop

	pop		YH
	pop		YL
	pop		ZH
	pop		ZL
	pop		XH
	pop		XL
	pop		r19
	pop		r18
	pop		r17
	pop		r16
.endmacro

;msm_LED_disp		; arg: void; used: TODO
; purpose: display the game state to the LED matrix
msm_LED_disp:
	push	b0
	push	xh
	push	xl
	push	a0

	ldi		b0, n_LEDS				; for loop i < 64 ;maybe r20 is not good because used as b0 later
	ldi		XH, high(MATRIX_RAM)
	ldi		XL, low(MATRIX_RAM)
;for loop over the memory (matrix_colors) (FROM END TO BEGINNING)
;load color from lookup (ws2812b4_ld_colors)
msm_LED_loop:
	ld		a0, x+
	rcall	ws2812b4_ld_colors
	rcall	ws2812b4_byte3wr
	dec		b0
	brne	msm_LED_loop

	pop		a0
	pop		xl
	pop		xh
	pop		b0
	
	rcall	ws2812b4_reset			;display the matrix
ret

;msm_comp_colors	; arg: r18, r19, r20, r21 (=input colors); used: r22, r23, r24, r25 (w) (=output)
;purpose: Compares the input color combination (each in GRB) and outputs the games results (right side of the matrix).
msm_comp_colors:
	push	r16
	push	r17
	push	r18
	push	r19
	mov		r16, yh					;keep track of row
	push	xl
	push	xh
	push	zl
	push	zh
	push	yl
	push	yh

	;COMP_GREEN
	ldi		zl, low(CODE)			;z -> code
	ldi		zh, high(CODE)
	ldi		xl, low(MATRIX_RAM)
	ldi		xh, high(MATRIX_RAM)
	ldi		yl, low(RESULTS)
	ldi		yh, high(RESULTS)

	add		xl, r16				;offset row
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16

	subi	xl, -0x03
	subi	yl, -0x03
	subi	zl, -0x03

	push r16
	ldi		r16, 0x03
	
comp_green_loop:
	ld		r18, z
	ld		r19, x
	cp		r18, r19				; compare code and user color
	brne	not_green
	ldi		r17, color_green
	st		y, r17					; put a green flag on this position
not_green:
	dec		zl
	dec		xl
	dec		yl
	dec		r16
	cpi		r16, 0xff
	brne	comp_green_loop
	;verify if some colors are already well positioned
	
	ldi		ZH, high(CODE)
	ldi		ZL, low(CODE)			;z -> code
	ldi		XH, high(MATRIX_RAM)	;x -> user inputs
	ldi		XL, low(MATRIX_RAM)
	ldi		YH, high(RESULTS)
	ldi		YL, low(RESULTS)		;result flags for color comparison output

	pop		r16
	add		xl, r16					;offset row...
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	add		xl, r16
	
	ldi		r16, 0x04
	;pour i=3:0
		;si d_i != 3
			;pour k=3:0
				;si d_k !=3
					;check rouge
					;si rouge break

msm_comp_colors_loop_k:
 	dec		r16
	cpi		r16, 0xff
	breq	end_loop
	add		yl, r16					;add column offset to code  
	ld		r18, y					;load code color
	cpi		r18, color_green		;compare if code color is already green (=good color at good position)
	brne	not_di_green
	sub		yl, r16
	rjmp	msm_comp_colors_loop_k	;skip all checks, color is already good!
	not_di_green:
	sub		yl, r16					;remove code offset
	ldi		r17, 0x03
msm_comp_colors_loop_i:
	add		yl, r17					;add column offset to code
	ld		r18, y					;load code color
	cpi		r18, color_green		;compare if code color is already green (=good color at good position)
	brne	not_dk_green
	sub		yl, r17
	dec		r17
	rjmp	msm_comp_colors_loop_i
not_dk_green:
	sub		yl, r17					;remove code offset
	add		zl, r17					;add code offset
	add		xl, r16					;add user color offset
	ld		r19, x
	ld		r18, z
	sub		zl, r17					;remove code offset
	sub		xl, r16					;remove user color offset
	;check if result color is red (=same color but wrong position)
	cp		r18, r19				;compare code and player combination
	brne	color_not_red
	add		yl, r17					;add offset to result flag
	ld		r18, y
	sub		yl, r17
	cpi		r18, color_red			;check if there was already a red flag at this position
	breq	color_not_red
	add		yl, r17	
	ldi		r18, color_red
	st		y, r18					;put a red flag on this position
	sub		yl, r17
	rjmp	msm_comp_colors_loop_k	;check next position
	color_not_red:
	dec		r17
	cpi		r17, 0xff
	brne	msm_comp_colors_loop_i
	cpi		r16, 0xff
	brne	msm_comp_colors_loop_k

	end_loop:

	subi	xl, -0x04

	ldi		YH, high(RESULTS)
	ldi		YL, low(RESULTS)		;result flags for color comparison output
	ld		r16, Y
	st		x+, r16
	ldd		r16, Y+1
	st		x+, r16
	ldd		r16, Y+2
	st		x+, r16
	ldd		r16, Y+3
	st		x, r16

	pop		yh
	pop		yl
	pop		zh
	pop		zl
	pop		xh
	pop		xl
	pop		r19
	pop		r18
	pop		r17
	pop		r16
ret

msm_clear_matrix:
	push	b0
	push	a0
	push	xl
	push	xh
	ldi		b0, n_LEDS
	ldi		a0, 0x00 ; black
	ldi		XH, high(MATRIX_RAM)
    ldi		XL, low(MATRIX_RAM)
;for loop over the matrix and set everything to black
msm_clear_loop:
	st		X+, a0
	dec		b0
	cpi		b0, 0xff
	brne	msm_clear_loop
	pop		xh
	pop		xl
	pop		a0
	pop		b0
ret
