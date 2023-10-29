	.p816
	.a16
	.i16

	.import	RESET, lz4dec, rnd, seed_rnd, mix_rnd
	.import	init_pixmap, make_pixmap, load_pixmap
	.import	init_cca, step_cca
	.import	load_sound
	.export	main

	.segment "TITLE"
	.byte "CYCLIC CELLULAR AUTO "

	;; https://snes.nesdev.org/wiki/ROM_header
	.segment "ROMINFO"
	.byte	$30			; FastROM, LoROM
	.byte	0
	.byte	$06			; 64KB
	.byte	0,0,0,0
	.word	$aaaa, $5555

	.segment "VECTORS"
	.addr	0,0,0,0,0,VBLANK,0,0
	.addr	0,0,0,0,0,0,RESET,0

	.zeropage
frame_count:
	.res	2
xscr:	.res	2
yscr:	.res	2
draw_state:
	.res	1
last_ctl:
	.res	1
curr_ctl:
	.res	1
new_ctl:
	.res	1
start_pressed:
	.res	1

	.segment "RAM0"
hdma_table:
hdma_stable_0_len:
	.res	1
hdma_stable_0:
	.res	2
hdma_stable_1_len:
	.res	1
hdma_stable_1:
	.res	2
hdma_spill_0_len:
	.res	1
hdma_spill_0:
	.res	254
hdma_spill_1_len:
	.res	1
hdma_spill_1:
	.res	254
hdma_term:
	.res	1

        ;; draw_state enum
GLOBAL_IDLE = 0
TITLE_BLEED = 1
CCA_IDLE    = 2
CCA_BLIT2   = 3
CCA_BLIT1   = 4

.macro	blit
	.local	lp
	lda	#CCA_IDLE
lp:	cmp	draw_state
	bne	lp
	lda	#CCA_BLIT1
	sta	draw_state
.endmacro

	.segment "CODE"

.proc	main
	sep	#$20
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

	rep	#$20
	.a16
	lda	#$000a			; Initialize PRNG seed
	ldx	#$0001
	jsr	seed_rnd
	sep	#$20
	.a8

	;; Set up Logo display
	stz	draw_state		; GLOBAL_IDLE vblank
	stz	last_ctl		; Clear controller logic
	stz	start_pressed
	stz	frame_count
	stz	frame_count+1
	lda	#$03			; Graphics mode 3
	sta	$2105
	lda	#$60			; BG1 at $6000, 32x32
	sta	$2107

	ldx	#$6000			; Clear screen to tile $0280
	stx	$2116			; (First "blank" 8bpp tile)
	ldy	#$0280
	ldx	#$0400
:	sty	$2118
	dex
	bne	:-

	ldx	#$6046			; Create main bitmap image
	stx	$2116
	ldx	#$00a0
bmaplp:	lda	#$14
:	stx	$2118
	inx
	cpx	#$280
	beq	showlogo
	dec	a
	bne	:-
	lda	#$0c
:	sty	$2118			; Y is still blank tile $0280
	dec	a
	bne	:-
	bra	bmaplp

showlogo:
	lda	#$01			; Enable BG1
	sta	$212c
	lda	#$0f			; Enable display
	sta	$2100
	lda	#^digidata		; load and run sound playback program
	ldx	#(digidata & $ffff)
	ldy	#(digidata_end - digidata)
	jsr	load_sound

	lda	$4210			; Clear VBLANK flag
	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI

	ldx	#$feed
:	cpx	$2140			; Wait for completion signal
	beq	:+
	lda	start_pressed
	beq	:-
	lda	#$ad
	sta	$2140
	lda	#$de
	sta	$2141
	bra	:-

	;; Fade out unless start was/is pressed
:	ldx	#$38
fade:	lda	start_pressed
	beq	:+
	stz	start_pressed
	bra	do_title
:	txa
	lsr
	lsr
	sta	$2100
	lda	frame_count
:	cmp	frame_count
	beq	:-
	dex
	bne	fade

	;; Set up title display
do_title:
	lda	#$8f			; Disable display
	sta	$2100
	stz	$4200			; Disable VBLANK interrupts

	lda	#$01			; Mode 1, 4BPP/4BPP/2BPP
	sta	$2105
	lda	#$60			; BG1 Tilemap at $6000, 32x32
	sta	$2107
	lda	#$01			; Enable BG1
	sta	$212c

	ldx	#$6000			; Clear screen to tile $0000
	stx	$2116			; (First "blank" 4bpp tile)
	ldy	#$0000
	ldx	#$0400
:	sty	$2118
	dex
	bne	:-

	ldx	#title_msg & $ffff
	jsr	draw_text

	lda	#$01			; Set up initial HDMA table
	sta	f:hdma_stable_0_len
	sta	f:hdma_stable_1_len
	dec	a
	sta	f:hdma_term
	lda	#$ff
	sta	f:hdma_spill_0_len
	sta	f:hdma_spill_1_len
	rep	#$20
	.a16
	lda	#$0000
	sta	f:hdma_stable_0
	sta	f:hdma_stable_1
	tax
:	dec	a
	sta	f:hdma_spill_0,x
	inx
	inx
	cpx	#$00fe
	bne	:-
	ldx	#$0000
:	dec	a
	sta	f:hdma_spill_1,x
	inx
	inx
	cpx	#$00fe
	bne	:-
	sep	#$20
	.a8
	lda	#TITLE_BLEED		; TITLE_BLEED will re-enable the
	sta	draw_state		; display for us

	lda	$4210			; Clear VBLANK flag
	lda	#$81			; Enable joypad auto-read
	sta	$4200			; and VBLANK NMI

