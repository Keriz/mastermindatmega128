/*
 * utils.asm
 *
 *  Created: 5/3/2019
 *   Author: guillaume.thivolet & fahradin.mujovi
 */
 ;this file provides macros to be used elsewhere in the program

 .macro ADD8T			;add 8 times ;for loop would not optimize so much
	add @0, @1
	add @0, @1
	add @0, @1
	add @0, @1 
	add @0, @1
	add @0, @1
	add @0, @1
	add @0, @1
.endmacro

 .macro ADD3T			;add 3 times
	add @0, @1
	add @0, @1
	add @0, @1
.endmacro