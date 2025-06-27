;;; Z80Load: copies data into the Z80 address space.
;;; Arguments: a0: Source address (68k).
;;;            d0: Source length (bytes)
;;;            d1: Destination address (z80)
Z80Load:
	move.l	a2,-(a7)
	;; Capture bus from Z80
	lea	$a11100,a2
	move.w	#0,256(a2)
	move.w	#256,(a2)
	move.w	#256,256(a2)
.ZWait: btst	#0,(a2)
	bne.s	.ZWait

	;; Load Z80 player program
	lea	$a00000,a1
	and.w	#$1fff,d1
	add.w	d1,a1
	subq	#1,d0
.ZFill: move.b	(a0)+,(a1)+
	dbra	d0,.ZFill

	;; Give control back to Z80
	move.w	#0,256(a2)
	moveq	#19,d0
.ZRst:	dbra	d0,.ZRst
	move.w	#256,256(a2)
	move.w	#0,(a2)

	move.l	(a7)+,a2
	rts
