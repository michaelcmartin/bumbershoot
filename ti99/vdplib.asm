* VRAM ACCESS MACROS
*
* VBLIT(DEST, SRC, SIZE) (trashes R0-2,R11)
* VFILL(DEST, VAL, SIZE) (trashes R0-2,R11)
* VLOAD(DEST, SRC, SIZE) (trashes R0-2,R11)
* VREG(REG, VAL) (trashes R0)
* VWRITE(DEST, VAL) (trashes R0)
*
* DEST and SRC must be addresses, of VRAM or CPU RAM as needed
* REG, VAL, and SIZE must be immediate values.
* All arguments must be in immediate *format* because the calling
* macros process addresses for efficient submission to the VDP.
*
* OTHER UTILITY FUNCTIONS
*
* FRWAIT() (trashes R0,R11) - waits until next VDP interrupt
* KSCAN() (trashes R0,R11) - reads device in >8374.
* STDCHAR() (trashes R0-1,R11) - loads the standard charset

	.DEFM	VBLIT
	LI	R0, ((#1 >> 8) & >003F) | ((#1 << 8) & >FF00) | >0040
	LI	R1, #2
	LI	R2, #3
	BL	@VBLIT
	.ENDM

	.DEFM	VFILL
	LI	R0, ((#1 >> 8) & >003F) | ((#1 << 8) & >FF00) | >0040
	LI	R1, (#2 << 8) & >FF00
	LI	R2, #3
	BL	@VFILL
	.ENDM

	.DEFM	VLOAD
	LI	R0, #1
	LI	R1, ((#2 >> 8) & >003F) | ((#2 << 8) & >FF00)
	LI	R2, #3
	BL	@VLOAD
	.ENDM

	.DEFM	VREG
	LI	R0, (#1 & >000F) | ((#2 << 8) & >FF00) | >0080
	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
	.ENDM

	.DEFM	VWRITE
	LI	R0, ((#1 >> 8) & >003F) | ((#1 << 8) & >FF00) | >0040
	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
	LI	R0,((#2 << 8) & >FF00)
	MOVB	R0,@>8C00
	.ENDM

	EVEN

VBLIT	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
!	MOVB	*R1+,@>8C00
	DEC	R2
	JNE	-!
	B	*R11

VFILL	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
	SWPB	R0
!	MOVB	R1,@>8C00
	DEC	R2
	JNE	-!
	B	*R11

VLOAD	MOVB	R1,@>8C02
	SWPB	R1
	MOVB	R1,@>8C02
	SWPB	R1
!	MOVB	@>8800,*R0+
	DEC	R2
	JNE	-!
	B	*R11

*  FRWAIT: Wait until next VDP interrupt.
*      In: None
*     Out: None
* Trashes: R0,R11.
FRWAIT	MOVB	@>8379,R0
	LIMI	2
!	CB	@>8379,R0
	JEQ	-!
	LIMI	0
	B	*R11

*   KSCAN: Check for input.
*      In: >8374 byte value of device to read. WSP must be >8300.
*     Out: Carry set if new value; keys and joystick dirs in >8375-7.
* Trashes: R0,R11.
KSCAN	LWPI	>83E0
	MOV	R11,@>8300
	BL	@>000E
	MOV	@>8300,R11
	LWPI	>8300
	MOVB	@>837C,R0
	SLA	R0,3
	B	*R11

* STDCHAR: Load standard character set into VRAM at >900. ASCII text will
*          render properly with default pattern table configuration.
*      In: None
*     Out: None
* Trashes: R0,R1,R11, VRAM and GROM pointers
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
