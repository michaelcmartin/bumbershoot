* VRAM ACCESS FUNCTIONS
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
