	.p816
	.a16
	.i16
	.export	seed_rnd, rnd, mix_rnd

	.zeropage
rnd_x:	.res	2
rnd_y:	.res	2

	.code

;;; seed_rnd: Seed the PRNG.
;;; INPUT: 32-bit seed in .AX (MX must both be 16-bit).
;;; OUTPUT: None.
;;; TRASHES: .AX (any zero in the reg becomes 1)
.proc	seed_rnd
	cmp	#$00
	bne	:+
	inc	a
:	cpx	#$00
	bne	:+
	inx
:	sta	rnd_x
	stx	rnd_y
	rts
.endproc

;;; mix_rnd: Add entropy to the PRNG seed.
;;; INPUT: 16-bit mix value in .A (MX must both be 16-bit).
;;; OUTPUT: None.
;;; TRASHES: .AX.
.proc	mix_rnd
	ldx	rnd_y
	clc
	adc	rnd_x
	bcc	:+
	inx
:	jmp	seed_rnd
.endproc

;;; rnd: Advance RNG
;;; INPUT: None
;;; OUTPUT: 8-16 bits of randomness in .A
;;; TRASHES: None
.proc	rnd
	php
	rep	#$30
	.a16
	.i16
	lda	rnd_x			; x ^= x << 5
	.repeat	5
	asl	a
	.endrep
	eor	rnd_x
	sta	rnd_x
	.repeat	3			; x ^= x >> 3
	lsr	a
	.endrep
	eor	rnd_x
	sta	rnd_x
	lda	rnd_y			; push y
	pha
	lsr	a			; y ^= y >> 1
	eor	rnd_y
	eor	rnd_x			; y ^= x
	sta	rnd_y
	pla				; pop x
	sta	rnd_x
	lda	rnd_y			; return y
	plp
	rts
.endproc

