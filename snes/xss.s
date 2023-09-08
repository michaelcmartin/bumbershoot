	.p816
	.a16
	.i16
	.export	seed_rnd, rnd

	.zeropage
state:	.res	8
ws:	.res	8
mul2:	.res	8
prod:	.res	8

	.code

;;; seed_rnd: Seed the PRNG.
;;; INPUT: 32-bit seed in .AX (MX must both be 16-bit).
;;; OUTPUT: None.
;;; TRASHES: .A
.proc	seed_rnd
	ora	#1
	sta	state
	stx	state+2
	sta	state+4
	stx	state+6
	rts
.endproc

;;; rnd: Advance RNG
;;; INPUT: None
;;; OUTPUT: 32 bits of randomness in .AX
;;; TRASHES: None
.proc	rnd
	php
	rep	#$30			;; state ^= state >> 12
	jsr	copy_state
	ldx	#4
	jsr	bulk_lsr
	lda	ws+1
	eor	state
	sta	state
	lda	ws+3
	eor	state+2
	sta	state+2
	lda	ws+5
	eor	state+4
	sta	state+4
	lda	ws+7
	and	#$ff
	eor	state+6
	sta	state+6
	jsr	copy_state		; state ^= state << 25
	asl	ws
	rol	ws+2
	rol	ws+4
	rol	ws+6
	lda	ws
	eor	state+3
	sta	state+3
	lda	ws+2
	eor	state+5
	sta	state+5
	lda	ws+4
	and	#$ff
	eor	state+7
	sta	state+7
	jsr	copy_state		; state ^= state >> 27
	ldx	#3
	jsr	bulk_lsr
	lda	ws+3
	eor	state
	sta	state
	lda	ws+5
	eor	state+2
	sta	state+2
	lda	ws+7
	and	#$ff
	eor	state+4
	sta	state+4

	jsr	copy_state		; Prepare for multiply
	lda	#$dd1d
	sta	mul2
	lda	#$4f6c
	sta	mul2+2
	lda	#$f491
	sta	mul2+4
	lda	#$2545
	sta	mul2+6
	stz	prod
	stz	prod+2
	stz	prod+4
	stz	prod+6

	ldx	#$40			; Do the multiply
:	lsr	mul2+6
	ror	mul2+4
	ror	mul2+2
	ror	mul2
	bcc	:+
	clc
	lda	prod
	adc	ws
	sta	prod
	lda	prod+2
	adc	ws+2
	sta	prod+2
	lda	prod+4
	adc	ws+4
	sta	prod+4
	lda	prod+6
	adc	ws+6
	sta	prod+6
:	asl	ws
	rol	ws+2
	rol	ws+4
	rol	ws+6
	dex
	bne	:--

	lda	prod+4			; Return top 32 bits as result
	ldx	prod+6
	plp
	rts

copy_state:
	lda	state
	sta	ws
	lda	state+2
	sta	ws+2
	lda	state+4
	sta	ws+4
	lda	state+6
	sta	ws+6
	rts

bulk_lsr:
	lsr	ws+6
	ror	ws+4
	ror	ws+2
	ror	ws
	dex
	bne	bulk_lsr
	rts
.endproc

