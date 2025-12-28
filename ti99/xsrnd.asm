	AORG	>6000

	DATA	0,0,0,0,0,0,0,0
	DATA	0,RNG,PHEX,DOSONG

RNG	LWPI	>8300
	MOV	R14,R0
	SLA	R0,5
	XOR	R14,R0
	MOV	R0,R14
	SRL	R0,3
	XOR	R14,R0
	XOR	R15,R0
	MOV	R15,R14
	SRL	R15,1
	XOR	R0,R15
	LWPI	>83E0
	B	*R11

PHEX	LWPI	>8300
	CLR	R1
	LI	R2,>4000
	MOVB	@>837F,@>8305		* Low byte of R2 = CCOL
	MOVB	@>837E,R1		* High byte of R1 = CROW
	SRL	R1,3			* R1 = CROW * 32
	A	R1,R2			* R2 = >4000 + screen address
	SWPB	R2			* Set VRAM write address
	MOVB	R2,@>8C02
	SWPB	R2
	MOVB	R2,@>8C02
	MOV	R0,R1
	SRL	R0,4
	BL	@!PDIGI
	MOV	R1,R0
	BL	@!PDIGI
	SWPB	R1
	MOV	R1,R0
	SRL	R0,4
	BL	@!PDIGI
	MOV	R1,R0
	BL	@!PDIGI
	AB	@C04,@>837F		* Advance CCOL
	CB	@>837F,@C20
	JL	!
	SB	@C20,@>837F
	AB	@C01,@>837E
!	LWPI	>83E0
	B	*R11
!PDIGI	ANDI	R0,>0F00
	AI	R0,>3000
	CI	R0,>3A00
	JL	!
	AI	R0,>0700
!	MOVB	R0,@>8C00
	B	*R11

DOSONG	LWPI	>8300
	MOV	R0,R12
	MOV	R0,R13
	MOV	@CISR,@>83C4
	LWPI	>83E0
	B	*R11

ISR	MOVB	@>83CE,@>83CE		* Sound list done?
	JNE	!DONE			* If not, we're done too
	LWPI	>8300
	MOVB	@>9802,R10		* Read original GROM location
	NOP
	MOVB	@>9802,@>8315		*  into R10
	DEC	R10
!GLOAD	MOVB	R13,@>9C02		* Dereference R13 into GROM
	SWPB	R13
	MOVB	R13,@>9C02
	SWPB	R13
	MOVB	@>9800,@>83CC		* Load new sound list ptr
	INCT	R13			* Increment song ptr while we wait
	MOVB	@>9800,@>83CD
	MOV	@>83CC,@>83CC		* Is it zero?
	JNE	!OK
	MOV	R12,R13			* If so, copy start of song back
	JMP	-!GLOAD			* And reload
!OK	MOVB	@C01,@>83CE		* Otherwise start sound playback
	MOVB	R10,@>9C02		* Restore the GROM address
	SWPB	R10
	MOVB	R10,@>9C02
	LWPI	>83E0
!DONE	B	*R11

C01:	BYTE	>01
C04:	BYTE	>04
C20:	BYTE	>20
CISR:	DATA	ISR
