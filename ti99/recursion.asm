* ----------------------------------------------------------------------
*                  FIBONACCI: ITERATIVE VS. RECURSIVE
*
*   This cartridge computes the first few Fibonacci numbers and prints
*   them out on the screen. One approach uses my allocation scheme that
*   keeps all state within the 32-byte workspace and solves it with a
*   fast iterative algorithm. The other builds a call stack with local
*   variable state in VRAM and admits a (much slower) recursive
*   implementation.
*
*   The recursive system is wildly inappropriate for this problem, with
*   over 35,000 function calls involved in computing the last number to
*   display, but it should serve as a simple proof of concept regarding
*   how to actually properly implement a recursive algorithm on the
*   unexpanded TI-99/4A with its 256 bytes of CPU RAM.
* ----------------------------------------------------------------------

	AORG	>6000
	DATA	>AA01,0,0,!MENU
	DATA	0,0,0,0
!MENU2	DATA	0,STARTITER
	STRI	'FIB ITERATIVE'
!MENU	DATA	-!MENU2,STARTREC
	STRI	'FIB RECURSIVE'

* ----------------------------------------------------------------------
*                       ITERATIVE IMPLEMENTATION
*
*   This implementation uses my usual workspace allocation scheme and
*   also runs extremely fast. It provides the correctness test for the
*   recursive algorithm.
* ----------------------------------------------------------------------

STARTITER
	LWPI	>8300
	LIMI	0
	BL	@STDCHR
	BL	@VBLIT
	DATA	>0968,GFXDASH,8
	BL	@VSTR
	DATA	>0009,STRFIB
	LI	R4,1
	LI	R5,>22
!	MOV	R5,R0
	MOV	R4,R1
	BL	@VNUM
	BL	@VSTRR
	DATA	STRPT
	MOV	R4,R0
	BL	@FIBITER
	MOV	R0,R1
	BL	@VNUMR
	AI	R5,>20
	INC	R4
	CI	R5,>2E2
	JNE	-!
!EVER	LIMI	2
!
	JMP	-!

* FIBITER: Compute the R0th fibonacci number, iteratively. Returns
*          result in R0. Uses four locals.
FIBITER	CLR	R1
	LI	R2,1
!	MOV	R1,R3
	MOV	R2,R1
	A	R3,R2
	DEC	R0
	JNE	-!
	MOV	R1,R0
	B	*R11

* ----------------------------------------------------------------------
*                       RECURSIVE IMPLEMENTATION
*
*   This implementation maintains a procedure call stack with saved
*   local variables in the top of VRAM, and implements the Fibonacci
*   function with a (very inefficient) tree-recursive algorithm to put
*   it through its paces.
* ----------------------------------------------------------------------

STARTREC
	LWPI	>8300
	LIMI	0
	BL	@STDCHR
	BL	@VBLIT
	DATA	>0968,GFXDASH,8
	BL	@VSTR
	DATA	>0009,STRFIB
	LI	R15,>8000
	LI	R4,1
	LI	R5,>22
!	MOV	R4,R0
	BL	@FIBREC
	MOV	R0,R6
	MOV	R5,R0
	MOV	R4,R1
	BL	@VNUM
	BL	@VSTRR
	DATA	STRPT
	MOV	R6,R1
	BL	@VNUMR
	AI	R5,>20
	INC	R4
	CI	R5,>2E2
	JNE	-!
	JMP	-!EVER

* FIBREC: Compute the R0th fibonacci number, recursively. Returns
*         result in R0. Uses the top of VRAM as a stack.
FIBREC	CI	R0,3
	JHE	!
	LI	R0,1			* BASE CASE
	B	*R11

