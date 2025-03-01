*	An adaptation of the SN7-based music playroutine from the Z80
*	to the TMS9900. See the comments in genesis/psg80.asm for
*	details of the file format and the song generator.

	AORG	>6000
	DATA	>AA01,0,0,!MENU
	DATA	0,0,0,0
!MENU	DATA	0,START
	STRI	'NYANCAT SONG'

MSG	TEXT	'            NYAN CAT            '
	TEXT	'            --------            '
	TEXT	'                                '
	TEXT    ' ADAPTED FROM AN ARRANGEMENT BY '
	TEXT	' VINCENT JOHNSON TO THE SN7 PSG '
MSGLEN	EQU $-MSG

	COPY	'vdplib.asm'

*	R15    = Song pointer
*	R12-14 = Current voice volumes 1-3
*	R10    = Countdown to next record
*	R0     = PSG pointer

START	LWPI	>8300
	LIMI	0
	BL	@STDCHR
	.VFILL	>0968,>00,>08		* Replace dash with underline
	.VWRITE	>0969,>FF
	.VFILL	>0000,>20,>0300
	.VBLIT	>0120,MSG,MSGLEN

	LI	R15,SONG		* Song pointer
	LI	R14,>001f		* Voice volumes
	MOV	R14,R13
	MOV	R14,R12
	LI	R10,>0001		* Frames to next record

LOOP	BL	@FRWAIT
	LI	R0,>8400		* PSG address
	DEC	R10			* Countdown frame counter
	JNE	!DECAY			* and just fade notes if waiting
	MOVB	*R15+,R10		* Load new frame length byte
	JNE	!NOLP			* And reset to segno if 0
	LI	R15,SEGNO
	MOVB	*R15+,R10
!NOLP	SWPB	R10			* Turn wait time into word value
	MOVB	*R15+,R1		* Load Voice 1 value
	JEQ	!V2
	MOVB	R1,*R0
	MOVB	*R15+,*R0
	LI	R12,>0007
!V2	MOVB	*R15+,R1		* Load Voice 2 value
	JEQ	!V3
	MOVB	R1,*R0
	MOVB	*R15+,*R0
	LI	R13,>0007
!V3	MOVB	*R15+,R1		* Load Voice 3 value
	JEQ	!DECAY
	MOVB	R1,*R0
	MOVB	*R15+,*R0
	LI	R14,>0007
!DECAY	LI	R1,>001F
	C	R1,R12			* Check Voice 1 attenuation
	JEQ	!
	INC	R12
!	MOV	R12,R2
	SLA	R2,7
	ORI	R2,>9000
	MOVB	R2,*R0
	C	R1,R13			* Check Voice 2 attenuation
	JEQ	!
	INC	R13
!	MOV	R13,R2
	SLA	R2,7
	ORI	R2,>B000
	MOVB	R2,*R0
	C	R1,R14			* Check Voice 3 attenuation
	JEQ	!
	INC	R14
!	MOV	R14,R2
	SLA	R2,7
	ORI	R2,>D000
	MOVB	R2,*R0
	JMP	LOOP

SONG	BCOPY	"../genesis/res/nyansong.bin"
SEGNO	EQU	SONG+130
