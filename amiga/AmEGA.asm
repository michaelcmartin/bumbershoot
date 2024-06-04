;;; ----------------------------------------------------------------------
;;;  AmEGA.asm: Display all 64 EGA colors in a single display
;;;    (c) 2024, Michael C. Martin
;;;  Available under the MIT license; see LICENSE for details.
;;; ----------------------------------------------------------------------

;; Register definitions and startup code from reference material
	include	"include/BareMetal.i"
	include	"include/SafeStart.i"

Main:	lea	Copper,a0		; Assign copper list
	move.l	a0,COP1LC(a5)

	;; Assign Bitplane pointers to copper list
	lea	bmp,a2
	move.l	a2,d0
	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)

	;; Start DMA for Copper and bitplane graphics
	move.w	#$8180,DMACON(a5)	; Enable Bitplane and Copper DMA

	;; Fill bitplane
	move.l	a2,a0
	move.w	#$9f,d1
.hdlp:	clr.l	(a0)+
	dbra	d1,.hdlp
	move.l	#$5555AAAA,d0
	move.w	#$12bf,d1
.midlp:	move.l	d0,(a0)+
	dbra	d1,.midlp
	move.w	#$9f,d1
.ftlp:	clr.l	(a0)+
	dbra	d1,.ftlp

	;; Draw the header and footer text
	lea	headertext(PC),a0
	lea	12(a2),a1
	bsr	drawtext_80
	lea	footertext(PC),a0
	lea	19860(a2),a1
	bsr	drawtext_80

	;; Wait for the user to click the mouse
.wait:	btst	#6,CIAAPRA
	bne.s	.wait

	;; Return to SafeStart to return control to OS
	rts

headertext:
	dc.b	"FLEXING ON IBM PC GRAPHICS IN 1985 WHILE WE STILL CAN...",0
footertext:
	dc.b	"80-COLUMN TEXT WITH ALL 64 EGA COLORS!!!",0
	even

drawtext_80:
	movem.l	a2-4,-(a7)
	lea	font,a2
.loop:	moveq	#0,d0			; Read next character
	move.b	(a0)+,d0
	beq.s	.done			; Quit if it's the null terminator
	and.b	#63,d0			; Convert to screencode
	lsl.w	#3,d0			; Put address of char in a3
	lea	(a2,d0),a3
	move.l	a1,a4			; Draw character
	moveq	#7,d1
.char:	move.b	(a3)+,(a4)
	add	#80,a4
	dbra	d1,.char
	addq	#1,a1			; Advance to next char position
	bra.s	.loop
.done:	movem.l	(a7)+,a2-4
	rts

;;; ----------------------------------------------------------------------
;;;  Public memory data
;;; ----------------------------------------------------------------------

	data
font:	incbin	"sinestra.bin"

;;; ----------------------------------------------------------------------
;;;  Chipmem data: Copper list and graphics data
;;; ----------------------------------------------------------------------

	data_c

Copper:
	;; Bitplane pointers
	dc.w	BPL1PTH,0
	dc.w	BPL1PTL,0
	;; Initial palette
	dc.w	COLOR0,$005A
	dc.w	COLOR1,$0FFF
	;; Display boundaries
	dc.w	DIWSTRT,$2C81
	dc.w	DIWSTOP,$2CC1
	;; DMA boundaries
	dc.w	DDFSTRT,$3C
	dc.w	DDFSTOP,$D4
	;; Fixed configuration
	dc.w	BPL1MOD,0	; No modulo for any bitplane
	dc.w	BPL2MOD,0
	dc.w	FMODE,0		; Slow DMA on post-OCS
	dc.w	BPLCON0,$9200	; 1 bitplane, hi-res, color on composite
	dc.w	BPLCON1,0	; Nothing else special
	dc.w	BPLCON2,0
	dc.w	$ffff,$fffe	; Wait indefinitely

	bss_c
bmp:	ds.b	80*256
