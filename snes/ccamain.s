	.p816
	.a16
	.i16

	.import	RESET, lz4dec, rnd, seed_rnd
	.import	init_pixmap, make_pixmap, load_pixmap
	.import	init_cca, step_cca
	.export	main

	.segment "TITLE"
	.byte "CYCLIC CELLULAR AUTO "

	;; https://snes.nesdev.org/wiki/ROM_header
	.segment "ROMINFO"
	.byte	$30			; FastROM, LoROM
	.byte	0
	.byte	$07			; 128KB
	.byte	0,0,0,0
	.word	$aaaa, $5555

	.segment "VECTORS"
	.word	0,0,0,0,0,VBLANK & $ffff,0,0
	.word	0,0,0,0,0,0,RESET & $ffff,0

	.zeropage
xscr:	.res	2
yscr:	.res	2

	.segment "CODE"

main:	sep	#$20
	rep	#$10
	.a8
	.i16

	phk
	plb

	lda	#$01			; Enable FastROM
	sta	$420d

	stz	$4300			; DMA0: linear forward copy A->B
	lda	#$22			; into CGRAM
	sta	$4301
	stz	$2121			; Load palette starting at 0
	lda	#^colors		; Set DMA source address
	ldx	#(colors & $ffff)
	stx	$4302
	sta	$4304
	ldx	#colors_end-colors	; Set DMA transfer size
	stx	$4305
	lda	#$01			; Send DMA
	sta	$420b

	lda	#^gfxdat		; Decompress into WRAM
	ldx	#(gfxdat & $ffff)
	ldy	#$0000
	jsr	lz4dec

	lda	#$01			; Blit result into VRAM
	sta	$4300
	lda	#$18
	sta	$4301
	stx	$4305			; "Final address" is length
	lda	#$7f
	ldx	#$0000
	stx	$4302
	sta	$4304
	stz	$2116			; Copy into VRAM $0000
	stz	$2117
	lda	#$01
	sta	$420b

	jsr	init_pixmap

	ldx	#$0000			; zero out the scroll registers
	stx	xscr
	stx	yscr

	rep	#$20
	.a16
	lda	#$000a
	ldx	#$0001
	jsr	seed_rnd
	sep	#$20
	.a8

	jsr	init_cca

	lda	#$7f
	ldx	#$0000
	jsr	make_pixmap
	ldx	#$6000
	ldy	#$8000
	jsr	load_pixmap
	ldx	#$7000
	ldy	#$9000
	jsr	load_pixmap

@disp:	lda	#$01			; Mode 1, 4BPP/4BPP/2BPP
	sta	$2105
	lda	#$63			; BG1 Tilemap at $6000, 64x64
	sta	$2107
	lda	#$73			; BG2 Tilemap at $7000, 64x64
	sta	$2108
	lda	#$03			; Enable BG1 and BG2
	sta	$212c
	lda	#$0f			; Enable display
	sta	$2100

	lda	$4210			; Clear VBLANK flag
	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI

@loop:	ldx	#$0000
	ldy	#$4000
	jsr	step_cca

	lda	#$7f
	ldx	#$0000
	jsr	make_pixmap
	lda	#$8f
	sta	$2100
	ldx	#$6000
	ldy	#$8000
	jsr	load_pixmap
	ldx	#$7000
	ldy	#$9000
	jsr	load_pixmap
	lda	#$0f
	sta	$2100

	ldx	#$4000
	ldy	#$0000
	jsr	step_cca

	lda	#$7f
	ldx	#$4000
	jsr	make_pixmap
	lda	#$8f
	sta	$2100
	ldx	#$6000
	ldy	#$8000
	jsr	load_pixmap
	ldx	#$7000
	ldy	#$9000
	jsr	load_pixmap
	lda	#$0f
	sta	$2100
	jmp	@loop

VBLANK:	jml	:+
:
	rti

	;; Read controller. Update x_scr and y_scr, START in carry
.proc	read_joy
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
:	sep	#$30			; Set scroll values
	.a8
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
	lsr	a			; Start?
	rep	#$10
	.i16
	rts
.endproc

colors:	.incbin "res/bumberpal.bin"
colors_end:

gfxdat:	.incbin "res/lz4gfx.bin"
