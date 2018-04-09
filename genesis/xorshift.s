	seg     data
rnd_x:	ds	2
rnd_y:	ds	2

        seg text
srnd:   lea     rnd_x, a0
        move.l  #$10001, (a0)
	rts

rnd:	movem.l	d2-d3, -(sp)
        lea     rnd_x, a0
	;; x ^= x << 5
	move.w	(a0), d0
	move.w	2(a0), d1
	move.w	d0, d3
	moveq	#5, d2
	asl	d2, d3
	eor	d3, d0
	;; x ^= x >> 3
	move.w	d0, d3
	moveq	#3, d2
	lsr	d2, d3
	eor	d3, d0
	;; push y
	move.w	d1, (a0)
	;; y ^= y >> 1
	move.w	d1, d2
	lsr	#1, d2
	eor	d2, d1
	;; y ^= x
	eor	d1, d0
	;; pop x
	;; return y
	move.w	d0, 2(a0)
	movem.l	(sp)+, d2-d3
	rts
