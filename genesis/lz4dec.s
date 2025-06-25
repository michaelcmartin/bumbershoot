;;; ----------------------------------------------------------------------
;;;   Unframed LZ4 Decoder
;;;   a0: source buffer
;;;   a1: destination buffer
;;; ----------------------------------------------------------------------

lz4dec:	movem.l	d2-d3/a2-a3,-(a7)
	move.l	a1,a3			; Cache original pointer
.loop:	move.b	(a0)+,d0		; Load lengths byte into d0
	moveq	#0,d1			; Literals length nybble in d1
	move.b	d0,d1
	lsr.w	#4,d1
	beq.s	.bkref			; Go to backref if there aren't any
	bsr.s	.rdlen			; Read rest of literals length
.copy:	move.b	(a0)+,(a1)+		; And do the byte copy
	dbra	d1,.copy
.bkref:	moveq	#0,d2			; Load little-endian backref
	moveq	#0,d3
	move.b	(a0)+,d3
	move.b	(a0)+,d2
	lsl.w	#8,d2
	or.w	d3,d2
	beq.s	.done			; Quit if it's zero
	move.l	a1,a2			; a2 = a1 - d2 UNSIGNED
	sub.l	d2,a2			; so no LEA
	moveq	#0,d1			; Backref length nybble in d0
	move.b	d0,d1
	and.b	#$0f,d1
	bsr.s	.rdlen			; Read rest of length
	addq	#4,d1			; Add 4 for true backref length
.copy2:	move.b	(a2)+,(a1)+		; and then do the copy
	dbra	d1,.copy2
	bra.s	.loop			; and back to start
.done:	suba.l	a3,a1			; Compute length
	move.l	a1,d0			; and return in d0
	movem.l	(a7)+,d2-d3/a2-a3
	rts

	;; Internal helper function. d1 holds the initial 4-bit length,
	;; and this routine reads any extra length bytes out of a0 and
	;; puts the final value into d1, predecremented for use with
	;; the DBRA instruction. Advances a0 as needed, trashes d2
.rdlen:	cmp.w	#15,d1
	bne.s	.rdone
	moveq	#0,d2
.rloop:	move.b	(a0)+,d2
	add.w	d2,d1
	cmp	#$ff,d2
	beq.s	.rloop
.rdone:	subq	#1,d1
	rts

