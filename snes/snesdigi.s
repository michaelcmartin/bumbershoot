	.p816
	.a16
	.i16

	.import	RESET
	.export	main

	.segment "TITLE"
	.byte "DIGITAL AUDIO TEST   "

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
joy0:	.res	1

	.segment "CODE"

.proc	main
	sep	#$30
	.a8
	.i8

	;; Main program begins here
	phk
	plb
	stz	$2121			; Load palette
	stz	$2122
	stz	$2122
	lda	#$e0
	sta	$2122
	lda	#$03
	sta	$2122

	lda	#$01
	sta	$2105			; Mode 1, 4BPP/4BPP/2BPP

	rep	#$10
	.i16
	ldx	#$0000
	ldy	#$00FF
	stx	$2116
	lda	#$08
:	sty	$2118
	dec	a
	bne	:-

	lda	#$01			; Enable BG 1
	sta	$212c

	lda	#$10			; And read it from $1000
	sta	$2107

	lda	#^spcdata
	ldx	#(spcdata & $ffff)
	ldy	#(spcdata_end - spcdata)
	jsr	load_sound

	stz	joy0			; Zero out our controller marker

	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI

	ldy	#$dead			; Cache abort code
	ldx	#$feed			; Check for completion code
wait:	lda	joy0
	beq	ok
	sty	$2140			; If start pressed, send abort code
ok:	cpx	$2140
	bne	wait

	lda	#$ed			; Ack completion code
	sta	$2140			; (8-bit to dodge bug)
	lda	#$fe
	sta	$2141

	;; Set up song playback
	lda	#^songdata
	ldx	#(songdata & $ffff)
	ldy	#(songdata_end - songdata)
	jsr	load_sound

	lda	#$0f			; Enable display
	sta	$2100

loop:	jmp	loop
.endproc

.proc	VBLANK
	rep	#$30
	pha
	sep	#$20
:	lda	$4212			; Wait for controller read to start
	lsr	a
	bcc	:-
:	lda	$4212			; Wait for controller read to end
	lsr	a
	bcs	:-
	lda	$4219			; Load controller state
	and	#$10			; Mask out START button
	sta	joy0			; And cache that where main can see it
	rep	#$30
	pla
	rti
.endproc

	.zeropage
spc_addr: .res 3

	.segment "CODE"

.proc	load_sound
	;; store source pointer
	stx	spc_addr
	sta	spc_addr+2
	;; Wait for boot
	ldx	#$bbaa
:	cpx	$2140
	bne	:-
	;; Set write address
	ldx	#$0200
	stx	$2142
	lda	#$cc
	sta	$2141
	sta	$2140
:	cmp	$2140
	bne	:-
	;; Copy data over
	tyx
	ldy	#$0000
copy:	lda	[spc_addr],y
	sta	$2141
	tya
	sta	$2140
:	cmp	$2140
	bne	:-
	iny
	dex
	bne	copy
	;; Run program
	tya
	inc	a
	ldx	#$0204
	stx	$2142
	stz	$2141
	sta	$2140
:	cmp	$2140
	bne	:-
	rts
.endproc

songdata:
	.incbin "spc_mus.bin",$200
songdata_end:

	.segment "BANK1"
spcdata:
	sampleSPC = (sample - spcdata) + $200
	;; Directory
	.word	sampleSPC, sampleSPC

	.incbin "spc_digi.bin",$204

	;; Sample data
sample:	.incbin	"res/bumbershoot.brr"
spcdata_end:
