	AORG	>6000
	DATA	>AA01,0,0,MENU
	DATA	0,0,0,0
MENU	DATA	0,START
	STRI	'SHOOTING GALLERY'

	COPY	'vdplib.asm'

START	LWPI	>8300
	LIMI	0
	BL	@STDCHR
	.VFILL	0,32,768
	.VFILL	32,>63,32
	.VFILL	>2A0,>68,>60
	.VFILL	>380,>F0,32
	LI	R0,>E100		* Tell BIOS our VDP1 value
	MOVB	R0,@>83D4
	CLR	R0
	MOVB	R0,@>837A		* Disable BIOS sprite motion
	.VREG	1,>E1
	.VREG	6,>01
	.VREG	7,>F1
	.VWRITE	>38D,>22
	.VBLIT	>0B00,GFX_PATTERNS,32
	.VBLIT	>0014,STR_SCORE,11
	.VBLIT	>0300,SPR_INITIAL,49
	CLR	R15			* Clear score
	BL	@FRWAIT			* Wait a frame to stabilize sprites

* Main Game Loop begins here
LOOP	BL	@FRWAIT

	CLR	R14
	MOVB	@>837B,R0		* Check VDP status
	SLA	R0,3			* Check collision bit
	JNC	!			* And store it in R14 for
	INC	R14			* easier checks later
	BL	@SCORE			* also score the hit here
!
	LI	R0,>0100		* Read Joystick 1
	MOVB	R0,@>8374
	BL	@KSCAN
	CLR	R0			* Reset screenblank counter
	C	R0,@>8376		* If joystick moved
	JEQ	!
	CLR	@>83D6
!
	.VLOAD	>8320,>0300,16		* Load player and targets
	MOVB	@>8324,R13		* Save original target Y
* Update Player
	MOVB	@>8377,R0		* Compute DX for player
	SRA	R0,1
	LI	R1,>8321		* Player X position address
	LI	R2,>0600		* Player X OOB Left
	LI	R3,>EA00		* Player X OOB Right
	AB	R0,*R1
	CB	R2,*R1
	JEQ	!
	CB	R3,*R1
	JNE	!!
!	SB	R0,*R1
!	AI	R1,3			* Point R1 to first target
* Update targets
	LI	R0,>0200		* Target speed
	LI	R2,>FE00		* Target boundary value
	LI	R3,>8600		* Target early clock code
	LI	R4,>0600		* Target normal clock code
	LI	R5,>1E00		* Refreshed early clock X coord
	MOVB	@>8376,R6		* Compute DY for targets
	SRA	R6,1
	LI	R7,>0A00		* Target Y OOB top
	LI	R8,>8A00		* Target Y OOB bottom
!TARGET	SB	R0,@1(R1)
	SB	R6,*R1
	CB	R7,*R1
	JEQ	!
	CB	R8,*R1
	JNE	!!
!	AB	R6,*R1
!	CB	@1(R1),R2
	JNE	!NEXT
	CB	@3(R1),R3
	JEQ	!
	MOVB	R3,@3(R1)
	MOVB	R5,@1(R1)
	JMP	!NEXT
!	MOVB	R4,@3(R1)
!NEXT	AI	R1,4
	CI	R1,>8330
	JNE	-!TARGET
	MOVB	@>8321,R5		* Save player X position
	.VBLIT	>0300,>8320,16		* Sync data back to VRAM

* Move shots
	.VLOAD	>8320,>0310,32		* Load 8 shot sprites
	CLR	R0			* Lowest shot found
	LI	R1,>8320		* Shot sprite pointer
	LI	R2,>FE00		* Shot DY
	LI	R3,>C000		* Offscreen Y coordinate
	LI	R4,>FF00		* Shot Y OOB top
