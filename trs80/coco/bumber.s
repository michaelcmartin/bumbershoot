	ORG	$3F00

	LDU	#SCREEN
	LDY	#$0400
	STY	<$88			; Home the cursor
	BSR	LZ4DEC			; and decompress logo to screen

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

	;; Play back at 4kHz. Target is 222 cycles per sample.
	LDX	#SAMPLE_END-SAMPLE
	LDY	#SAMPLE
LOOP	LDA	,Y+
	ANDA	#$FC
	STA	$FF20
	LDB	#40
DELAY	DECB
	BNE	DELAY
	LEAX	-1,X
	BNE	LOOP

	;; Clear the screen now that we're done.
	LDA	#$60
	LDY	#$0400
CLS	STA	,Y+
	CMPY	#$0600
	BNE	CLS
	RTS

	INCLUDE	"lz4dec.s"
SCREEN	INCLUDEBIN "res/bumberlz4.bin"
SAMPLE	INCLUDEBIN "res/bumberwav.bin"
SAMPLE_END
