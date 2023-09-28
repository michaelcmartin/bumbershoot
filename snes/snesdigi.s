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

	jsr	load_sound

	stz	$00			; Zero out our controller marker

	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI

	ldy	#$dead			; Cache abort code
	ldx	#$feed			; Check for completion code
wait:	lda	$00
	beq	ok
	sty	$2140			; If start pressed, send abort code
ok:	cpx	$2140
	bne	wait

	lda	#$ed			; Ack completion code
	sta	$2140			; (8-bit to dodge bug)
	lda	#$fe
	sta	$2141

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
	sta	$00			; And cache that where main can see it
	rep	#$30
	pla
	rti
.endproc

.proc	load_sound
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
	ldx	#$0000
copy:	lda	f:spcdata,x
	sta	$2141
	txa
	sta	$2140
:	cmp	$2140
	bne	:-
	inx
	cpx	#spcdata_end-spcdata
	bne	copy
	;; Run program
	txa
	inc	a
	ldx	#$0204
	stx	$2142
	stz	$2141
	sta	$2140
:	cmp	$2140
	bne	:-
	rts
.endproc

	.segment "BANK1"
spcdata:
	sampleSPC = (sample - spcdata) + $200
	;; Directory
	.word	sampleSPC, sampleSPC

	;; Config/playback code
	.byte	$cd,$00,$f5,$48,$02,$fd,$f5,$47,$02,$30,$06,$3d,$3d,$da,$f2,$2f
	.byte	$f1,$e8,$fc,$c4,$f2,$e4,$f3,$28,$01,$d0,$0c,$e4,$f4,$68,$ad,$d0
	.byte	$f0,$e4,$f5,$68,$de,$d0,$ea,$e8,$ed,$c4,$f4,$e8,$fe,$c4,$f5,$e8
	.byte	$5c,$8d,$01,$da,$f2,$e4,$f4,$68,$ed,$d0,$fa,$e4,$f5,$68,$fe,$d0
	.byte	$f4,$2f,$fe

	;; DSP configuration data
	.word	$206c,$004c,$ff5c,$025d
	.word	$7f00,$7f01,$0002,$0803,$0004,$0005,$e006,$7f07
	.word	$005c,$007c,$003d,$004d,$7f0c,$7f1c,$002c,$003c,$014c
	.byte	$ff

        ;; Sample data
sample:	.incbin	"res/bumbershoot.brr"
spcdata_end:
