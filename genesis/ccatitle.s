BumbershootTitle:
	movem.l	d2-d3/a2-a3,-(a7)
	lea	$c00000,a2		; Set up VDP registers where function
	lea	4(a2),a3		; calls won't clobber them
	move.l	d0,d2			; Stash frame counter d0->d2

	bsr	ReadJoy1		; Skip title if START already down
	btst	#7,d0
	bne	.exit

	lea	.title,a0		; Set up messages
	move.w	#$8104,(a3)		; Disable display
.blit:	move.l	a0,d0			; Is address even?
	btst	#0,d0
	beq.s	.ok
	addq	#1,a0			; If not, advance one more
.ok:	move.l	(a0)+,d0		; Load next VRAM control
	beq.s	.ready			; Stop if done
	move.l	d0,(a3)
	moveq	#0,d0
.line:	move.b	(a0)+,d0		; Load next byte
	beq.s	.blit			; Finish string if null
	move.w	d0,(a2)			; Write to VRAM
	bra.s	.line
.ready:	move.w	#$8144,(a3)		; Re-enable display

	moveq	#1,d3			; Scanline to start the bleed
.wait:	move.w	(a3),d0
	btst	#3,d0			; Wait for no VBLANK
	bne.s	.wait
.v:	move.w	(a3),d0
	btst	#3,d0			; Wait for VBLANK
	beq.s	.v
	addq	#1,d2			; Increment frame count
	bsr	ReadJoy1
	btst	#7,d0			; Start pressed?
	bne.s	.exit			; If so, we're done here
	moveq	#0,d1			; Initial scroll value
	move.l	#$40000010,(a3)		; Write scroll to VSRAM
	move.w	d1,(a2)
	cmp.b	#222,d3			; Bleed effect finished?
	beq.s	.wait			; If so, we're done
.bzz:	move.b	8(a2),d0		; Otherwise spin till we reach line d3
	cmp.b	d3,d0
	bne.s	.bzz
	move.b	8(a2),d0		; Double-check in case of corruption
	cmp.b	d3,d0
	bne.s	.bzz
.bld:	subq	#1,d1
	move.l	#$40000010,(a3)		; Write scroll to VSRAM
	move.w	d1,(a2)
.bz2:	cmp.b	8(a2),d0
	beq.s	.bz2
	addq	#1,d0
	cmp.b	#223,d0
	bne.s	.bld
	subq	#1,d1
	move.l	#$40000010,(a3)		; Write final scroll to VSRAM
	move.w	d1,(a2)
	addq	#1,d3			; Start bleed one line down next frame
	bra.s	.wait

.exit:	move.w	#$8104,(a3)		; Disable display so changes in raster
	move.l	#$40000003,(a3)		; effects don't glitch display as we
	move.w	#2047,d1		; clear it
	moveq	#$00,d0
.cls:	move.l	d0,(a2)
	dbra	d1,.cls
	move.w	#$8144,(a3)		; Re-enable display now that it's safe

.wait2:	move.w	(a3),d0
	btst	#3,d0			; Wait for no VBLANK
	bne.s	.wait2
.v2:	move.w	(a3),d0
	btst	#3,d0			; Wait for VBLANK
	beq.s	.v2
	addq	#1,d2			; Increment frame count
	bsr	ReadJoy1
	btst	#7,d0			; Start pressed?
	bne.s	.wait2			; If so, keep waiting

	move.l	d2,d0			; Return updated frame count in d0
	movem.l	(a7)+,d2-d3/a2-a3
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
