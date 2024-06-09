;;; ----------------------------------------------------------------------
;;;  hwlogo.asm: Display the Bumbershoot logo via direct hardware control
;;;    (c) 2024, Michael C. Martin
;;;  Available under the MIT license; see LICENSE for details.
;;; ----------------------------------------------------------------------

;; Register definitions and startup code from reference material
	include	"include/BareMetal.i"
	include	"include/SafeStart.i"

Main:	lea	Copper,a0		; Assign copper list
	move.l	a0,COP1LC(a5)

	;; Assign Bitplane pointers to copper list
	lea	Logo,a1
	moveq	#4,d1
.bplp:	move.l	a1,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	addq	#8,a0
	add	#128*128/8,a1
	dbra	d1,.bplp

	;; a1 now pointing at palette, so let's assign that
	lea	COLOR0(a5),a0
	moveq	#31,d0
.pallp:	move.w	(a1)+,(a0)+
	dbra	d0,.pallp

	;; Start DMA for Copper and bitplane graphics
	move.w	#$8180,DMACON(a5)	; Enable Bitplane and Copper DMA

	;; Wait for the user to click the mouse
.wait:	btst	#6,CIAAPRA
	bne.s	.wait

	;; Return to SafeStart to return control to OS
	rts

;;; ----------------------------------------------------------------------
;;;  Chipmem data: Copper list and graphics data
;;; ----------------------------------------------------------------------

	data_c

Copper:
	;; Bitplane pointers
	dc.w	BPL1PTH,0
	dc.w	BPL1PTL,0
	dc.w	BPL2PTH,0
	dc.w	BPL2PTL,0
	dc.w	BPL3PTH,0
	dc.w	BPL3PTL,0
	dc.w	BPL4PTH,0
	dc.w	BPL4PTL,0
	dc.w	BPL5PTH,0
	dc.w	BPL5PTL,0
	;; Display boundaries
	dc.w	DIWSTRT,$6CE1
	dc.w	DIWSTOP,$EC61
	;; DMA boundaries
	dc.w	DDFSTRT,$68
	dc.w	DDFSTOP,$A0
	;; Misc configuration
	dc.w	BPL1MOD,0	; No modulo for any bitplane
	dc.w	BPL2MOD,0
	dc.w	FMODE,0		; Slow DMA on post-OCS
	dc.w	BPLCON0,$5200	; 5 bitplanes, color on composite
	dc.w	BPLCON1,0	; Nothing else special
	dc.w	BPLCON2,0
	;; End of frame
	dc.w	$ffff,$fffe

Logo:	incbin "res/bumberlogo.bin"
