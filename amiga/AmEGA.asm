;;; ----------------------------------------------------------------------
;;;  AmEGA.asm: Display all 64 EGA colors in a single display
;;;    (c) 2024, Michael C. Martin
;;;  Available under the MIT license; see LICENSE for details.
;;; ----------------------------------------------------------------------

	;; Register definitions and startup code from reference material
	include	"include/BareMetal.i"
	include	"include/SafeStart.i"

	;; Mapping graphics offsets into copper offsets
	;; (Negative offset ends the list)

CpOffs:	dc.w	0,0,640,footC-Copper,1280,imgC-Copper
	dc.w	1320,8,1360,16,1400,24
	dc.w	$ffff

Main:	lea	Copper,a2		; a2 = copper list base addr
	lea	bmp,a3			; a3 = graphics buffer base addr
	move.l	a2,COP1LC(a5)		; Set primary copper list

	;; Assign Bitplane pointers to copper list
	lea	CpOffs(PC),a4
.bplp:	move.w	(a4)+,d0
	bmi.s	.start
	move.w	(a4)+,d1
	lea	(a3,d0),a0
	lea	(a2,d1),a1
	move.l	a0,d0
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	bra.s	.bplp

.start:	move.w	#$81c0,DMACON(a5)	; Enable Bitplane, Copper, and Blitter DMA

	;; Clear graphic area
	bsr	blitter_wait
	move.l	#$01000000,BLTCON0(a5)
	move.l	a3,BLTDPT(a5)
	clr.w	BLTDMOD(a5)
	move.w	#496*64+40,BLTSIZE(a5)
	bsr	blitter_wait

	;; Draw the color boxes. 32x23 drawing unit, border starts
	;; 2 pixels in on sides, 1 row margin on top and bottom.
	;; Border is 2 thick on the sides and 1 thick on top and
	;; bottom. Center color patch is thus 28x18.
	;; NTSC starts at row 9. PAL wants 32x30 unit.
	lea	1284(a3),a2	; 32px in from start of low-res
	moveq	#7,d2
	moveq	#2,d3
.boxlp:	move.l	a2,a0
	move.w	d3,d0
	bsr	drawbox
	addq	#4,a2
	addq	#1,d3
	dbra	d2,.boxlp

	;; Copy the next seven rows based on the first
	lea	1280(a3),a0
	lea	6080(a3),a1
	move.l	a0,BLTAPT(a5)
	move.l	a1,BLTDPT(a5)
	clr.w	BLTAMOD(a5)
	move.l	#$ffffffff,BLTAFWM(a5)
	move.w	#$09f0,BLTCON0(a5)
	move.w	#420*64+40,BLTSIZE(a5)

	;; Draw the header and footer text while the blitter does its thing
	lea	headertext(PC),a0
	lea	12(a3),a1
	bsr	drawtext_80
	lea	footertext(PC),a0
	lea	660(a3),a1
	bsr	drawtext_80

	;; Draw the numeric labels
	clr.w	-(a7)		; Push the ASCIIZ string "00"
	move.w	#$3030,-(a7)
	lea	3045(a3),a4	; Write cursor
	bsr	blitter_wait	; Make sure blitter has finished copying
	moveq	#63,d2
.numlp:	move.l	a4,a1		; Draw label at cursor
	move.l	a7,a0
	bsr	drawtext_40
	addq	#4,a4		; Move cursor right
	move.b	1(a7),d0	; Increment ones digit
	addq	#1,d0
	cmp.b	#$38,d0		; Is it 8?
	bne.s	.not8
	add	#4768,a4	; If so, move to next line
.not8:	cmp.b	#$07,d0		; Is it 17?
	bne.s	.not17
	add	#4768,a4	; If so move to next line
	add.b	#1,(a7)		; and advance 16s digit
	moveq	#$30,d0		; and reset 1s digit
.not17:	cmp.b	#$3a,d0		; Is it 10?
	bne.s	.not10
	moveq	#1,d0		; Fix digit to 'A'.
