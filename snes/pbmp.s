	.p816
	.a8
	.i16

	.export	init_pixmap, make_pixmap, load_pixmap

.proc	init_pixmap
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
	rts
.endproc

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

	;; .X = VRAM destination
	;; .Y = WRAM source (bank 7F)
.proc	load_pixmap
	stx	$2116			; Save destination
	lda	#$00			; Only write low byte
	sta	$2115
	stz	$4300			; Linear copy
	lda	#$18			; into low byte
	sta	$4301
	lda	#$7f			; From RAM image
	sty	$4302
	sta	$4304
	ldx	#$1000			; Write 4 nametables worth
	stx	$4305
	lda	#$01
	sta	$420b
	rts
.endproc

	;; Raw data for the VRAM DMA initialization
zero:	.byte	$00
vflip:	.byte	$80
