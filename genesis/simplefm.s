SetupFM:
	moveq	#0,d0
	move.w	#$100,d1
	;; Capture bus from Z80
	movea.l #$00a11100,a0
	move.w	d1,(a0)
	move.w	d1,$100(a0)
.ZWait:	btst	d0,(a0)
	bne.s	.ZWait

	;; Load Z80 player program
	move.l	#$00a00000,a0
	lea	.PlayerProg(pc),a1
	move.w	#(.PlayerProgEnd - .PlayerProg - 1),d0
.ZFill:	move.b	(a1)+,(a0)+
	dbra	d0,.ZFill

	;; Give control back to Z80
	movea.l #$00a11100,a0
	moveq	#0,d0
	move.w	d0,$100(a0)
	move.w	d0,(a0)
	moveq	#19,d0
.ZRst:	dbra	d0,.ZRst
	move.w	d1,$100(a0)

	rts

.PlayerProg:
	incbin	"fm_mus.bin"
.PlayerProgEnd:

	align	2
