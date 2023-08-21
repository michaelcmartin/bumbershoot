	.p816
	.a16
	.i16

	.import	RESET, seed_rnd, rnd
	.export	main

	.segment "TITLE"
	.byte "P-BITMAP TEST        "

	;; https://snes.nesdev.org/wiki/ROM_header
	.segment "ROMINFO"
	.byte	$20			; SlowROM, LoROM
	.byte	0
	.byte	$07			; 128KB
	.byte	0,0,0,0
	.word	$aaaa, $5555

	.segment "VECTORS"
	.word	0,0,0,0,0,VBLANK,0,0
	.word	0,0,0,0,0,0,RESET,0

	.zeropage
xscr:	.res	2
yscr:	.res	2
pict:	.res	2

	.segment "CODE"

main:	sep	#$30
	.a8
	.i8

	;; Main program begins here
	phk
	plb
	stz	$2121			; Load palette
	ldx	#$00
:	lda	colors,x
	sta	$2122
	inx
	cpx	#colors_end-colors
	bne	:-

	lda	#$01
	sta	$2105			; Mode 3, 8BPP/4BPP
	rep	#$30
	.a16
	.i16
	stz	$2116
	ldx	#$00
:	lda	f:ancillary,x
	sta	$2118
	inx
	inx
	cpx	#ancillary_end-ancillary
	bne	:-

	ldx	#$7fff
:	lda	f:pbmp_0,x
	sta	$7f0000,x
	dex
	bpl	:-

	stz	xscr			; zero out the scroll registers
	stz	yscr			; (16-bit writes)
	lda	#(pbmp_0 & $ffff)	; Point to first image
	sta	pict

	sep	#$20
	.a8
	lda	#$63			; BG1 Tilemap at $6000, 64x64
	sta	$2107
	lda	#$73			; BG2 Tilemap at $7000, 64x64
	sta	$2108

	;; Clear 8bpp screen
	ldx	#$6000			; Clear entire screen
	stx	$2116
	ldy	#$0000			; First blank 4bpp tile
	ldx	#$1000			; 4096 tiles
:	sty	$2118
	dex
	bne	:-
	ldy	#$8000			; Flip every tile in BG2
	ldx	#$1000
:	sty	$2118
	dex
	bne	:-

	lda	#^pbmp_0
	ldx	pict
	jsr	make_pixmap
	jsr	load_pixmap

@disp:	lda	#$03
	sta	$212c			; Enable BG1 and BG2

	lda	#$0f			; Enable display
	sta	$2100

	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI
@loop:	jmp	@loop

VBLANK:	rep	#$30
	.i16
	pha
	phx
	phy
	sep	#$20
	.a8
:	lda	$4212			; Has the controller started reading?
	lsr	a
	bcc	:-
:	lda	$4212			; Is the controller ready?
	lsr	a
	bcs	:-
	lda	$4219			; Read the directional part
	rep	#$20			; We'll need 16-bit memory here
	.a16
	lsr	a			; Right?
	bcc	:+
	inc	xscr
:	lsr	a
	bcc	:+			; Left?
	dec	xscr
:	lsr	a			; Down?
	bcc	:+
	inc	yscr
:	lsr	a			; Up?
	bcc	:+
	dec	yscr
:	sep	#$10
	.i8
	ldx	xscr
	ldy	xscr+1
	stx	$210d
	sty	$210d
	stx	$210f
	sty	$210f
	ldx	yscr
	ldy	yscr+1
	stx	$210e
	sty	$210e
	stx	$2110
	sty	$2110
	rep	#$30
	.i16
	lsr	a			; Start?
	bcc	done
	lda	pict
	eor	#(pbmp_0 ^ pbmp_1)
	sta	pict
	tax
	sep	#$20
	.a8
	lda	#$01			; Disable NMI
	sta	$4200
	lda	#$8f			; Force blank
	sta	$2100
	lda	#^pbmp_0
	jsr	make_pixmap
	jsr	load_pixmap
	lda	#$0f			; Re-enable display
	sta	$2100
	lda	#$81
	sta	$4200			; Re-enable VBLANK
done:	rep	#$30
	ply
	plx
	pla
	rti

	;; Convenience macro for make_pixmap
.macro	combine src_offset, dest_offset
	lda	a:src_offset,y
	asl
	asl
	asl
	asl
	ora	a:src_offset+1,y
	sta	$7f8000 + dest_offset,x
.endmacro

	.zeropage
pm_row:	.res	1
pm_col:	.res	1

	.segment "CODE"

	.a8
	.i16
.proc	make_pixmap
	phb				; Save data bank
	pha				; And set it to source bank
	plb
	txy				; Rest of src addr in Y
	ldx	#$0000
	lda	#$20			; 32 rows and columns per table
	sta	pm_row
row:	lda	#$20
	sta	pm_col
col:	combine $0000, $0000
	combine $0040, $0400
	combine $2000, $0800
	combine $2040, $0c00
	combine $0080, $1000
	combine $00c0, $1400
	combine $2080, $1800
	combine $20c0, $1c00
	iny
	iny
	inx
	dec	pm_col
	bne	col
	dec	pm_row
	beq	done
	rep	#$21			; Jump X ahead 192
	.a16				; For next pair of rows
	tya
	adc	#$00c0
	tay
	sep	#$20
	.a8
	jmp	row
done:	plb				; Restore data bank
	rts
.endproc

.proc	load_pixmap
	ldx	#$6000			; Create main bitmap
	stx	$2116
	lda	#$00			; Only write low byte
	sta	$2115
	ldx	#$0000			; Write 8 nametables
:	lda	$7f8000,x
	sta	$2118
	inx
	cpx	#$2000
	bne	:-
	rts
.endproc


colors:	.incbin "res/bumberpal.bin"
colors_end:

	.segment "BANK1"

ancillary:
	.incbin "res/ancillary.bin"
ancillary_end:

	.segment "BANK2"

pbmp_0:	.incbin "res/pbmp_0.bin"
pbmp_1:	.incbin "res/pbmp_1.bin"
