	.p816
	.a16
	.i16

	.import	RESET, init_pixmap, make_pixmap, load_pixmap
	.export	main

	.segment "TITLE"
	.byte "P-BITMAP TEST        "

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
pict:	.res	3
draw_state:
	.res	1

	;; Draw state 0: normal operation, all memory static
	;; Draw state 1: switch requested, WRAM changing
	;; Draw state 2: render requested, VRAM changing
	;; Draw state 3: render progressing, VRAM changing
	;; Draw state 4: waiting for input reset, all memory static

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

	sta	$4300			; VRAM word copy this time
	lda	#$18
	sta	$4301
	lda	#^ancillary
	ldx	#(ancillary & $ffff)
	stx	$4302
	sta	$4304
	ldx	#ancillary_end-ancillary
	stx	$4305
	stz	$2116			; Copy into VRAM $0000
	stz	$2117
	lda	#$01
	sta	$420b

	jsr	init_pixmap

	;; Load semigraphics and font
	ldx	#$0000			; zero out the scroll registers
	stx	xscr
	stx	yscr
	ldx	#(pbmp_0 & $ffff)	; Point to first image
	stx	pict
	lda	#^pbmp_0
	sta	pict+2
	stz	draw_state

	lda	pict+2
	ldx	pict
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

@loop:	lda	draw_state		; Has a switch been requested?
	cmp	#$01
	bne	@loop

	rep	#$20
	.a16
	lda	pict
	eor	#(pbmp_0 ^ pbmp_1)
	sta	pict
	tax
	sep	#$20
	.a8
	lda	#pict+2
	jsr	make_pixmap

	inc	draw_state
	bra	@loop

VBLANK:	jml	:+
:	rep	#$30
	.i16
	pha
	phx
	phy
	sep	#$20
	.a8
	lda	draw_state
	dec	a
	dec	a			; Blit phase 1?
	beq	blit1
	dec	a
	beq	blit2			; Blit phase 2?
:	lda	$4212			; Has the controller started reading?
	lsr	a
	bcc	:-
:	lda	$4212			; Is the controller ready?
	lsr	a
	bcs	:-
	jsr	read_joy
	bcc	nopress
	;; START is down. If we're in state 0, go to state 1.
	lda	draw_state
	bne	done
	inc	draw_state
	bra	done
nopress:
	;; START is up. If we're in state 4, return to state 0.
	lda	draw_state
	cmp	#$04
	bne	done
	stz	draw_state
	bra	done
blit1:	ldx	#$6000
	ldy	#$8000
	jsr	load_pixmap
	bra	scroll
blit2:	ldx	#$7000
	ldy	#$9000
	jsr	load_pixmap
scroll:	jsr	read_joy		; No delays needed for joyread here
	inc	draw_state		; Advance to next state
done:	rep	#$30
	ply
	plx
	pla
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

	.segment "BANK1"

ancillary:
	.incbin "res/ancillary.bin"
ancillary_end:

	.segment "BANK2"

pbmp_0:	.incbin "res/pbmp_0.bin"
pbmp_1:	.incbin "res/pbmp_1.bin"
