LZ4DEC	LDB	,U+			; Load lengths byte
	PSHS	B			; Save it for reprocessing
	LSRB				; Shift right 4 to get literals
	LSRB				;    length nybble
	LSRB
	LSRB
	BEQ	LZBKREF			; Are there any at all?
	BSR	LZRDLEN			; If so, read that length...
LZCOPY	LDA	,U+			; ... and copy that many from src
	STA	,Y+			;     to dest
	LEAX	-1,X
	BNE	LZCOPY
LZBKREF	LDD	,U			; Is the backref offset zero?
	BEQ	LZDONE			; If so, we're done.
	LDB	,U+			; If not, consume it as little-endian
	LDA	,U+
	STD	,--S			; And push it on the stack
	LDB	2,S			; Reload the lengths byte
	ANDB	#$0F			; Isolate the backref length
	BSR	LZRDLEN			; and read the rest of it
	TFR	Y,D			; Copy our dest pointer to D
	SUBD	,S			; Subtract backref amount
	STU	,S			; And replace it with orig src ptr
	TFR	D,U			; Our new src ptr is the backref ptr
	LEAX	4,X			; Add 4 to length to get real length
LZCOPY2	LDA	,U+			; And then do the copy
	STA	,Y+
	LEAX	-1,X
	BNE	LZCOPY2
	LDU	,S++			; Restore original source pointer
	LEAS	1,S			; Discard lengths byte
	BRA	LZ4DEC			; On to next block
LZDONE	LEAS	1,S			; Discard lengths byte again
	RTS

	;; Internal helper function. B holds initial 4-bit length, and this
	;; routine reads any extra length bytes out of U and puts the final
	;; length in the X register.
	;; Advances U appropriately. Trashes D.
LZRDLEN	CLRA
	TFR	D,X
	CMPB	#$0f			; Multi-byte length?
	BNE	LZRDONE
LZRLP	LDB	,U+			; Read next length byte
	ABX				; Add it to X
	INCB				; Was it #$FF?
	BEQ	LZRLP
LZRDONE	RTS
