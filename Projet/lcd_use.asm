/*
 * lcd_use.asm
 *
 *  Created: 07.05.2019 17:52:51
 *   Author: fmujo
 */ 
.include "macros.asm"
.include "definitions.asm"

.org 0x0000
 reset:
	LDSP	RAMEND		;init SP
	rcall	LCD_init
	rjmp	main
.include "lcd.asm"
.include "printf.asm"

main: ;pour load "nb coups : x"
	PRINTF	LCD_putc
.db			"yes1", 0
/*
main: ;pour load "nb coups : x"
	ldi		r16, str0
	ldi		zl, low(2*str0)
	ldi		zh, high(2*str0)
	rcall	LCD_putstring
	rjmp	PC

LCD_putstring:
	lpm		;r0, z
	tst		r0
	breq	done
	mov		a0, r0					
	rcall	LCD_putc		;écrit contenu de a0 à l'endroit actuel dans le LCD et l'affiche. essayer LCD_wr_dr qui affiche pas ?
	adiw	zh:zl, 1		;ajoute 1 au pointeur z (donc aux deux parties)
	rjmp	LCD_putstring
done:ret

.org 200 ;où les placer ? Généralement en début de programme plutôt.
str0:
.db	"Coup num : x" ;regarder comment ajouter un nbr mofdifiable à la place de x 
str1:
.db	"GAGNE"
str2:
.db	"PERDU"*/