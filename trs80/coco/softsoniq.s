PLAYMUS	STX	SONGIDX			; Store argument
	;; Save original configuration and disable interrupts
	PSHS	CC
	ORCC	#$10

	;; Configure muxer settings for 6-bit audio output
	LDA	$FF01
	ANDA	#$F7
	STA	$FF01
	LDA	$FF03
	ANDA	#$F7
	STA	$FF03
	LDA	$FF23
	ORA	#$08
	STA	$FF23

	;; Clear control registers
	CLRA
	CLRB
	STD	V1SAMP
	STD	V1FREQ
	STD	V2SAMP
	STD	V2FREQ
	STD	V3SAMP
	STD	V3FREQ
	STD	V1INDEX
	STD	V2INDEX
	STD	V3INDEX

	;; Read new song command
	;; We're normally at cycle 164 when we loop back here
1	LDU	SONGIDX			; 6   (170)
	LDB	,U+			; 4+2 (176)
	LDY	#V1SAMP			; 4   (180)
	LDX	,U++			; 5+3 (188)
	STX	B,Y			; 5+1 (194)
	LDY	,U++			; 5+3 (202)
	CMPB	#12			; 2   (204)  Did we move?
	BNE	3F			; 3   (207)
	BRN	2F			; 3   (210)
	BRA	2F			; 3   (213)
3	STU	SONGIDX			; 6   (213)
	;; Compute next output sample
	;; This is the "zero point" for our loop timing
2	LDD	V1FREQ			; 6   (  6)
	ADDD	V1INDEX			; 7   ( 13)
	STD	V1INDEX			; 6   ( 19)
	LSRA				; 2   ( 21)
	LSRA				; 2   ( 23)
	LSRA				; 2   ( 25)
	LDX	V1SAMP			; 6   ( 31)
	LDB	A,X			; 4+1 ( 36)
	STB	CURSAMP			; 5   ( 41)
	LDD	V2FREQ			; 6   ( 47)
	ADDD	V2INDEX			; 7   ( 54)
	STD	V2INDEX			; 6   ( 60)
	LSRA				; 2   ( 62)
	LSRA				; 2   ( 64)
	LSRA				; 2   ( 66)
	LDX	V2SAMP			; 6   ( 72)
	LDB	A,X			; 4+1 ( 77)
	ADDB	CURSAMP			; 5   ( 82)
	STB	CURSAMP			; 5   ( 87)
	LDD	V3FREQ			; 6   ( 93)
	ADDD	V3INDEX			; 7   (100)
	STD	V3INDEX			; 6   (106)
	LSRA				; 2   (108)
	LSRA				; 2   (110)
	LSRA				; 2   (112)
	LDX	V3SAMP			; 6   (118)
	LDB	A,X			; 4+1 (123)
	ADDB	CURSAMP			; 5   (128)
	ADDB	#$80			; 2   (130)
	ANDB	#$FC			; 2   (132)
	STB	$FF20			; 5   (137)   Check for kb hit
	CLR	$FF02			; 7   (144)
	LDB	$FF00			; 5   (149)
	ORB	#$80			; 2   (151)
	INCB				; 2   (153)
	BNE	4F			; 3   (156)
	LEAY	-1,Y			; 4+1 (161)
	BEQ	1B			; 3   (164)
	LDB	#8			; 2   (166)
3	DECB				; 2*8 (182)
	BNE	3B			; 3*8 (206)
	NOP				; 2   (208)
	NOP				; 2   (210)
	BRA	2B			; 3   (213)
4	PULS	CC,PC			; Restore interrupts and return

V1SAMP	FDB	0
V1FREQ	FDB	0
V2SAMP	FDB	0
V2FREQ	FDB	0
V3SAMP	FDB	0
V3FREQ	FDB	0
SONGIDX	FDB	0

V1INDEX	FDB	0
V2INDEX	FDB	0
V3INDEX	FDB	0
CURSAMP	FCB	0