.not10:	move.b	d0,1(a7)	; write back ones digit
	dbra	d2,.numlp
	addq	#4,a7		; Pop the label string

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

headertext:
	dc.b	"FLEXING ON IBM PC GRAPHICS IN 1985 WHILE WE STILL CAN...",0
footertext:
	dc.b	"80-COLUMN TEXT WITH ALL 64 EGA COLORS!!!",0
	even

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
	btst	#0,d0			; Was it a key-up?
	beq.s	.handshake		; If so, ignore it
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

	;; Overlay 4bpp text string (a0) to graphics memory (a1). Draws
	;; in color 15, overlays previous graphics.
drawtext_40:
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
.char:	move.b	(a3)+,d0
	or.b	d0,(a4)
	or.b	d0,40(a4)
	or.b	d0,80(a4)
	or.b	d0,120(a4)
	add	#160,a4
	dbra	d1,.char
	addq	#1,a1			; Advance to next char position
	bra.s	.loop
.done:	movem.l	(a7)+,a2-4
	rts

	;; a0 = first longword to write in image
	;; d0 = internal color for box
drawbox:
	movem.l	d2-5,-(a7)
	move.l	#$3ffffffc,d1
	move.l	d1,160(a0)
	move.l	d1,4480(a0)		; 3360 for NTSC
	add.w	#320,a0
	move.l	#$0ffffff0,d5
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	lsr	#1,d0
	bcc.s	.n1
	move.l	d5,d1
.n1:	lsr	#1,d0
	bcc.s	.n2
	move.l	d5,d2
.n2:	lsr	#1,d0
	bcc.s	.n3
	move.l	d5,d3
.n3:	lsr	#1,d0
	bcc.s	.n4
	move.l	d5,d4
.n4:	or.l	#$3000000c,d1		; Add border to bp1
	move.w	#25,d0			; 18 for NTSC
.fill:	move.l	d1,(a0)
	move.l	d2,40(a0)
	move.l	d3,80(a0)
	move.l	d4,120(a0)
	add.w	#160,a0
	dbra	d0,.fill
	movem.l	(a7)+,d2-5
	rts

blitter_wait:
	btst	#14,DMACONR(a5)	; Amiga 1000 compat dummy read
.lp:	btst	#14,DMACONR(a5)
	bne.s	.lp
	rts

;;; ----------------------------------------------------------------------
;;;  Public memory data
;;; ----------------------------------------------------------------------

	data
font:	incbin	"res/sinestra.bin"
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
	;; Initial palette
	dc.w	COLOR0,$005a
	dc.w	COLOR1,$0fff
	dc.w	COLOR2,$0000
	dc.w	COLOR3,$000a
	dc.w	COLOR4,$00a0
	dc.w	COLOR5,$00aa
	dc.w	COLOR6,$0a00
	dc.w	COLOR7,$0a0a
	dc.w	COLOR8,$0aa0
	dc.w	COLOR9,$0aaa
	dc.w	COLOR15,$0fff
	;; Display boundaries
	dc.w	DIWSTRT,$2c81
	dc.w	DIWSTOP,$2cc1
	;; DMA boundaries
	dc.w	DDFSTRT,$3c
	dc.w	DDFSTOP,$d4
	;; Fixed configuration
	dc.w	BPL1MOD,0	; No modulo for BP1, 120 for BP2 in advance
	dc.w	BPL2MOD,120
	dc.w	FMODE,0		; Slow DMA on post-OCS
	dc.w	BPLCON0,$9200	; 1 bitplane, hi-res, color on composite
	dc.w	BPLCON1,0	; Nothing else special
	dc.w	BPLCON2,0

	;; Wait for end of header
	dc.w	$340f,$fffe
	;; Switch to 40-column mode
	dc.w	BPLCON0,$4200
	dc.w	DDFSTRT,$38
	dc.w	DDFSTOP,$d0
	dc.w	BPL1MOD,120	; Interleaved 4BPP mode
