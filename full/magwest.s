;;; MagWest 2019 Impromptu Code Jam Tribute!
;;; By Michael Martin of Bumbershoot Software
;;; Composed (with some borrowing from Ophis sample code) during
;;; spare moments at MagWest 2019.

.outfile "magwest.bin"

;; Aliases for Atari 2600 control registers
.alias	VSYNC	$00
.alias	VBLANK	$01
.alias	WSYNC	$02
.alias	NUSIZ0	$04
.alias	NUSIZ1	$05
.alias	COLUP0	$06
.alias	COLUP1	$07
.alias	COLUPF	$08
.alias	CTRLPF	$0A
.alias	PF2	$0F
.alias	RESP0	$10
.alias	RESP1	$11
.alias	GRP0	$1B
.alias	GRP1	$1C
.alias	HMP0	$20
.alias	HMP1	$21
.alias	HMOVE	$2A
.alias	INTIM	$284
.alias	TIM64T	$296


.data
.org	$0080
.space	col'0	1
.space	col'1	1
.space	temp	1
.space	counter	1

.text
.org	$F800

	; Console reset
reset:	sei
	cld
	ldx	#$00
	txa
	tay
*	dex
	txs
	pha
	bne	-

	;; Initialize the player sprites. Interleave the player
	;; config and variable setup with the wait to fire the
	;; player-reset signal.

	sta	WSYNC
	lda	#$05	; 2
	sta	NUSIZ0	; 5
	sta	NUSIZ1	; 8
	lda	#$20	; 10
	ldy	#5	; 12
*	dey
	bne	-	; 17-22-27-32-36
	nop		; 38
	sta	RESP0	; 41 = pixel 60
	sta	col'0	; 44
	eor	#$80	; 46
	sta	RESP1	; 49 = pixel 84
	sta	col'1
	sta	temp

	;; Fine tune the player location so the players abut
	lda	#$40	; Pull P1 left to 80
	sta	HMP1
	lda	#$C0	; Push P0 right to 64
	sta	HMP0
	sta	WSYNC
	sta	HMOVE

	;; Near-white, mirrored playfield
	lda	#$0C
	sta	COLUPF
	lda	#$01
	sta	CTRLPF

frame:	lda	#$02
	sta	WSYNC		; Three lines of VSYNC
	sta	VSYNC
	sta	WSYNC
	sta	WSYNC
	lsr
	sta	WSYNC
	sta	VSYNC

	;; Set the VBLANK timer
	lda	#43
	sta	TIM64T

	;; Advance the color bars once every fourth frame.
	inc	counter
	lda	#$03
	bit	counter
	bne	+
	inc	col'0
	dec	col'1

	;; Wait for VBLANK to finish, then turn off the VBLANK signal.
*	lda	INTIM
	bne	-
	sta	WSYNC
	sta	VBLANK

	;; The kernel. Four lines of playfield bars around our dual-
	;; size players that represent the text. The 'text kernel' is
	;; a 4-line kernel at the top level, and expects .A and .X
	;; to have the player 0 and 1 colors at the start.
	;; We set those during the top wait, because why not.
	lda	col'0
	ldx	col'1

	;; Wait 56 lines for vertical placement...
	ldy	#56
*	sta	WSYNC
	dey
	bne	-

	;; Draw the top bar and then seet the playfield to become the walls.
	ldy	#$FF
	sty	PF2
	sty	WSYNC
	sty	WSYNC
	sty	WSYNC
	sty	WSYNC
	ldy	#$01
	sty	PF2
	sty	WSYNC
	sty	WSYNC
	sty	WSYNC
	sty	WSYNC
		

	;; And draw the text. This is a 4-line kernel, but
	;; the colors update every line. To keep that working
	;; we need to juggle the registers a bit. The accumulator
	;; _starts_ with P0's color, but it's needed to load the
	;; graphics, so we stash it in TEMP first.
	ldy	#17
*	sta	COLUP0
	stx	COLUP1
	sta	temp
	lda	hgr-1, y
	sta	GRP0
	lda	igr-1, y
	sta	GRP1

	;; Now, to make the lines update cleanly, we want a fast
	;; incrementer, but with two counters, we need to stash
	;; away .Y. Fortunately, the accumulator was just trashed
	;; by the graphics loads and so is available for this.
	tya
	ldy	temp
	inx
	iny
	sta	WSYNC	; Go through three more lines,
	sty	COLUP0	; updating the colors and bumping
	stx	COLUP1	; the counters.
	inx
	iny
	sta	WSYNC
	sty	COLUP0
	stx	COLUP1
	inx
	iny
	sta	WSYNC
	sty	COLUP0
	stx	COLUP1
	inx		; .X is only touched here, so we
	iny		; can keep it around, but .Y is
	sty	temp	; our line count. Use temp again
	tay		; to trade back .A and .Y, which
	lda	temp	; also preps .A for the color write
	sta	WSYNC	; at the top of the whole 4-line
	dey		; loop.
	bne	-

	;; Clear out the player graphics,,,
	lda	#$00
	sta	GRP0
	sta	GRP1

	;; Close out our border box...
	sta	WSYNC
	sta	WSYNC
	sta	WSYNC
	sta	WSYNC
	lda	#$FF
	sta	PF2
	sta	WSYNC
	sta	WSYNC
	sta	WSYNC
	sta	WSYNC
	lda	#$00
	sta	PF2

	;; Wait 56 lines for the rest of the screen...
	ldy	#56
*	sta	WSYNC
	dey
	bne	-

	;; Turn on VBLANK, do 30 lines of Overscan
	lda	#$02
	sta	VBLANK
	ldy	#30
*	sta	WSYNC
	dey
	bne	-
	jmp	frame	; And the frame is done, back to VSYNC.

	;; Graphics for the letters.
hgr:	.byte	$E4,$4A,$2A,$AA,$44,$00,$53,$AA,$AB,$8A,$8B,$00,$8A,$8A,$AB,$AA,$D9
igr:	.byte	$E2,$42,$46,$CA,$46,$00,$62,$12,$22,$42,$37,$00,$4C,$52,$D6,$50,$8C

	;; Interrupt vectors.
.advance $FFFA
	.word	reset, reset, reset

	;; The graphics nybbles to produce the above graphics.
	;; XX.X X..X X... XX..
	;; X.X. X.X. .X.X ....
	;; X.X. X.XX XX.X .XX.
	;; X... X.X. .X.X ..X.
	;; X... X.X. .X.. XX..
	;; .... .... .... ....
	;; X... X.XX ..XX .XXX
	;; X... X.X. .X.. ..X.
	;; X.X. X.XX ..X. ..X.
	;; X.X. X.X. ...X ..X.
	;; .X.X ..XX .XX. ..X.
	;; .... .... .... ....
	;; .X.. .X.. .X.. .XX.
	;; X.X. X.X. XX.. X.X.
	;; ..X. X.X. .X.. .XX.
	;; .X.. X.X. .X.. ..X.
	;; XXX. .X.. XXX. ..X.
