	.p816
	.a8
	.i16

	.export load_sound

	.zeropage
spc_addr: .res 3

	.segment "CODE"

;;; load_sound: Loads a chunk of data into audio RAM at $0200 and then
;;;             starts running code at $0204. The expectation is that a
;;;             single sample has been configured in a directory at $0200.
;;;     INPUTS: .XA holds the source pointer (A=bank, X=address).
;;;             .Y holds the length of the data block.
;;;    RETURNS: Nothing.

.proc	load_sound
	;; store source pointer
	stx	spc_addr
	sta	spc_addr+2
	;; Wait for boot
	ldx	#$bbaa
:	cpx	$2140
	bne	:-
	;; Set write address
	ldx	#$0200
	stx	$2142
	lda	#$cc
	sta	$2141
	sta	$2140
:	cmp	$2140
	bne	:-
	;; Copy data over
	tyx
	ldy	#$0000
copy:	lda	[spc_addr],y
	sta	$2141
	tya
	sta	$2140
:	cmp	$2140
	bne	:-
	iny
	dex
	bne	copy
	;; Run program
	tya
	inc	a
	ldx	#$0204
	stx	$2142
	stz	$2141
	sta	$2140
:	cmp	$2140
	bne	:-
	rts
.endproc
