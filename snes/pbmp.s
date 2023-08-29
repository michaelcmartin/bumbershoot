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
pict:	.res	3
draw_state:
	.res	1

	.segment "CODE"

main:	sep	#$20
	rep	#$10
	.a8
	.i16

	phk
	plb
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

	ldx	#$6000			; Clear tilemap area
	stx	$2116
	lda	#$09			; Fixed ROM->VRAM copy
	sta	$4300
	lda	#^zero
	ldx	#(zero & $ffff)
	stx	$4302
	sta	$4304
	ldx	#$4000
	stx	$4305
	lda	#$01
	sta	$420b
	ldx	#$7000
	stx	$2116
	lda	#$08			; Only write the high bytes
	sta	$4300
	lda	#$19
	sta	$4301
	lda	#^vflip
	ldx	#(vflip & $ffff)
	stx	$4302
	sta	$4304
	ldx	#$1000
	stx	$4305
	lda	#$01
	sta	$420b

	rep	#$30			; Load semigraphics and font
	.a16
	.i16
	stz	xscr			; zero out the scroll registers
	stz	yscr			; (16-bit writes)
	lda	#(pbmp_0 & $ffff)	; Point to first image
	sta	pict
	sep	#$20
	.a8
	lda	#^pbmp_0
	sta	pict+2
	stz	draw_state

	lda	pict+2
	ldx	pict
	jsr	make_pixmap
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
	bcc	nopress
	lda	draw_state
	bne	done
	inc	draw_state
	rep	#$30
	.a16
	.i16
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
	lda	#pict+2
	jsr	make_pixmap
	jsr	load_pixmap
	lda	#$0f			; Re-enable display
	sta	$2100
	lda	#$81
	sta	$4200			; Re-enable VBLANK
	bra	done
nopress:				; Start OK again
	stz	draw_state
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
	ldx	#$6000			; Write to tilemaps
	stx	$2116
	lda	#$00			; Only write low byte
	sta	$2115
	stz	$4300			; Linear copy
	lda	#$18			; into low byte
	sta	$4301
	lda	#$7f			; From RAM image
	ldx	#$8000
	stx	$4302
	sta	$4304
	ldx	#$2000			; Write 8 nametables worth
	stx	$4305
	lda	#$01
	sta	$420b
	rts
.endproc

	;; Raw data for the VRAM DMA initialization
zero:	.byte	$00
vflip:	.byte	$80

colors:	.incbin "res/bumberpal.bin"
colors_end:

	.segment "BANK1"

ancillary:
	.incbin "res/ancillary.bin"
ancillary_end:

	.segment "BANK2"

pbmp_0:	.incbin "res/pbmp_0.bin"
pbmp_1:	.incbin "res/pbmp_1.bin"
