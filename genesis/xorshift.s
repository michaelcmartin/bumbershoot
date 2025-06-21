	seg	data
rnd_v:	ds	4			; "x" and "y" words in that order

	seg text
srnd:	move.l	d0,rnd_v
	;; fall through to tick_rnd

tick_rnd:
	lea	rnd_v,a0
	moveq	#1,d0
	add.l	d0,(a0)
	tst.w	(a0)
	bne.s	.ok
	add.w	d0,(a0)
.ok:	tst.w	2(a0)
	bne.s	.ok2
	add.w	d0,2(a0)
.ok2:	rts

rnd:	movem.l	d2-d3,-(sp)
	lea	rnd_v,a0
	;; x ^= x << 5
	move.w	(a0),d0
	move.w	2(a0),d1
	move.w	d0,d3
	moveq	#5,d2
	asl	d2,d3
	eor	d3,d0
	;; x ^= x >> 3
	move.w	d0,d3
	moveq	#3,d2
	lsr	d2,d3
	eor	d3,d0
	;; push y
	move.w	d1,(a0)
	;; y ^= y >> 1
	move.w	d1,d2
	lsr	#1,d2
	eor	d2,d1
	;; y ^= x
	eor	d1,d0
	;; pop x
	;; return y
	move.w	d0,2(a0)
	movem.l	(sp)+,d2-d3
	rts
