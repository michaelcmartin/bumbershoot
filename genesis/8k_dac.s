SetupDAC:
	lea	.PlayerProg,a0
	move.w	#(.PlayerProgEnd - .PlayerProg),d0
	moveq	#0,d1
	bra	Z80Load

.PlayerProg:
	incbin	"8k_dac.bin"
.PlayerProgEnd:

	align	2

PlaySample:
	movea.l	#$00a00008,a0
	movea.l	#$00a11100,a1
	move.w	#$0100,(a1)
	move.l	4(sp),d0
	moveq	#0,d1
	move.w	8(sp),d1
.z1:	btst	#0,(a1)
	bne.s	.z1
	move.b	d1,(a0)+
	lsr.l	#8,d1
	move.b	d1,(a0)+
	move.b	d0,(a0)+
	lsr.l	#8,d0
	move.b	d0,(a0)+
	lsr.l	#8,d0
	move.b	d0,(a0)
	move.w	#$00,(a1)
	rts
