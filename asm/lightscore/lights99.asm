* ----------------------------------------------------------------------------
*   Generic Lights-Out Core for the TMS9900 processor
*   For use with the xas99 assembler
*
*   Copyright 2026 Michael C. Martin. Available under 2-clause BSD
*      license.
*
*   Exported functions:
*
*   - NEWPUZZLE: Randomizes the board. Trashes R0-R5.
*   - MOVEXY: Makes a move at column R0 row R1, both 0-4. Trashes R0/R1.
*   - MAKEMOVE: Makes a move at location R1 (0-24). Trashes R0/R1.
*   - WONGAME: Sets the zero flag if the puzzle is solved.
*   - RNG: Updates the PRNG state (see below). Trashes R0, result in R15.
*
*   These functions all expect to be operating the same workspace, and use
*   R0-R5 (as listed above) for local storage and R11 for return addresses.
*
*   In addition, R12-R15 are used for global state:
*
*   R12: First 16 bits of state, MSB = upper left, 1 bits = lit cells
*   R13: Last 9 bytes of state, MSB of lower byte = lower right
*   R14: PRNG internal state.
*   R15: PRNG internal state exposed as return value.
*
*   To seed the RNG, write nonzero values to R14 and R15.
* ---------------------------------------------------------------------------

* MOVEXY: carry out a move at (R0, R1), both in the 0-4 range.
*   Consumes two locals.
MOVEXY	A	R1,R0			* R1 = (R1 * 5) + R0
	SLA	R1,2
	A	R0,R1
* FALLS THROUGH INTO MAKEMOVE

* MAKEMOVE: Carry out a move at R1 (range: 0-25). 0 is the
*           upper-left corner. Consumes 2 locals, modifies
*           board state in R12-R13.

MAKEMOVE
	SLA	R1,2
	XOR	@!(R1),R12
	XOR	@(!+2)(R1),R13
	B	*R11

* Data tables for MAKEMOVE.
!	DATA	>C400,>0000,>E200,>0000,>7100,>0000,>3880,>0000
	DATA	>1840,>0000,>8620,>0000,>4710,>0000,>2388,>0000
	DATA	>11C4,>0000,>08C2,>0000,>0431,>0000,>0238,>8000
	DATA	>011C,>4000,>008E,>2000,>0046,>1000,>0021,>8800
	DATA	>0011,>C400,>0008,>E200,>0004,>7100,>0002,>3080
	DATA	>0001,>0C00,>0000,>8E00,>0000,>4700,>0000,>2380
	DATA	>0000,>1180

* WONGAME: Checks for victory. Returns with Zero/Equal flag set on win.
*          Consumes no locals.
WONGAME	MOV	R12,R12
	JNE	!
	MOV	R13,R13
!	B	*R11

* NEWPUZZLE: Randomizes the board state.
*            Alters R12/R13 globals, and consumes six locals.
NEWPUZZLE
	CLR	R12
	CLR	R13
	MOV	R11,R2
	BL	@RNG
	MOV	R15,R3
	BL	@RNG
	MOV	R15,R4
	LI	R5,25
!LP	A	R3,R3
	JNC	!
	MOV	R5,R1
	DEC	R1
	BL	@MAKEMOVE
!	A	R4,R4
	JNC	!
	INC	R3
!	DEC	R5
	JNE	-!LP
	B	*R2

* RNG: Advances the PRNG state. Read the latest random number out of R15.
*      Consumes one local.
RNG	MOV	R14,R0
	SLA	R0,5
	XOR	R14,R0
	MOV	R0,R14
	SRL	R0,3
	XOR	R14,R0
	XOR	R15,R0
	MOV	R15,R14
	SRL	R15,1
	XOR	R0,R15
	B	*R11
