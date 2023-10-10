	.p816
	.a16
	.i16

	.import	RESET, load_sound
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

songdata:
	.incbin "spc_mus.bin",$200

	;; DSP setup
	.byte	$6c,$20,$0c,$7f,$1c,$7f,$2c,$00,$3c,$00,$4c,$00,$5c,$ff,$2d,$00
	.byte	$3d,$00,$4d,$00,$5d,$02,$5c,$00

	;; Instrument/Envelope control
	.byte	$00,$7f,$01,$7f,$04,$00,$05,$9f,$06,$1a

	;; Play scale
	.byte	$02,$5f,$03,$08,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$65,$03,$09,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$8c,$03,$0a,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$2c,$03,$0b,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$8b,$03,$0c,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$14,$03,$0e,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$cd,$03,$0f,$5c,$00,$4c,$01,$9c,$5c,$01,$84
	.byte	$02,$be,$03,$10,$5c,$00,$4c,$01,$9c,$5c,$01,$84

	;; Pause, then loop back to start of scale
	.byte	$5c,$00,$f0,$80,$22,$00
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
