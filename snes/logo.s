	.p816
	.a16
	.i16

	.import	RESET
	.export	main

	.segment "TITLE"
	.byte "BUMBERSHOOT LOGO     "

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

	lda	#$03
	sta	$2105			; Mode 3, 8BPP/4BPP
	rep	#$30
	.a16
	.i16
	lda	#$0020
	sta	$2116
	ldx	#$00
@tlp:	lda	f:tiles,x
	sta	$2118
	inx
	inx
	cpx	#tile_end-tiles
	bne	@tlp
	sep	#$20
	.a8
	lda	#$40			; BG1 Tilemap at $4000, 32x32
	sta	$2107

	ldx	#$4046			; Create main bitmap
	stx	$2116
	ldy	#$00
	tyx
	inx
@bmap:	lda	#$14
:	stx	$2118
	inx
	cpx	#$1e1
	beq	@disp
	dec	a
	bne	:-
	lda	#$0c
:	sty	$2118
	dec	a
	bne	:-
	beq	@bmap

@disp:	lda	#$01
	sta	$212c			; Enable BG1

	lda	#$0f			; Enable display
	sta	$2100

	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI
@loop:	jmp	@loop

VBLANK:	rti

colors:	.incbin "res/bumberpal.bin"
colors_end:

	.segment "BANK1"

tiles:	.incbin "res/bumberlogo.bin"
tile_end:


