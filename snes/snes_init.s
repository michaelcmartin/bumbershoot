	.p816
	.export RESET
	.import main
	.segment "CODE"
RESET:	clc				; Native mode
	xce
	rep	#$ff			; Clear flags
	sei				; Disable interrupts
	.a16
	.i16
	lda	#$03ff			; Stack is bottom 1K
	tcs
	inc	a			; Direct page at $0400
	tcd
	sep	#$20			; 8-bit memory for reg init
	.a8
	phk				; Set data bank to prog bank
	plb

	;; Setup CPU registers
	stz	$4200			; Disable NMI
	stz	$420c			; Disable HDMA
	lda	#$00			; 0=SlowROM, 1=FastROM
	sta	$420d
	lda	#$ff
	sta	$4201

	;; Clear regs
	ldx	#$0000
	txy
@regcl:	lda	@regs,x
	beq	@memcl
	inx
	sta	$00
@bytlp:	lda	@regs,x
	sta	$2100,y
	inx
	iny
	dec	$00
	bne	@bytlp
	lda	@regs,x
	beq	@memcl
	inx
	sta	$00
@dbtlp:	lda	@regs,x
	sta	$2100,y
	lda	@regs+1,x
	sta	$2100,y
	inx
	inx
	iny
	dec	$00
	bne	@dbtlp
	bra	@regcl

	;; Clear all non-scratchpad RAM
@memcl:	lda	#$00			; Clear all non-scratchpad RAM
	sta	$7e2000
	sta	$7f0000
	lda	#$df
	xba
	lda	#$fe
	ldx	#$2000
	ldy	#$2001
	phb
	mvn	#$7e,#$7e
	dec	a
	inx
	iny
	mvn	#$7f,#$7f
	plb

	;; Clear VRAM
	lda	#$80
	sta	$2115
	rep	#$20
	.a16
	ldx	#$8000
	stz	$2116
:	stz	$2118
	dex
	bne	:-
	sep	#$20
	.a8

	;; Clear CGRAM
	stz	$2121
	ldx	#$0200
@cglp:	stz	$2122
	dex
	bne	@cglp

	;; Init OAM
	stz	$2102
	stz	$2103
	ldx	#$80
	lda	#$f0
@oamlp:	sta	$2104
	sta	$2104
	stz	$2104
	stz	$2104
	dex
	bne	@oamlp
	ldx	#$0020
@oam2:	stz	$2104
	dex
	bne	@oam2

	jml	main			; To main program
	;; Alternating byte/word blits starting at $2100
@regs:	.byte	$0d
	.byte	$8f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$08
	.word	$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	.byte	$06
	.byte	$80,$00,$00,$00,$00,$00
	.byte	$06
	.word	$0100,$0000,$0000,$0100,$0000,$0000
	.byte	$13
	.byte	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte	$00,$00,$00,$00,$00,$30,$00,$e0,$00
	.byte	$00
