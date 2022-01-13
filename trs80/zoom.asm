	defc	cls=$01c9
	defc	kbdscn=$002b
	defc	timer=$4216

	org	$6a00

	call	cls
	ld	hl,title
	ld	de,150
	call	str_at
	ld	hl,subhed
	ld	de,799
	call	str_at

	ld	c,7
	ld	hl,stripe
	ld	de,$3d00
m_0:	ld	b,8
m_1:	push	bc
	ld	bc,8
	push	bc
	ldir
	pop	bc
	xor	a
	sbc	hl,bc
	pop	bc
	djnz	m_1
	push	bc
	ld	bc,8
	add	hl,bc
	pop	bc
	dec	c
	jr	nz,m_0

m_2:	call	kbdscn
	jr	z,m_3
	call	cls
	ret

m_3:	ld	b,7
	ld	hl,$3d00
	ld	de,buffer
m_4:	ld	a,(hl)
	ld	(de),a
	ld	a,64
	add	l
	ld	l,a
	ld	a,0
	adc	h
	ld	h,a
	inc	de
	djnz	m_4
	ld	hl,timer
	ld	de,$3d00
	ld	bc,$1bf
	ld	a,(hl)
m_5:	cp	(hl)
	jr	z, m_5
	ld	hl,$3d01
	ldir
	ld	hl,buffer
	ld	de,$3d3f
	ld	b,7
m_6:	ld	a,(hl)
	ld	(de),a
	ld	a,64
	add	e
	ld	e,a
	ld	a,0
	adc	d
	ld	d,a
	inc	hl
	djnz	m_6
	jr	m_2


	;; Print string in HL at the screen location in DE.
str_at:	push	hl
	ld	hl,$3c00
	add	hl,de
	ld	d,h
	ld	e,l
	pop	hl
sa_0:	ld	a,(hl)
	or	a
	ret	z
	ld	(de),a
	inc	de
	inc	hl
	jr	sa_0

title:	defm	"BUMBERSHOOT SOFTWARE"
	defb	0

subhed:	defb	$90,$90,$98,$98,$98,$99,$99,$81
	defm	" Speeding into the past!"
	defb	0

stripe:	defb	$BF,$BF,$BF,$BF,$BF,$BF,$BF,$BF
	defb	$9F,$81,$8B,$BF,$BF,$BF,$BF,$BF
	defb	$80,$80,$80,$82,$AF,$BF,$BF,$87
	defb	$A0,$BE,$B4,$80,$80,$8B,$81,$80
	defb	$BF,$BF,$BF,$BD,$90,$80,$80,$B8
	defb	$BF,$BF,$BF,$BF,$BF,$B4,$BE,$BF
	defb	$8F,$8F,$8F,$8F,$8F,$8F,$8F,$8F

	defc	buffer=ASMPC
