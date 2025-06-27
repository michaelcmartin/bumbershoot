ReadJoy1:
	moveq	#$40,d0
	moveq	#0,d1
	lea	$a10003,a0		; I/O Port 1 Data
	lea	$a11100,a1
	move.w	#$100,(a1)		; Halt Z80
	move.b	d0,6(a0)		; Configure data direction
	move.b	d0,(a0)			; Strobe controller
	nop				; Wait two microseconds
	nop
	nop
	nop
	move.b	(a0),d0			; Read buttons
	move.b	#$00,(a0)		; Second strobe
	move.b	d0,d1
	and.b	#$0f,d1
	add.b	d0,d0
	and.b	#$60,d0
	or.b	d0,d1
	move.b	(a0),d0
	move.w	#0,(a1)			; Resume Z80
	add.b	d0,d0
	add.b	d0,d0
	asr.b	#2,d0
	and.b	#$90,d0
	or.b	d1,d0
	eor.b	#$ff,d0
	rts
