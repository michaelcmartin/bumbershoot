;;; ----------------------------------------------------------------------
;;;   softsoniq.s: 3-voice synthesizer inspired by the Ensonic 5503
;;;
;;;   One function is exported: PLAYMUS. A pointer to song data is stored
;;;   in the X argument.
;;; ----------------------------------------------------------------------

PLAYMUS	STX	SONGIDX			; Store argument
	;; Save original configuration and disable interrupts
	PSHS	CC
	ORCC	#$50

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
1	LDU	SONGIDX			; 6   (170)  U = current song loc
	LDB	,U+			; 4+2 (176)  B = register to write
	LDY	#V1SAMP			; 4   (180)  Y = register bank base
	LDX	,U++			; 5+3 (188)  X = value to write
	STX	B,Y			; 5+1 (194)  Do the write
	LDY	,U++			; 5+3 (202)  Y = iterations-to-next-cmd
	CMPB	#12			; 2   (204)  Did we change song loc?
	BNE	3F			; 3   (207)  If not, save U as new loc
	BRN	2F			; 3   (210)  If so, stall 6 cycles
	BRA	2F			; 3   (213)    instead
3	STU	SONGIDX			; 6   (213)
	;; Compute next output sample
	;; This is the "zero point" for our loop timing
2	LDD	V1FREQ			; 6   (  6)  Update voice 1 data
	ADDD	V1INDEX			; 7   ( 13)
	STD	V1INDEX			; 6   ( 19)
	LSRA				; 2   ( 21)  Get current voice 1 sample
	LSRA				; 2   ( 23)
	LSRA				; 2   ( 25)
	LDX	V1SAMP			; 6   ( 31)
	LDB	A,X			; 4+1 ( 36)
	STB	CURSAMP			; 5   ( 41)  Store as current sample
	LDD	V2FREQ			; 6   ( 47)  Update voice 2 data
	ADDD	V2INDEX			; 7   ( 54)
	STD	V2INDEX			; 6   ( 60)
	LSRA				; 2   ( 62)  Get current voice 2 sample
	LSRA				; 2   ( 64)
	LSRA				; 2   ( 66)
	LDX	V2SAMP			; 6   ( 72)
	LDB	A,X			; 4+1 ( 77)
	ADDB	CURSAMP			; 5   ( 82)  Update current sample
	STB	CURSAMP			; 5   ( 87)
	LDD	V3FREQ			; 6   ( 93)  Update voice 3 data
	ADDD	V3INDEX			; 7   (100)
	STD	V3INDEX			; 6   (106)
	LSRA				; 2   (108)  Get current voice 3 sample
	LSRA				; 2   (110)
	LSRA				; 2   (112)
	LDX	V3SAMP			; 6   (118)
	LDB	A,X			; 4+1 (123)
	ADDB	CURSAMP			; 5   (128)  Create final sample
	ADDB	#$80			; 2   (130)  Convert to 8-bit unsigned
	ANDB	#$FC			; 2   (132)  Convert to 6-bit
	STB	$FF20			; 5   (137)  Output 6-bit to audio port
	CLR	$FF02			; 7   (144)  Scan entire keyboard
	LDB	$FF00			; 5   (149)
	ORB	#$80			; 2   (151)  Mask out joystick info
	INCB				; 2   (153)  ... was it $FF?
	BNE	4F			; 3   (156)  If not, key hit, done
	LEAY	-1,Y			; 4+1 (161)  If so, decrement timer
	BEQ	1B			; 3   (164)  If timer 0, read new cmd
	LDB	#8			; 2   (166)  Otherwise stall for the
3	DECB				; 2*8 (182)     time it takes to
	BNE	3B			; 3*8 (206)     read a new command...
	NOP				; 2   (208)
	NOP				; 2   (210)
	BRA	2B			; 3   (213)  ...and compute next sample
4	PULS	CC,PC			; Restore interrupts and return

;;; Software registers for playback. Song data will index these to set
;;; instruments and frequencies.
V1SAMP	FDB	0
V1FREQ	FDB	0
V2SAMP	FDB	0
V2FREQ	FDB	0
V3SAMP	FDB	0
V3FREQ	FDB	0
SONGIDX	FDB	0

;;; Internal software registers. Song data and external routines will
;;; PROBABLY not have to care about these.
V1INDEX	FDB	0
V2INDEX	FDB	0
V3INDEX	FDB	0
CURSAMP	FCB	0
