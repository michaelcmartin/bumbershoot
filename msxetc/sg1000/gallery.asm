;;;----------------------------------------------------------------------
;;;  Shooting Gallery Shell: SG-1000 edition
;;;  This code handles the initial startup and SG-1000-specific I/O.
;;;  See sg1000bios.asm for the VDP and I/O support routines and
;;;  the ../gallerycore.asm file for platform-independent logic.
;;;----------------------------------------------------------------------

	include	"sg1000bios.asm"

main:	ld	de,init_reg		; Init VDP registers
	ld	h,0
	ld	b,8
.reglp:	ld	a,(de)
	inc	de
	ld	l,a
	rst	set_vdp_register
	inc	h
	djnz	.reglp
	;; Draw static screen
	ld	a,$07			; Draw divider line
	ld	bc,$0020
	ld	de,$0020
	rst	fill_vram
	ld	a,$68			; Draw ground
	ld	bc,$0060
	ld	de,$02a0
	rst	fill_vram
	ld	a,$f0			; Initialize Color RAM
	ld	bc,$0020		; Most everything is white on black
	ld	de,$0380
	rst	fill_vram
	ld	a,$22			; Ground is green
	ld	de,$38d
	rst	write_vram
	ld	hl,initial_gfx
	ld	bc,$000b		; Score display
	ld	de,$0014
	rst	blit_vram
	;; Initialize graphics patterns
	ld	bc,$0088		; Tile graphics
	ld	de,$0808
	rst	blit_vram
	ld	bc,$0018		; Sprite graphics
	ld	de,$0b00
	rst	blit_vram
	ld	bc,$0030		; Load sprite attrs to CPU RAM
	ld	de,sprattrs
	ldir
	ld	bc,$0030		; Then blit them to VRAM
	ld	de,$0300
	ld	hl,sprattrs
	rst	blit_vram
	ld	a,$d0			; Write sprite terminator
	out	(VDPDATA),a
	;;	Set up interrupt handler
	ld	hl,.irq
	ld	(irqvec),hl
	ei
	ld	hl,$01e1
	rst	set_vdp_register

.ever:	halt
	jr	.ever

.irq:	ld	a,(vdp_status)
	and	$20
	ld	(collision),a
	jp	irq


blit_sprites:
	ld	hl,sprattrs		; Blit updated sprites to VRAM
	ld	de,$0300
	ld	bc,$0030
	rst	blit_vram
	ret

blit_score:
	ld	hl,scorebuf
	ld	de,$001b
	ld	bc,$0004
	rst	blit_vram
	ret

read_joystick:
	ld	a,(joy1)
	ld	hl,0
	rra
	jr	nc,1f
	dec	l
	dec	l
1	rra
	jr	nc,1f
	inc	l
	inc	l
1	rra
	jr	nc,1f
	dec	h
	dec	h
1	rra
	jr	nc,1f
	inc	h
	inc	h
1	and	3
	ld	(fire),a
	ret

init_reg:
	db	$00,$80,$00,$0e,$01,$06,$01,$f1

	include	"../gallerycore.asm"

	ds	$400-$,$ff
