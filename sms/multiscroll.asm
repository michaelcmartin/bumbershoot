	define	SMS
	include	"sega8bios.asm"

scr_x	# 1
scr_y	# 1
mode	# 1

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
	ld	de,$2800
	call	prep_vram_write
	ld	hl,font2
	ld	bc,2
1	ld	a,(hl)
	out	(VDPDATA),a
	xor	a
	out	(VDPDATA),a
	inc	hl
	out	(VDPDATA),a
	nop
	out	(VDPDATA),a
	djnz	1B
	ld	de,$2400
	call	prep_vram_write
	dec	c
	jr	nz,1B
	ld	a,$3f
	ld	de,$8001
	rst	write_vram
	ld	a,$20
	ld	de,$8010
	rst	write_vram
	ld	a,$1f
	ld	de,$8011
	rst	write_vram

	xor	a
	ld	(scr_x),a
	ld	(scr_y),a
	ld	(mode),a

	call	screen_main
	ld	hl,irq
	ld	(irqvec),hl
	ei
	ld	hl,$01e0
	rst	set_vdp_register

1	halt
	jr	1B

irq:	ld	a,(scr_y)
	ld	h,a
	ld	a,(scr_x)
	ld	l,a
	ld	a,(joy1)
	rrca
	jr	nc,1F
	dec	h
1	rrca
	jr	nc,1F
	inc	h
1	rrca
	jr	nc,1F
	inc	l
1	rrca
	jr	nc,1F
	dec	l
1	ld	a,h
	cp	224
	jr	nz,1F
	xor	a
1	cp	255
	jr	nz,1F
	ld	a,223
1	ld	(scr_y),a
	ld	a,l
	ld	(scr_x),a
	ld	a,(joy1_pressed)
	and	$30			; Either button pressed?
	jr	z,1F
	call	change_screen
1	ld	a,(scr_x)
	ld	l,a
	ld	h,$08
	rst	set_vdp_register
	ld	a,(scr_y)
	ld	l,a
	ld	h,$09
	rst	set_vdp_register
	ret

change_screen:
	ld	hl,$0180		; Disable display
	rst	set_vdp_register
	call	screen_main
	ld	a,(mode)
	inc	a
	cp	3
	jr	nz,1F
	xor	a
1	ld	(mode),a
	and	a
	jr	z,.end
	dec	a
	jr	nz,1F
	call	screen_top
	jr	.end
1	call	screen_right
.end:	ld	hl,$01e0		; Re-enable display
	rst	set_vdp_register
	ret

screen_main:
	ld	hl,$36
	rst	set_vdp_register
	ld	de,$3800
	call	prep_vram_write
	ld	d,0
	ld	bc,32*28
1	ld	a,d
	and	63
	add	32
	inc	d
	out	(VDPDATA),a
	xor	a
	out	(VDPDATA),a
	dec	bc
	ld	a,b
	or	c
	jr	nz,1B
	ret

screen_top:
	ld	hl,$76
	rst	set_vdp_register
	ld	de,$3800
	call	prep_vram_write
	ld	b,64
	ld	hl,topbar
1	ld	a,(hl)
	out	(VDPDATA),a
	inc	hl
	ld	a,$09
	out	(VDPDATA),a
	djnz	1B
	xor	a
	ld	(scr_x),a
	ld	(scr_y),a
	ret

screen_right:
	ld	hl,$b6
	rst	set_vdp_register
	ld	hl,rightbar
	ld	de,$3830
	ld	c,28
1	call	prep_vram_write
	ld	a,e
	add	64
	jr	nc,2F
	inc	d
2	ld	e,a
	ld	b,8
3	ld	a,(hl)
	out	(VDPDATA),a
	inc	hl
	ld	a,$09
	out	(VDPDATA),a
	djnz	3B
	dec	c
	jr	nz,1B
	xor	a
	ld	(scr_x),a
	ld	(scr_y),a
	ret

topbar:	defb	"       TOP ROW STATUS BARS      "
	defb	"    SCROLL VERTICALLY TO RUIN   "

rightbar:
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	" RIGHT  "
	defb	" SIDE   "
	defb	" STATUS "
	defb	" WINDOW "
	defb	"        "
	defb	"        "
	defb	" SCROLL "
	defb	" RIGHT  "
	defb	" OR LEFT"
	defb	" TO RUIN"
	defb	" IT ALL "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "
	defb	"        "

font:	incbin	"halogen.bin"
font2:	incbin	"sinestra.bin"
