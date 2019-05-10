/*
 *
 *  Created: 5/3/2019 7:40:37 PM
 *   Author: guillaume.thivolet
 */
.equ color_black	=	0x00
.equ color_yellow	=	0x01
.equ color_red		=	0x02
.equ color_blue		=	0x03
.equ color_cyan		=	0x04
.equ color_purple	=	0x05
.equ color_green	=	0x06
.equ color_white	=	0x07

colors:
	.db 0x00, 0x00, 0x00, 0x0f, 0x0f, 0x00, 0x00, 0x07, 0x0, 0x0, 0x00, 0x07, 0x07, 0x00, 0x07, 0x00, 0x03, 0x07
	;	black(#000000),   yellow (#ffc12b), red(##ff0001),   blue(#000000),   cyan(#070007),    purple(#800080)
	.db 0x07, 0x00, 0x00, 0x0f, 0xf, 0xf
	;	green(#000007),   white (#ffffff)
	; usage of the lookup table: 
	; 0=black
	; 1=yellow
	; 2=red
	; 3=blue
	; 4=cyan
	; 5=purple
	; 6=green
	; 7=white