!	AI	R15,-4			* PUSH R4 and R11
	SWPB	R15
	MOVB	R15,@>8C02
	SWPB	R15
	MOVB	R15,@>8C02
	SWPB	R4
	MOVB	R4,@>8C00
	SWPB	R4
	MOVB	R4,@>8C00
	SWPB	R11
	MOVB	R11,@>8C00
	SWPB	R11
	MOVB	R11,@>8C00

	MOV	R0,R4			* DO THE WORK
	DEC	R0
	BL	@FIBREC
	MOV	R0,R1
	MOV	R4,R0
	MOV	R1,R4
	DECT	R0
	BL	@FIBREC
	A	R4,R0

	ANDI	R15,>3FFF		* RESTORE R4 AND R11
	SWPB	R15
	MOVB	R15,@>8C02
	SWPB	R15
	MOVB	R15,@>8C02
	AI	R15,>4004
	MOVB	@>8800,R4
	SWPB	R4
	MOVB	@>8800,R4
	NOP
	MOVB	@>8800,R11
	SWPB	R11
	MOVB	@>8800,R11
	B	*R11

* ----------------------- VDP SUPPORT ROUTINES -------------------------

* STDCHAR: Load standard character set into VRAM at >900. ASCII text will
*          render properly with default pattern table configuration. Uses
*          two locals.
STDCHR	LI	R1,>06B4
	MOVB	R1,@>9C02
	SWPB	R1
	MOVB	R1,@>9C02
	LI	R1,>0049
	MOVB	R1,@>8C02
	SWPB	R1
	MOVB	R1,@>8C02
	LI	R1,32
!	CLR	R0
	MOVB	R0,@>8C00
	LI	R0,7
!	MOVB	@>9800,@>8C00
	DEC	R0
	JNE	-!
	INC	R1
	CI	R1,127
	JNE	-!!
	B	*R11

* VSTR:  Read VRAM address, then null-terminated string pointer, from
*        instruction stream and print it out. Uses one local.
* VSTRR: As above, but without a new VRAM address.
VSTR	MOV	*R11+,R0
	ORI	R0,>4000
	SWPB	R0
	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
VSTRR	MOV	*R11+,R0
!	CB	*R0,@C00
	JEQ	!
	MOVB	*R0+,@>8C00
	JMP	-!
!	B	*R11

* VBLIT: Read VRAM address, then source address, then count, from
*        instruction stream and copy it. Uses two locals.
VBLIT	MOV	*R11+,R0
	ORI	R0,>4000
	SWPB	R0
	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
	MOV	*R11+,R0
	MOV	*R11+,R1
!	MOVB	*R0+,@>8C00
	DEC	R1
	JNE	-!
	B	*R11

* VNUM: Write the number (< 100000) in R1 to the VRAM location in R0.
*       Uses two locals. VNUMR ignores R0 and writes to current VRAM
*       pointer location.
VNUM	SWPB	R0
	MOVB	R0,@>8C02
	SWPB	R0
	ORI	R0,>4000
	MOVB	R0,@>8C02
VNUMR	CI	R1,10
	JL	!ONES
	CI	R1,100
	JL	!TENS
	CI	R1,1000
	JL	!HUND
	CI	R1,10000
	JL	!THOUS
	CLR	R0
	DIV	@C2710,R0
	AI	R0,>30
	SWPB	R0
	MOVB	R0,@>8C00
!THOUS	CLR	R0
	DIV	@C03E8,R0
	AI	R0,>30
	SWPB	R0
	MOVB	R0,@>8C00
!HUND	CLR	R0
	DIV	@C0064,R0
	AI	R0,>30
	SWPB	R0
	MOVB	R0,@>8C00
!TENS	CLR	R0
	DIV	@C000A,R0
	AI	R0,>30
	SWPB	R0
	MOVB	R0,@>8C00
!ONES	AI	R1,>30
	SWPB	R1
	MOVB	R1,@>8C00
	B	*R11

* --------------------------- LITERAL POOL -----------------------------

C00
C000A	DATA	>000A
C0064	DATA	>0064
C03E8	DATA	>03E8
C2710	DATA	>2710

GFXDASH	BYTE	>00,>FF,>00,>00,>00,>00,>00,>00

STRFIB	TEXT	'FIBONACCI NUMBERS               '
	TEXT	'-----------------'
	BYTE	0

STRPT	TEXT	'. '
	BYTE	0
