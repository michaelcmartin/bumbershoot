	include	"coleco_bios.asm"

	org	$8000

	map	$702b
controllers     # 12

	dw	$55AA,0,0,0
	dw	controllers
	dw	main
	ds	$8021-$
	jp	vblank
	db	"SHOOTING GALLERY/BUMBERSHOOT SOFTWARE'S/2025"

main:	call	TURN_OFF_SOUND
	call	MODE_1
	;; Draw static screen
	xor	a			; Clear VRAM
	ld	de,$4000
	ld	h,a
	ld	l,a
	call	FILL_VRAM
	ld	a,$07			; Draw divider line
	ld	hl,$1820
	ld	de,$0020
	call	FILL_VRAM
	ld	a,$68			; Draw ground
	ld	de,$0060
	ld	hl,$1aa0
	call	FILL_VRAM
	ld	a,$f0			; Initialize Color RAM
	ld	de,$0020		; Most everything is white on black
	ld	hl,$2000
	call	FILL_VRAM
	ld	a,$22			; Ground is green
	ld	hl,$200d
	ld	de,1
	call	FILL_VRAM
	ld	hl,gfx_score
	ld	bc,$000b
	ld	de,$1814
	call	WRITE_VRAM
	;; Initialize graphics patterns
	ld	hl,gfx_pat
	ld	bc,$0088
	ld	de,$0008
	call	WRITE_VRAM
	ld	hl,gfx_sprpat
	ld	bc,$0018
	ld	de,$3b00
	call	WRITE_VRAM
	ld	hl,gfx_sprattr
	ld	bc,$0030
	ld	de,sprattrs
	ldir
	ld	bc,$0031		; Then blit them to VRAM
	ld	de,$1b00
	ld	hl,gfx_sprattr
	call	WRITE_VRAM

	ld	bc,$01e1
	call	WRITE_REGISTER

.ever:	halt
	jr	.ever

vblank:	ex	af,af'
	exx
	push	ix
	push	iy
	call	READ_REGISTER
	ld	(VDP_STATUS_BYTE),a
	and	$20
	ld	(collision),a
	ld	a,$8b
	ld	(controllers),a
	call	POLLER
	call	irq
	pop	iy
	pop	ix
	exx
	ex	af,af'
	retn

blit_sprites:
	ld	hl,sprattrs		; Blit updated sprites to VRAM
	ld	de,$1b00
	ld	bc,$0030
	jp	WRITE_VRAM

blit_score:
	ld	hl,scorebuf
	ld	de,$181b
	ld	bc,$0004
	jp	WRITE_VRAM

read_joystick:
	push	bc
	ld	a,(controllers+2)
	ld	b,a
	ld	a,(controllers+5)
	or	b
	ld	(fire),a
	ld	a,(controllers+3)
	ld	hl,0
	rra
	jr	nc,1f
	dec	l
	dec	l
1	rra
	jr	nc,1f
	inc	h
	inc	h
1	rra
	jr	nc,1f
	inc	l
	inc	l
1	rra
	jr	nc,1f
	dec	h
	dec	h
1	pop	bc
	ret

	include	"../common/gallerycore.asm"

	ds	$a000-$,$ff
