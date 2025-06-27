;;; Bumbershoot Software intro (logo/sound)
;;; This routine includes a skip to a 32KB boundary so it's probably best
;;; to put it at the very end of any given project
;;; Include lz4dec.s, 8k_dac.s, joystick.s, and z80load.s in any project that
;;; includes this, and include lz4dec _immediately_ before this file.
;;; As a side effect this function will add the frame count spent to the
;;; value in d0

BumbershootLogo:
	movem.l	d2-d4/a2-a3,-(sp)
	move.l	d0,d4			; Shift frame count from d0->d4

	lea	.logodata,a0
	lea	$ff0000,a1
	bsr.s	lz4dec			; Puts amount uncompressed in d0

	lea	$C00000,a2
	lea	4(a2),a3
	lea	$ff0000,a1

	;; Load palette
	move.w	#$8f02,(a3)		; VDP increment = 2
	move.l	#$c0000000,(a3)		; Write to CRAM 0
	moveq	#15,d1
.pallp: move.l	(a1)+,(a2)
	dbra	d1,.pallp

	;; Load patterns
	sub.l	#$3040,d0		; Total pattern bytes in d0
	lsr.l	#2,d0			; Total pattern longwords
	subq	#1,d0			; Adjustment for dbra
	move.l	#$40000000,(a3)		; Write to VRAM $0000
.patlp: move.l	(a1)+,(a2)
	dbra	d0,.patlp

	;; Load nametables
	move.l	#$40000003,(a3)		; Write to VRAM $C000
	move.w	#3071,d0
.namlp: move.l	(a1)+,(a2)
	dbra	d0,.namlp

	;; Enable the display
	move.w	#$8144,(a3)

	;; Set up the sample player
	bsr	SetupDAC

	;; Sing a song
	move.w	#.logosong_end-.logosong,-(sp)
	move.l	#.logosong,-(sp)
	bsr	PlaySample
	addq	#6,sp

	;; Wait 240 frames or until START is pressed
	move.w	#240,d2
.v1:	move.w	(a3),d0
	btst	#3,d0			; Wait for no VBLANK
	bne.s	.v1
.v2:	move.w	(a3),d0
	btst	#3,d0			; Wait for VBLANK
	beq.s	.v2
	addq	#1,d4			; Increment frame count
	bsr	ReadJoy1
	btst	#7,d0			; Start pressed?
	bne	.skip			; If so, end immediately
	dbra	d2,.v1

	;; --- Fade out logo ---

	;; Step 1: split out each color into three words for R G B
	lea	$ff0000,a0
	lea	64(a0),a1
	moveq	#31,d0
.fade1: move.w	(a0)+,d1
	move.w	d1,d2
	and.w	#$00f,d2
	lsr.w	#1,d2
	move.w	d2,(a1)+
	move.w	d1,d2
	and.w	#$0f0,d2
	lsr.w	#5,d2
	move.w	d2,(a1)+
	move.w	d1,d2
	and.w	#$f00,d2
	lsr.w	#8,d2
	lsr.w	#1,d2
	move.w	d2,(a1)+
	dbra	d0,.fade1
	;; Step 2: Create "fixed point" buffers for each color to hold our
	;; full intermediate colors. Note that at this point a0 is where a1
	;; started, and a1 is our new destination
	moveq	#95,d0
.fade2: move.w	(a0)+,d1
	lsl.w	#6,d1
	move.w	d1,(a1)+
	dbra	d0,.fade2
	;; Step 3: 60-frame loop where we repeatedly subtract the step 1
	;; buffer from the step 2 buffer, reassemble the palette, and blit it
	;; to CRAM
	moveq	#59,d3
.fade3: lea	$ff0040,a0		; 3a: Subtract 1st buffer from 2nd
	lea	192(a0),a1
	moveq	#95,d0
.f3a:	move.w	(a0)+,d1
	sub.w	d1,(a1)+
	dbra	d0,.f3a
.f3b1:	move.w	(a3),d0			; 3b: Wait for VBLANK, abort if START
	btst	#3,d0
	bne.s	.f3b1
.f3b2:	move.w	(a3),d0
	btst	#3,d0
	beq.s	.f3b2
	addq	#1,d4			; Increment frame count
	bsr	ReadJoy1
	btst	#7,d0
	bne.s	.skip
	lea	$ff0100,a0		; 3c: Reassemble palette and blit to CRAM
	move.l	#$c0000000,(a3)
	moveq	#31,d0
.f3c:	move.w	(a0)+,d2
	lsr.w	#5,d2
	and.w	#$00e,d2
	move.w	(a0)+,d1
	lsr.w	#1,d1
	and.w	#$0e0,d1
	or.w	d1,d2
	move.w	(a0)+,d1
	lsl.w	#3,d1
	and.w	#$e00,d1
	or.w	d1,d2
	move.w	d2,(a2)
	dbra	d0,.f3c
	dbra	d3,.fade3

	;; Stop playback by taking over the Z80 bus and forcing a reset
.skip:	move.w	#0,$a11200
	move.w	#256,$a11100

	;; Clear screen
	move.l	#$40940003,(a3)
	move.w	#3071,d1
	moveq	#$00,d0
.cls:	move.l	d0,(a2)
	dbra	d1,.cls

	;; Restore palette in CRAM
	move.l	#$c0000000,(a3)
	lea	$ff0000,a0
	moveq	#15,d0
.pfix:	move.l	(a0)+,(a2)
	dbra	d0,.pfix

	move.l	d4,d0			; Adjusted frame counter back to d0
	movem.l	(sp)+,d2-d4/a2-a3
	rts

.logodata:
	incbin	"res/logogfx.bin"

	;; Put our sound sample on a 32KB boundary so the Z80 can see
	;; it all at once
	org	(*+$7fff)&$ff8000
.logosong:
	incbin	"res/bumbersong.bin"
.logosong_end:
