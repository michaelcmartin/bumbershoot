	ORG	$4000

	;; Clear and home text screen
	JSR	CLS
	;; Display initial text message
	LDX	#MSG
1	LDA	,X+
	BEQ	2F
	JSR	[$A002]
	BRA	1B
	;; Wait for keypress
2	JSR	[$A000]
	TSTA
	BEQ	2B
	;; Clear Text and Graphics screen
	BSR	CLS
	BSR	PCLS
	;; Enter graphics mode 6R
	LDA	$FF22
	ANDA	#7
	ORA	#$F0
	STA	$FF22
	STA	$FFC5
	STA	$FFC3
	LDA	$BC
	BSR	SETPORG
	;; Show the text
	LDX	#MSG2
	LDA	$BC
	CLRB
	ADDD	#32*8*6			; Start on seventh row
	TFR	D,Y
1	PSHS	Y
	LDB	,X+
	BEQ	1F
2	ANDB	#$3F			; Convert ASCII to scrcode
	LDU	#FONT			; Convert screencode to font addr
	CLRA
	LSLB
	LSLB
	LSLB
	ROLA
	LEAU	D,U
	LDB	#8
3	LDA	,U+
	EORA	#$FF
	STA	,Y+
	LEAY	31,Y
	DECB
	BNE	3B
	LEAY	-255,Y
	LDB	,X+
	BNE	2B
	PULS	Y			; Next line
	LEAY	256,Y
	BRA	1B
1	PULS	Y			; Clean up stack

	;; Wait for key
1	JSR	[$A000]
	TSTA
	BEQ	1B
	;; Return to text mode
	LDA	$FF22
	ANDA	#7
	STA	$FF22
	STA	$FFC2
	STA	$FFC4
	LDA	#$04
	BSR	SETPORG
	RTS

CLS	LDX	#$0400
	LDA	#$60
	STX	<$88			; Home cursor
1	STA	,X+
	CMPX	#$0600
	BNE	1B
	RTS

PCLS	LDA	$BC			; First graphics page
	CLRB				; ... convert to 16-bit addr
	TFR	D,X
	LDY	#$1800			; Clear 4 graphics pages (6KB)
	DECB				; B = $FF
1	STB	,X+
	LEAY	-1,Y
	BNE	1B
	RTS

SETPORG	LSRA
	LDX	#$FFC6
1	CLRB
	LSRA
	ROLB
	STA	B,X
	LEAX	2,X
	CMPX	#$FFD4
	BNE	1B
	RTS

MSG	FCB	13,13,13,"THIS IS TEXT CREATED USING THE",13
	FCB	"IN-SYSTEM CHARACTER GENERATOR IN"
	FCB	"THE VDG'S TEXT MODE. IT ALLOWS A"
	FCB	"32 BY 16 DISPLAY IN A FIXED FONT"
	FCB	"AND COLOR SCHEME.",13,13,13
	FCB	"  PRESS A KEY TO CONTINUE...",0

MSG2	FCB	"THIS IS TEXT CREATED USING AN",0
	FCB	"IN-PROGRAM 8 BY 8 FONT IN THE",0
	FCB	"VDG'S MONOCHROME MODE 6R. IT",0
	FCB	"ALLOWS A 32 BY 24 DISPLAY.",0
	FCB	32,0,32,0
	FCB	"  PRESS A KEY TO CONTINUE...",0
	FCB	0

FONT	INCLUDEBIN "res/sinestra.bin"
