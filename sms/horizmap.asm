	define	SMS
	include	"sega8bios.asm"

mapcrsr	# 2
chrcrsr	# 1
scr_x	# 1

main	ld	de,$0800
	call	prep_vram_write
	ld	hl,font
	ld	bc,2
1	ld	a,(hl)
	out	(VDPDATA),a		; Display is off, we can be quick here
	xor	a
	out	(VDPDATA),a
	inc	hl
	out	(VDPDATA),a
	nop
	out	(VDPDATA),a
	djnz	1B
	ld	de,$0400
	call	prep_vram_write
	dec	c
	jr	nz,1B
	ld	a,$3f
	ld	de,$8001
	rst	write_vram

	;; Create map
	ld	de,$3800
	call	prep_vram_write
	ld	c,28
	ld	d,0
1	ld	b,32
2	ld	a,d
	add	32
	out	(VDPDATA),a
	sub	31
	and	63
	ld	d,a
	xor	a
	out	(VDPDATA),a
	djnz	2B
	ld	a,d
	sub	31
	and	63
	ld	d,a
	dec	c
	jr	nz,1B

	;; Initial scroll conditions
	ld	hl,$383e
	ld	(mapcrsr),hl
	ld	a,31
	ld	(chrcrsr),a
	ld	a,$8
	ld	(scr_x),a
	ld	hl,$0808
	rst	set_vdp_register

	ld	hl,irq
	ld	(irqvec),hl

	ei
	ld	hl,$1e0
	rst	set_vdp_register

1:	halt
	jr	1B

irq:	ld	a,(scr_x)
	dec	a
	ld	(scr_x),a
	ld	l,a
	ld	h,8
	rst	set_vdp_register
	ld	a,l
	and	7
	ret	nz
	ld	de,(mapcrsr)
	ld	a,e
	add	2
	and	63
	ld	e,a
	ld	hl,64
	ld	(mapcrsr),de
	ld	a,(chrcrsr)
	inc	a
	and	63
	ld	(chrcrsr),a
	ld	b,28
1	add	32
	rst	write_vram
	sub	31
	and	63
	ex	de,hl
	add	hl,de
	ex	de,hl
	djnz	1B
	ret
	ret

font:	incbin	"halogen.bin"
