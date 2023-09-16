	.p816
	.a8
	.i16

	.export	init_cca, step_cca
	.import	rnd

	.zeropage
count:	.res	1

	.segment "CODE"

.proc	init_cca
	phb
	lda	#$7f			; Set PDB to $7f
	pha
	plb
	ldx	#$0000
	ldy	#$1000
loop:	jsr	rnd
	jsr	write
	dey
	bne	loop
	plb
	rts

write:	jsr	write2
	xba
	;; Fall through
write2:	pha
	and	#$0f
	sta	a:$0000,x
	inx
	pla
	lsr
	lsr
	lsr
	lsr
	sta	a:$0000,x
	inx
	rts
.endproc

.macro	check_cell center, left, right, up, down, abort
	.local	eat
	lda	a:center,x		; Check target
	.ifnblank abort
	bmi	abort			; Quit if it's the sentinel
	.endif
	inc	a			; Get target value
	and	#$0f
	cmp	a:up,x
	beq	eat
	cmp	a:left,x
	beq	eat
	cmp	a:right,x
	beq	eat
	cmp	a:down,x
	beq	eat
	dec	a			; No-op, copy orig value
	and	#$0f
eat:	sta	a:center,y
.endmacro

;;; Advance the simulation one step.
;;; .X holds the source buffer, .Y the destination.
.proc	step_cca
	phb				; Save original bank
	lda	#$7f			; And set the new one to 7f
	pha
	plb
	;; Step 1: Check the corners
	check_cell $0000,$007f,$0001,$3f80,$0080
	check_cell $007f,$007e,$0000,$3fff,$00ff
	check_cell $3f80,$3fff,$3f81,$3f00,$0000
	check_cell $3fff,$3ffe,$3f80,$3f7f,$007f
	;; Step 2: Check interior cells (trashes L/R edges off corners)
	phx				; Save buffer base addresses
	phy
	lda	a:$3f80,x		; Save lower left corner true value
	pha
	lda	#$ff
	sta	a:$3f80,x		; Replace with sentinel
midlp:	check_cell $0081,$0080,$0082,$0001,$0101,endmid
	inx
	iny
	bra	midlp
endmid:	pla				; Restore sentinel with orig. value
	sta	a:$3f80,x
	ply
	plx
	;; Step 3: Check top/bottom edges
	phx
	phy
	lda	#$7e
	sta	count
hlp:	check_cell $0001,$0000,$0002,$3f81,$0081
	check_cell $3f81,$3f80,$3f82,$3f01,$0001
	inx
	iny
	dec	count
	bne	hlp
	ply
	plx
	;; Step 4: Check left/right edges
	lda	#$7e
	sta	count
vlp:	check_cell $0080,$00ff,$0081,$0000,$0100
	check_cell $00ff,$00fe,$0080,$007f,$017f
	rep	#$21
	.a16
	txa
	adc	#$0080
	tax
	tya
	clc
	adc	#$0080
	tay
	sep	#$20
	.a8
	dec	count
	bne	vlp
	plb
	rts
.endproc