:	lda	start_pressed		; Wait for user to press START
	beq	:-
	stz	start_pressed

	;; Set up CCA display
	lda	#$8f			; Disable display
	sta	$2100
	stz	$4200			; Disable VBLANK interrupts

	;; Decompress and run music program before we reuse the
	;; decompression space as CCA data
	lda	#$ed			; Acknowledge digital sound
	sta	$2140			; and reset SPC-700
	lda	#$fe
	sta	$2141
	lda	#^musdat
	ldx	#(musdat & $ffff)
	ldy	#$0000
	jsr	lz4dec
	txy				; Put decompressed length in .Y
	lda	#$7f
	ldx	#$0000
	jsr	load_sound

	jsr	init_pixmap

	ldx	#$0000			; zero out the scroll registers
	stx	xscr
	stx	yscr
	lda	#CCA_IDLE		; and initialize draw state
	sta	draw_state

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

	lda	#$01			; Mode 1, 4BPP/4BPP/2BPP
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

	;; Main update loop
loop:	lda	start_pressed
	bne	reset_cca
	ldx	#$0000
	ldy	#$4000
	jsr	step_cca

	lda	#$7f
	ldx	#$4000
	jsr	make_pixmap
	blit

	lda	start_pressed
	bne	reset_cca
	ldx	#$4000
	ldy	#$0000
	jsr	step_cca

	lda	#$7f
	ldx	#$0000
	jsr	make_pixmap
	blit
	bra	loop

reset_cca:
	jsr	init_cca
	lda	#$7f
	ldx	#$0000
	jsr	make_pixmap
	blit
	stz	start_pressed
	bra	loop
.endproc

.proc	VBLANK
	jml	:+
:	rep	#$30
	phb
	pha
	phx
	phy
	inc	frame_count
	sep	#$30			; Need .i8 here so that TAX
	.a8				; doesn't pollute our jump address
	.i8				; with the leftover accumulator high
	lda	#$80			; byte, even in .a8 mode!
	pha
	plb
	stz	$420c			; Disable HDMA
	lda	draw_state
	asl	a
	tax
	rep	#$10
	.i16
	jmp	(vtable,x)
vtable:	.addr	do_global_idle, do_title_bleed, do_cca_idle, do_cca_blit2, do_cca_blit1

do_cca_blit1:
	ldx	#$6000
	ldy	#$8000
	bra	doblit

do_cca_blit2:
	ldx	#$7000
	ldy	#$9000
	;; Fall through to doblit

doblit:	jsr	load_pixmap
	jsr	read_joy
	dec	draw_state
	bra	done

do_cca_idle:
	jsr	wait_for_joy
	jsr	read_joy
	bra	done

do_title_bleed:
	lda	#$0f			; Force-enable display
	sta	$2100
	jsr	wait_for_joy
	lda	f:hdma_stable_0_len
	cmp	#$7f
	beq	:+
	inc	a
	sta	f:hdma_stable_0_len
	bra	:++
:	lda	f:hdma_stable_1_len
	cmp	#$7f
	beq	:+
	inc	a
	sta	f:hdma_stable_1_len
:	lda	#^hdma_table
	ldx	#(hdma_table & $ffff)
	stx	$4312
	sta	$4314
	lda	#$02			; Pattern 2
	sta	$4310
	lda	#$0e			; Write BG1 Vertical scroll
	sta	$4311
	lda	#$02
	sta	$420c			; Enable HDMA channel 0
	bra	done

do_global_idle:
	jsr	wait_for_joy
	;; Fall through to end

done:	lda	curr_ctl
	sta	last_ctl
	lda	$4219
	sta	curr_ctl
	eor	last_ctl
	and	curr_ctl
	sta	new_ctl
	and	#$10			; Was START pressed?
	beq	ret

	lda	#$01
	sta	start_pressed
	rep	#$30
	lda	frame_count
	jsr	mix_rnd

ret:	rep	#$30
	ply
	plx
	pla
	plb
	rti
.endproc

	;; Wait until the controller has started, then finished, reading.
.proc	wait_for_joy
:	lda	$4212			; Has the controller started reading?
	lsr	a
	bcc	:-
:	lda	$4212			; Is the controller ready?
	lsr	a
	bcs	:-
	rts
.endproc

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

.proc	draw_text
	rep	#$20
	.a16
	lda	a:$00,x
	beq	done
	sta	$2116
	sep	#$20
	.a8
	inx
line:	inx
	lda	a:$00,x
	beq	next
	sec
	sbc	#$20
	sta	$2118
	lda	#$01
	sta	$2119
	bra	line
next:	inx
	bra	draw_text
done:	sep	#$20
	rts
.endproc

	.rodata

title_msg:
	.word	$6066
	.byte	"BUMBERSHOOT SOFTWARE",0
	.word	$608e
	.byte	"2023",0
	.word	$60cc
	.byte	"PRESENTS",0
	.word	$61ab
	.byte	"THE CYCLIC",0
	.word	$61c7
	.byte	"CELLULAR AUTOMATON",0
	.word	$6306
	.byte	"PRESS START TO BEGIN",0
	.word	$0000
colors:	.incbin "res/bumberpal.bin"
colors_end:

gfxdat:	.incbin "res/lz4gfx.bin"
musdat: .incbin "res/lz4mus.bin"

	.segment "BANK1"
digidata:
	.incbin "spc_digi.bin", $200
digidata_end:
