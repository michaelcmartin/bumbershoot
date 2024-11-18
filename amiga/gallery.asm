;;; ----------------------------------------------------------------------
;;;  Gallery.asm: Simple shooting gallery game
;;;    (c) 2024, Michael C. Martin
;;;  Available under the MIT license; see LICENSE for details.
;;; ----------------------------------------------------------------------

	;; Register definitions and startup code from reference material
	include	"include/BareMetal.i"
	include	"include/SafeStart.i"

spr_list:
	dc.l	gfx_blaster_l, gfx_blaster_r, gfx_target, gfx_none
	dc.l	gfx_missiles, gfx_none, gfx_none, gfx_none

Main:	lea	Copper,a2		; a2 = copper list base addr
	lea	bmp,a3			; a3 = graphics buffer base addr
	move.l	a3,d0			; Load bitplane location into copper list
	move.w	d0,6(a2)
	swap	d0
	move.w	d0,2(a2)
	lea	spr_list(PC),a0
	lea	8(a2),a1		; Load sprite definitions into place
	moveq	#7,d1
.sprlp:	move.l	(a0)+,d0
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	add	#8,a1
	dbra	d1,.sprlp
	move.l	a2,COP1LC(a5)		; Set primary copper list

.start:	move.w	#$81e0,DMACON(a5)	; Enable Bitplane, Copper, Sprite, and Blitter DMA

	;; Clear screen
	bsr	blitter_wait
	move.l	#$01000000,BLTCON0(a5)
	move.l	a3,BLTDPT(a5)
	clr.w	BLTDMOD(a5)
	move.w	#496*64+40,BLTSIZE(a5)
	bsr	blitter_wait

	;; Draw score and footer
	lea	msg,a0
	lea	25(a3),a1
	bsr	drawtext
	lea	msg2,a0
	lea	9938(a3),a1
	bsr	drawtext

	;; Set up keyboard IRQs
	moveq	#0,d0
	move.b	d0,pending
	move.b	d0,ready
	move.l	S_VBR,a0	; Save out original handler
	move.l	IRQ2(a0),-(a7)
	lea	irq2_handler(pc),a1
	move.l	a1,IRQ2(a0)
	move.w	#$8008,INTENA(a5)	; Enable IRQ 2

	;; Wait for the user to click the mouse
.wait:	tst.b	ready
	bne.s	.end
	btst	#6,CIAAPRA
	bne.s	.wait

	;; Clean up interrupt handlers
.end:	move.w	#$0008,INTENA(a5)
	move.l	S_VBR,a0
	move.l	(a7)+,IRQ2(a0)
	;; Return to SafeStart to return control to OS
	rts

irq2_handler:
	movem.l	d0-d3,-(a7)		; Save out registers

	move.b	CIAAICR,d0
	btst	#3,d0			; Was this the keyboard interrupt?
	bne.s	.kb			; If so, handle key event
	btst	#0,d0			; Was this Timer A?
	beq.s	.end			; If not, skip everything

	bclr.b	#6,CIAACRA		; If so, finish handshake
	move.b	#$01,CIAAICR		; Disable Timer A interrupt
	move.b	pending,ready		; And confirm keystroke
	bra.s	.end

.kb:	move.b	CIAASDR,d0		; Read actual keyboard data
	cmp.b	#$75,d0			; Was it pressing ESCAPE?
	bne.s	.handshake		; If not, ignore it
	move.b	#$ff,pending		; Otherwise, record pending keypress

.handshake:
	move.b	#$48,CIAACRA		; Serial output, single-shot timer on A
	clr.b	CIAASDR			; Serial signal low
	move.b	#75,CIAATALO		; for 75 ticks
	clr.b	CIAATAHI
	move.b	#$81,CIAAICR		; Enable Timer A interrupt

.end:	move.w	#$0008,$dff000+INTREQ	; Acknowledge INT2 IRQ
	movem.l	(a7)+,d0-d3
	rte

	;; Copy 1bpp text string (a0) to graphics memory (a1).
drawtext:
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
	add	#40,a4
	dbra	d1,.char
	addq	#1,a1			; Advance to next char position
	bra.s	.loop
.done:	movem.l	(a7)+,a2-4
	rts

blitter_wait:
	btst	#14,DMACONR(a5)		; Amiga 1000 compat dummy read
.lp:	btst	#14,DMACONR(a5)
	bne.s	.lp
	rts

;;; ----------------------------------------------------------------------
;;;  Public memory data
;;; ----------------------------------------------------------------------

	data
font:	incbin	"res/sinestra.bin"
msg:	dc.b	"SCORE: 0000",0
msg2:	dc.b	"INITIAL SPRITE EXAMPLE",0
	even

;;; ----------------------------------------------------------------------
;;;  Chipmem data: Copper list and graphics data
;;; ----------------------------------------------------------------------

	data_c

