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
	.VWRITE	>38D,>22
	.VBLIT	>0B00,GFX_PATTERNS,32
	.VBLIT	>0014,STR_SCORE,11
	.VBLIT	>0300,SPR_INITIAL,49
	MOVB	@C00,@>837A		* Disable BIOS sprite motion
	MOVB	@CE1,@>83D4		* Tell BIOS our VDP1 value
	.VREG	1,>E1
	.VREG	6,>01
	.VREG	7,>F1
	CLR	R15			* Clear score
	BL	@FRWAIT			* Wait a frame to stabilize sprites

* Main Game Loop begins here
LOOP	BL	@FRWAIT

	CLR	R14			* Clear collision bit
	MOVB	@>837B,R0		* Check VDP status
	SLA	R0,3			* Check collision bit
	JNC	!			* And store it in R14 for
	INC	R14			* easier checks later
	BL	@SCORE			* also score the hit here
!
	MOVB	@C01,@>8374
	BL	@KSCAN
	MOV	@>8376,R0		* If joystick moved...
	JEQ	!
	CLR	@>83D6			* ... reset screenblank counter
!
	.VLOAD	>8320,>0300,16		* Load player and targets
	MOVB	@>8324,R13		* Save original target Y
* Update Player
	MOVB	@>8377,R0		* Compute DX for player
	SRA	R0,1
	LI	R1,>8321		* Player X position address
	AB	R0,*R1			* Apply DX...
	CB	@C06,*R1		* Check against left OOB...
	JEQ	!
	CB	@CEA,*R1		* Check against right OOB...
	JNE	!!
!	SB	R0,*R1			* ... and undo DX if OOB.
!	MOVB	@>8321,R12		* Save final player X position
	AI	R1,3			* Point R1 to first target
* Update targets. Constants are kept in workspace registers because we've
* got the room for it.
	LI	R0,>0200		* Target speed
	LI	R2,>FE00		* Target boundary value
	LI	R3,>8600		* Target early clock code
	LI	R4,>0600		* Target normal clock code
	LI	R5,>1E00		* Refreshed early clock X coord
	MOVB	@>8376,R6		* Compute DY for targets
	SRA	R6,1
	LI	R7,>0A00		* Target Y OOB top
	LI	R8,>8A00		* Target Y OOB bottom
!TARGET	SB	R0,@1(R1)		* Apply target DX
	SB	R6,*R1			* Apply target DY
	CB	R7,*R1			* Check against top OOB...
	JEQ	!
	CB	R8,*R1			* Check against bottom OOB...
	JNE	!!
!	AB	R6,*R1			* ... and undo DY if OOB.
!	CB	@1(R1),R2		* Check for X coord wrap-around
	JNE	!NEXT			* next target if not
	CB	@3(R1),R3		* Is early clock set already?
	JEQ	!
	MOVB	R3,@3(R1)		* If not, set early clock...
	MOVB	R5,@1(R1)		* And reset X coord from -2 to 30
	JMP	!NEXT
!	MOVB	R4,@3(R1)		* If so, leave X but clear early clock
!NEXT	AI	R1,4			* Advance R1 to point to next target
	CI	R1,>8330		* Loop until all targets done
	JNE	-!TARGET
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
	MOV	R14,R14			* Checking collisions?
	JEQ	!DOSHOT			* If not, don't
	LI	R5,>0300		* Graphic bias for Y-range check
	AB	R13,R5			* R6 = Target Y + 3
	SB	*R1,R5			* R6 = Target Y - Shot Y + 3
	CI	R5,>1000		* 0 <= R6 <= 16?
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

	CB	R0,@C75			* Room for new shot?
	JH	!NOSHOT			* If not, no new shots
	CB	@C12,@>8375		* Fire button pressed?
	JNE	!NOSHOT			* If not, no new shots
	CLR	@>83D6			* Reset screen blank timer
	LI	R1,>8320		* Search for unused shot
!	CB	R3,*R1			* Is this shot offscreen?
	JEQ	!			* If so, found
	AI	R1,4			* otherwise, next shot
	CI	R1,>8340		* Out of shots somehow?
	JNE	-!
	JMP	!NOSHOT			* If so, no new shots
!	MOVB	@C89,*R1+		* Set new-shot Y coordinate
	MOVB	R12,*R1			* Copy X coordinate from blaster
!NOSHOT	.VBLIT	>0310,>8320,32		* Sync data back to VRAM
	B	@LOOP

* Support Routines

*   SCORE: Award one point and update score display. Two locals.
SCORE	LI	R0,>1B40		* Set VRAM pointer
	MOVB	R0,@>8C02
	SWPB	R0
	MOVB	R0,@>8C02
	INC	R15			* Award point
	CI	R15,10000		* Wrap around?
	JNE	!
	CLR	R15			* If so, back to zero
!	MOV	R15,R1			* Divide out each of the four digits
	CLR	R0			* R15 becomes 32-bit val in R0-1
	DIV	@C03E8,R0		* Divide thousands
	AI	R0,>0030		* Turn quotient to ASCII
	MOVB	@>8301,@>8C00		* And write to VRAM
	CLR	R0			* Remainder in R1 is new dividend
	DIV	@C0064,R0		* Continue for hundreds...
	AI	R0,>0030
	MOVB	@>8301,@>8C00
	CLR	R0			* ... and tens...
	DIV	@C000A,R0
	AI	R0,>0030
	MOVB	@>8301,@>8C00
	AI	R1,>0030		* ... and write ones out of R1.
	MOVB	@>8303,@>8C00
	B	*R11

* Constant word data

C00
C000A	DATA	10
C0064	DATA	100
C03E8	DATA	1000

* Constant byte data

C01	BYTE	>01
C06	BYTE	>06
C12	BYTE	>12
C75	BYTE	>75
C89	BYTE	>89
CE1	BYTE	>E1
CEA	BYTE	>EA

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
