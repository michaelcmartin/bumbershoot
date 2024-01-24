	ORG	$4000

	LDU	#SCREEN
	LDY	#$0400
	STY	<136			; Home the cursor

	;; Fall through into LZ4DEC

	INCLUDE	"lz4dec.s"
SCREEN	INCLUDEBIN "res/bumberlz4.bin"
