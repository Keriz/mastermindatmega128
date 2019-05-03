/*
 * colorslu.asm
 *
 *  Created: 5/3/2019 7:40:37 PM
 *   Author: guillaume.thivolet
 */ 
colors:
	.db 0x00, 0x00, 0x00, 0xff, 0xc1, 0x2b, 0xff, 0x00, 0x01, 0x0e, 0x69, 0x8b, 0x00, 0xff, 0xff, 0x80, 0x00, 0x80
	;	black(#000000),   yellow (#ffc12b), red(##ff0001),    blue(#0e698b),    cyan(#00ffff),    purple(#800080)
	.db 0x32, 0xcd, 0x32, 0xff, 0xff, 0xff
	;	green(#32cd32),   white (#ffffff)
	; usage of the lookup table: 
	; 0=black
	; 1=yellow
	; 2=red
	; 3=blue
	; 4=cyan
	; 5=purple
	; 6=green
	; 7=white