Copper:
	;; Bitplane pointers
	dc.w	BPL1PTH,0
	dc.w	BPL1PTL,0
	;; Sprite pointers
	dc.w	SPR0PTH,0
	dc.w	SPR0PTL,0
	dc.w	SPR1PTH,0
	dc.w	SPR1PTL,0
	dc.w	SPR2PTH,0
	dc.w	SPR2PTL,0
	dc.w	SPR3PTH,0
	dc.w	SPR3PTL,0
	dc.w	SPR4PTH,0
	dc.w	SPR4PTL,0
	dc.w	SPR5PTH,0
	dc.w	SPR5PTL,0
	dc.w	SPR6PTH,0
	dc.w	SPR6PTL,0
	dc.w	SPR7PTH,0
	dc.w	SPR7PTL,0
	;; Initial palette
	dc.w	COLOR0,$005a
	dc.w	COLOR1,$0fff
	dc.w	COLOR17,$0555
	dc.w	COLOR18,$00a5
	dc.w	COLOR19,$0fa5
	dc.w	COLOR21,$0a00
	dc.w	COLOR22,$000a
	dc.w	COLOR23,$0fff
	dc.w	COLOR25,$0550
	dc.w	COLOR26,$0aa0
	dc.w	COLOR27,$0ff0
	;; Display boundaries
	dc.w	DIWSTRT,$2c81
	dc.w	DIWSTOP,$2cc1
	;; DMA boundaries
	dc.w	DDFSTRT,$38
	dc.w	DDFSTOP,$d0
	;; Fixed configuration
	dc.w	BPL1MOD,0	; No modulo
	dc.w	FMODE,0		; Slow DMA on post-OCS
	dc.w	BPLCON0,$1200	; 1 bitplane, low-res, color on composite
	dc.w	BPLCON1,0	; Nothing else special
	dc.w	BPLCON2,0
	;; Draw divider line with Copper
	dc.w	$380f,$fffe
	dc.w	COLOR0,$0fff
	dc.w	$3a0f,$fffe
	dc.w	COLOR0,$005a
	;; Draw ground with Copper
	dc.w	$fc0f,$fffe
	dc.w	COLOR0,$0270
	;; Wait for end of frame
	dc.w	$ffff,$fffe

	;; Sprite graphics
gfx_blaster_l:
	dc.w	$efd0,$fc00
	dc.w	%0000000000100000, %0000000000100000
	dc.w	%0000000000100000, %0000000000100000
	dc.w	%0000000001110000, %0000000001110000
	dc.w	%0000000010101000, %0000000010101000
	dc.w	%0000000011111000, %1111100011111000
	dc.w	%1110001010101010, %0001101010101010
	dc.w	%1110001111111110, %0001101111111110
	dc.w	%1110001011111010, %0001101011111010
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0001100000000110, %1110011111111001
	dc.w	%0011110000001111, %1100001111110000
	dc.w	%0001100000000110, %0000000000000000
gfx_none:
	dc.w	0,0

gfx_blaster_r:
	dc.w	$ef50,$fc00
	dc.w	%0000010000000000, %0000010000000000
	dc.w	%0000010000000000, %0000010000000000
	dc.w	%0000111000000000, %0000111000000000
	dc.w	%0001010100000000, %0001010100000000
	dc.w	%0001111100000000, %0001111100011111
	dc.w	%0101010101000111, %0101010101011000
	dc.w	%0111111111000111, %0111111111011000
	dc.w	%0101111101000111, %0101111101011000
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0110000000011000, %1001111111100111
	dc.w	%1111000000111100, %0000111111000011
	dc.w	%0110000000011000, %0000000000000000
	dc.w	0,0

gfx_target:
	dc.w	$508c,$6000
	dc.w	%0000001111000000, %0000001111000000
	dc.w	%0000111111110000, %0000110000110000
	dc.w	%0001111111111000, %0001001111001000
	dc.w	%0011110000111100, %0010111111110100
	dc.w	%0111101111011110, %0101111111111010
	dc.w	%0111011111101110, %0101111001111010
	dc.w	%1110111111110111, %1011110110111101
	dc.w	%1110111001110111, %1011101111011101
	dc.w	%1110111001110111, %1011101111011101
	dc.w	%1110111111110111, %1011110110111101
	dc.w	%0111011111101110, %0101111001111010
	dc.w	%0111101111011110, %0101111111111010
	dc.w	%0011110000111100, %0010111111110100
	dc.w	%0001111111111000, %0001001111001000
	dc.w	%0000111111110000, %0000110000110000
	dc.w	%0000001111000000, %0000001111000000
	dc.w	0,0

gfx_missiles:
	dc.w	$98d5,$9e00
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%1000000000000000, %0000000000000000
	dc.w	$a052,$a601
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%1000000000000000, %0000000000000000
	dc.w	$a8d5,$ae00
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%1000000000000000, %0000000000000000
	dc.w	$d8d5,$de00
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%1000000000000000, %0000000000000000
	dc.w	$e052,$e601
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%1000000000000000, %0000000000000000
	dc.w	0,0

	bss_c
bmp:	ds.b	40*256
pending:
	ds.b	1
ready:	ds.b	1
