	define	SMS
	define	RASTERINT
	include	"sega8bios.asm"

scrbuf	# 4
pscroll # 2

main	ld	a,$3f
	ld	de,$8001
	rst	write_vram
	ld	a,$18
	ld	de,$38
	rst	write_vram
	ld	e,$3c
	rst	write_vram

	;; Create map
	ld	de,$3800
	call	prep_vram_write
	ld	bc,3
	xor	a
1	inc	a
	out	(VDPDATA),a
	xor	a
	out	(VDPDATA),a
	djnz	1B
	dec	c
	jr	nz,1B

	;; Initial scroll conditions (A=0)
	ld	h,a
	ld	l,a
	ld	(scrbuf),hl
	ld	(scrbuf+2),hl
	ld	hl,scrbuf
	ld	(pscroll),hl

	ld	hl,irq
	ld	(irqvec),hl
	ld	hl,hirq
	ld	(rastervec),hl

	ei
	ld	hl,$1e0
	rst	set_vdp_register
	ld	hl,$0a30
	rst	set_vdp_register

1:	halt
	jr	1B

irq:	ld	hl,scrbuf
	ld	a,(hl)
	dec	a
	ld	(hl),a
	ld	l,a
	ld	h,8
	rst	set_vdp_register
	ld	hl,scrbuf+1
	ld	(pscroll),hl
	ld	b,3
	ld	c,1
1	ld	a,(hl)
	sub	c
	ld	(hl),a
	inc	hl
	inc	c
	djnz	1B
	ret

hirq:	ld	hl,(pscroll)
	ld	a,(hl)
	inc	hl
	ld	(pscroll),hl
	ld	l,a
	ld	h,8
	rst	set_vdp_register
	ret
