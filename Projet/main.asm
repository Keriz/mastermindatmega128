;MICROCONTROLEURS PROJET BA4
; main.asm
;
; Created: 4/25/2019 9:59:59 PM
; Author : guillaume.thivolet and fahradin.mujovi
;
;Entry point of the program, this file includes the main game loop.

.include msm.asm

.org 0x0000			; memory (PC) location of reset handler
	rjmp reset
;to implement; all the interrupts

.dseg
.org 0x100 ;found in atmega128 datasheet page 19
; usage: https://www.microchip.com/webdoc/avrassembler/avrassembler.wb_directives.html#avrassembler.wb_directives.ORG
;memore starts at location 0x100
matrix_colors: .byte 0x40 ;(reserve 8x8 = 64 bytes of color to work with)

.cseg
reset:
	LDSP	RAMEND
	rcall	ws2812b4_init

main:
	; implement main loop here
    rjmp main
