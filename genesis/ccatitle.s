BumbershootTitle:
	move.l	a2,-(a7)
	lea	$c00000,a0		; Set up VDP registers
	lea	4(a0),a2
	lea	.title,a1		; Set up messages
	move.w	#$8104,(a2)		; Disable display
.blit:	move.l	a1,d0			; Is address even?
	btst	#0,d0
	beq.s	.ok
	addq	#1,a1			; If not, advance one more
.ok:	move.l	(a1)+,d0		; Load next VRAM control
	beq.s	.ready			; Stop if done
	move.l	d0,(a2)
	moveq	#0,d0
.line:	move.b	(a1)+,d0		; Load next byte
	beq.s	.blit			; Finish string if null
	move.w	d0,(a0)			; Write to VRAM
	bra.s	.line
.ready:	move.w	#$8144,(a2)		; Re-enable display

.wait:	move.w	(a2),d0
	btst	#3,d0			; Wait for no VBLANK
	bne.s	.wait
.v:	move.w	(a2),d0
	btst	#3,d0			; Wait for VBLANK
	beq.s	.v
	bsr	ReadJoy1
	btst	#7,d0			; Start pressed?
	beq.s	.wait			; If not, keep waiting

.wait2:	move.w	(a2),d0
	btst	#3,d0			; Wait for no VBLANK
	bne.s	.wait2
.v2:	move.w	(a2),d0
	btst	#3,d0			; Wait for VBLANK
	beq.s	.v2
	bsr	ReadJoy1
	btst	#7,d0			; Start pressed?
	bne.s	.wait2			; If so, keep waiting

	move.l	#$40000003,(a2)
	subq	#4,a2
	move.w	#2047,d1
	moveq	#$00,d0
.cls:	move.l	d0,(a2)
	dbra	d1,.cls

	move.l	(a7)+,a2
	rts

.title:	dc.l	$41940003
	dc.b	"BUMBERSHOOT SOFTWARE",0
	even
	dc.l	$42240003
	dc.b	"2025",0
	even
	dc.l	$43200003
	dc.b	"PRESENTS",0
	even
	dc.l	$469e0003
	dc.b	"THE CYCLIC",0
	even
	dc.l	$47160003
	dc.b	"CELLULAR AUTOMATON",0
	even
	dc.l	$4c140003
	dc.b	"PRESS START TO BEGIN",0
	even
	dc.l	0