imgC:	dc.w	BPL1PTH,0
	dc.w	BPL1PTL,0
	dc.w	COLOR1,$0ccc
	;; Deliver the next sets of colors
	dc.w	$520f,$fffe
	dc.w	COLOR2,$0005
	dc.w	COLOR3,$000f
	dc.w	COLOR4,$00a5
	dc.w	COLOR5,$00af
	dc.w	COLOR6,$0a05
	dc.w	COLOR7,$0a0f
	dc.w	COLOR8,$0aa5
	dc.w	COLOR9,$0aaf
	dc.w	COLOR15,$0dde
	dc.w	$700f,$fffe
	dc.w	COLOR2,$0050
	dc.w	COLOR3,$005a
	dc.w	COLOR4,$00f0
	dc.w	COLOR5,$00fa
	dc.w	COLOR6,$0a50
	dc.w	COLOR7,$0a5a
	dc.w	COLOR8,$0af0
	dc.w	COLOR9,$0afa
	dc.w	COLOR15,$0bbd
	dc.w	$8e0f,$fffe
	dc.w	COLOR2,$0055
	dc.w	COLOR3,$005f
	dc.w	COLOR4,$00f5
	dc.w	COLOR5,$00ff
	dc.w	COLOR6,$0a55
	dc.w	COLOR7,$0a5f
	dc.w	COLOR8,$0af5
	dc.w	COLOR9,$0aff
	dc.w	COLOR15,$099c
	dc.w	$ac0f,$fffe
	dc.w	COLOR2,$0500
	dc.w	COLOR3,$050a
	dc.w	COLOR4,$05a0
	dc.w	COLOR5,$05aa
	dc.w	COLOR6,$0f00
	dc.w	COLOR7,$0f0a
	dc.w	COLOR8,$0fa0
	dc.w	COLOR9,$0faa
	dc.w	COLOR15,$077b
	dc.w	$ca0f,$fffe
	dc.w	COLOR2,$0505
	dc.w	COLOR3,$050f
	dc.w	COLOR4,$05a5
	dc.w	COLOR5,$05af
	dc.w	COLOR6,$0f05
	dc.w	COLOR7,$0f0f
	dc.w	COLOR8,$0fa5
	dc.w	COLOR9,$0faf
	dc.w	COLOR15,$055a
	dc.w	$e80f,$fffe
	dc.w	COLOR2,$0550
	dc.w	COLOR3,$055a
	dc.w	COLOR4,$05f0
	dc.w	COLOR5,$05fa
	dc.w	COLOR6,$0f50
	dc.w	COLOR7,$0f5a
	dc.w	COLOR8,$0ff0
	dc.w	COLOR9,$0ffa
	dc.w	COLOR15,$0339
	;; Wait for 8-bit turnover as part of final box
	dc.w	$ffe1,$fffe
	dc.w	$06e1,$fffe
	dc.w	COLOR2,$0555
	dc.w	COLOR3,$055f
	dc.w	COLOR4,$05f5
	dc.w	COLOR5,$05ff
	dc.w	COLOR6,$0f55
	dc.w	COLOR7,$0f5f
	dc.w	COLOR8,$0ff5
	dc.w	COLOR9,$0fff
	dc.w	COLOR15,$011e
	;; Wait for end of main body
	dc.w	$240f,$fffe
	;; Switch back to 80-column mode
	dc.w	BPLCON0,$9200
	dc.w	DDFSTRT,$3c
	dc.w	DDFSTOP,$d4
	dc.w	BPL1MOD,0
footC:	dc.w	BPL1PTH,0
	dc.w	BPL1PTL,0
	dc.w	COLOR1,$0fff
	dc.w	COLOR0,$005a
	;; Wait for end of frame
	dc.w	$ffff,$fffe

	bss_c
bmp:	ds.b	80*16+40*240*4
pending:
	ds.b	1
ready:	ds.b	1
