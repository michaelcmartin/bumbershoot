	.p816
	.a8
	.i16
	.export lz4dec

	.zeropage
srcptr:	.res	3
len:	.res	2

	.segment "CODE"

	;; LZ4DEC: Decodes a 16-bit 0-terminated LZ4 block.
	;; Register widths: A8, I16
	;; Parameters:
	;;     .AX: start of block
	;;     .Y: Destination offset in bank $7F
	;; Results:
	;;     .X: address just past last decoded byte
	;;     .Y: length of compressed data, minus 2
	;;         (offset to null terminator)
.proc	lz4dec
	phb
	stx	srcptr			; Store source pointer
	sta	srcptr+2
	lda	#$7f			; Set data bank to $7f
	pha
	plb
	tyx				; Move dest ptr to .X
	ldy	#$0000			; src offset in .Y
loop:	lda	[srcptr],y		; load lengths byte
	iny
	pha				; save it for reprocessing
	lsr				; Shift right 4 to get literals
	lsr				;    length nybble
	lsr
	lsr
	beq	bkref			; Are there any at all?
	jsr	rd_len			; If so, read that length...
cp_lit:	lda	[srcptr],y		; ...then copy that many from src
	sta	a:$0000,x		;        to dest
	inx
	iny
	rep	#$20
	dec	len
	sep	#$20
	bne	cp_lit
bkref:	rep	#$20			; Backref: load 16-bit load offset
	.a16
	lda	[srcptr],y
	beq	done			; If it's the null terminator, quit
	iny
	iny
	eor	#$ffff			; Negate it
	inc	a
	pha				; Stash it while we read the length
	sep	#$20
	.a8
	lda	3,s			; pull back length byte
	and	#$0f			;   ... and mask out the backref length
	jsr	rd_len			;   ... and load the rest if any
	rep	#$20
	.a16
	pla				; Get our offset back
	phy				; Save our place in the source
	phx				; Get our current destptr in memory...
	clc				; ... so we can get our backref srcptr
	adc	1,s
	pha				; Save that off too
	clc
	lda	len			; ... to add 3 to the length for the
	adc	#$0003			;     REAL backref length code...
	plx				; ... load backref srcptr into X...
	ply				; ... load destptr into Y...
	mvn	#$7f,#$7f		; ... and blit it!
	tyx				; Adjusted destptr back to X
	ply				; And restore our srcptr
	sep	#$20			; Back to A8I16...
	.a8
	pla				; ... clear off the old lengths byte
	bra	loop			; ... and back for the next lengths
done:	sep	#$20			; Force A8I16 mode on exit
	pla				; pop the now-useless lengths byte
	plb				; Restore the original data block
	rts				; And return.
.endproc

	;; Internal helper function. Accumulator holds initial 4-bit
        ;; length, and this routine reads any extra length bytes out
        ;; of the source data and writes the len value appropriately.
.proc	rd_len
	sta	len
	stz	len+1
	cmp	#$0f			; multi-byte length?
	bne	done
loop:	lda	[srcptr],y
	iny
	cmp	#$ff
	bne	last
	rep	#$21
	.a16
	and	#$ff
	adc	len
	sta	len
	sep	#$20
	bra	loop
last:	rep	#$21
	and	#$ff
	adc	len
	sta	len
	sep	#$20
	.a8
done:	rts
.endproc
