	.p816
	.a8
	.i16

	.export	init_cca
	.import	rnd

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
	rts
.endproc