!SHOT	CB	R3,*R1
	JEQ	!NEXT
	CI	R14,0			* Checking collisions?
	JEQ	!DOSHOT			* If not, don't
	LI	R6,>0300		* Graphic bias for Y-range check
	AB	R13,R6			* R6 = Target Y + 3
	SB	*R1,R6			* R6 = Target Y - Shot Y + 3
	CI	R6,>1000		* 0 <= R6 <= 16?
	JH	!DOSHOT			* If not, missile still in flight
	CLR	R14			* If so, acknowledge hit...
	MOVB	R3,*R1			* ...delete shot...
	JMP	!NEXT			* ...and skip update
!DOSHOT	AB	R2,*R1
	CB	*R1,R0
	JL	!
	MOVB	*R1,R0
!	CB	R4,*R1
	JNE	!NEXT
	MOVB	R3,*R1
!NEXT	AI	R1,4
	CI	R1,>8340
	JNE	-!SHOT

	CI	R0,>7500		* Room for new shot?
	JH	!NOSHOT			* If not, no new shots
	LI	R0,>1200		* Fire button pressed?
	CB	R0,@>8375
	JNE	!NOSHOT
	CLR	@>83D6			* Reset screen blank timer
	LI	R1,>8320		* Search for unused shot
!	CB	R3,*R1
	JEQ	!
	AI	R1,4
	CI	R1,>8340
	JNE	-!
	JMP	!NOSHOT
!	LI	R0,>8900
	MOVB	R0,*R1+
	MOVB	R5,*R1
!NOSHOT	.VBLIT	>0310,>8320,32		* Sync data back to VRAM
	B	@LOOP

* Support Routines

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

*   SCORE: Award one point and update score in VRAM.
*      In: Score is in R15 as 4-digit BCD.
*     Out: Updated score is in R15 as 4-digit BCD.
* Trashes: R0,R1,R2,R11
SCORE	INC	R15			* Award point
	MOV	R15,R0			* Decimal correct
	ANDI	R0,>000F		* There is probably a better and
	CI	R0,>000A		* less tedious way to do this but
	JL	!			* it gets the job done adequately
	AI	R15,6
	MOV	R15,R0
	ANDI	R0,>00F0
	CI	R0,>00A0
	JL	!
	AI	R15,>60
	MOV	R15,R0
	ANDI	R0,>0F00
	CI	R0,>0A00
	JL	!
	AI	R15,>600
	MOV	R15,R0
	ANDI	R0,>F000
	CI	R0,>A000
	JL	!
	AI	R15,>6000		* End of decimal correct logic
!	LI	R0,>1B40		* Set VRAM pointer to score location
	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
	MOV	R11,R1			* Stash return value
	MOV	R15,R0			* Print R15 a byte at a time
	BL	@!			* With internal routine
	MOV	R1,R11
	MOV	R15,R0
	SWPB	R0
!	MOV	R0,R2			* Print top byte of R0 as BCD
	SRL	R0,4
	AI	R0,>3000
	MOVB	R0,@>8C00
	MOV	R2,R0
	ANDI	R0,>0F00
	AI	R0,>3000
	MOVB	R0,@>8C00
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

* Game Data

GFX_PATTERNS
	BYTE	>10,>38,>BA,>BA,>FE,>FE,>92,>00	* >60: BLASTER
	BYTE	>00,>3C,>42,>5A,>5A,>42,>3C,>00	* >61: TARGET
	BYTE	>00,>00,>00,>00,>00,>10,>10,>10	* >62: MISSILE
	BYTE	>00,>00,>FF,>FF,>00,>00,>00,>00	* >63: DIVIDER LINE

SPR_INITIAL
	BYTE	>99,>78,>60,>09,>38,>38,>61,>06
	BYTE	>38,>78,>61,>06,>38,>B8,>61,>06
	BYTE	>C0,>78,>62,>0B,>C0,>78,>62,>0B
	BYTE	>C0,>78,>62,>0B,>C0,>78,>62,>0B
	BYTE	>C0,>78,>62,>0B,>C0,>78,>62,>0B
	BYTE	>C0,>78,>62,>0B,>C0,>78,>62,>0B
	BYTE	>D0

STR_SCORE
	TEXT	'SCORE: 0000'

	END	START
