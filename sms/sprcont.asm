	define	SMS
	include "sega8bios.asm"

status	# 64*3
arrowx	# 1
arrowy	# 1

main:	ld	hl,palette
	ld	de,$8000
	ld	bc,5
	rst	blit_vram
	ld	hl,palette
	ld	de,$8010
	ld	bc,5
	rst	blit_vram
	ld	hl,spritegfx
	ld	de,$0020
	ld	bc,64
	rst	blit_vram
	ld	de,$0800
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

	ld	hl,$6080
	ld	(arrowx),hl

	ld	hl,h1str
	call	vstr
	call	vstr

	ld	hl,spriteattrs
	ld	de,$3f00
	ld	bc,6
	rst	blit_vram
	ld	de,$3f80
	ld	bc,10
	rst	blit_vram

	ld	hl,song			; Inititalize music playback
	ld	(songptr),hl
	ld	a,$1f
	ld	(vol),a
	ld	(vol+1),a
	ld	(vol+2),a
	ld	a,1
	ld	(wait),a

	ld	hl,irq
	ld	(irqvec),hl
	ld	hl,$01e0
	rst	set_vdp_register
	ei

1	halt
	jr	1B

irq:	ld	a,(joy1)		; Interpret joystick
	ld	hl,(arrowx)		; X in L, Y in H
	rra
	jr	nc,1F
	dec	h
	push	hl
	ld	hl,upstr
	call	ramstr
	pop	hl
1	rra
	jr	nc,1F
	inc	h
	push	hl
	ld	hl,dnstr
	call	ramstr
	pop	hl
1	rra
	jr	nc,1F
	dec	l
	push	hl
	ld	hl,lfstr
	call	ramstr
	pop	hl
1	rra
	jr	nc,1F
	inc	l
	push	hl
	ld	hl,rtstr
	call	ramstr
	pop	hl
1	push	hl
	rra
	jr	nc,1F
	ld	hl,b1str
	call	ramstr
1	rra
	jr	nc,1F
	ld	hl,b2str
	call	ramstr
1	pop	hl
	ld	a,l			; Boundscheck X
	cp	$07
	jr	z,1F
	cp	$fd
	jr	z,1F
	ld	(arrowx),a		; Is OK, write change to RAM and VRAM
	ld	de,$3f84
	rst	write_vram
1	ld	a,h			; Boundscheck Y
	cp	$fc
	jr	z,1F
	cp	$b9
	jr	z,1F
	ld	(arrowy),a
	ld	de,$3f02
	rst	write_vram
1	ld	hl,status
	ld	de,$3800+64*9
	ld	bc,64
	rst	blit_vram
	ld	de,$3800+64*11
	ld	bc,64
	rst	blit_vram
	ld	de,$3800+64*13
	ld	bc,64
	rst	blit_vram
	call	music
	ld	a,32
	ld	b,64*3
	ld	hl,status
1	ld	(hl),a
	inc	hl
	djnz	1B
	ret

vstr:	ld	a,(hl)
	ld	e,a
	inc	hl
	ld	a,(hl)
	ld	d,a
	inc	hl
	call	prep_vram_write
1	ld	a,(hl)
	inc	hl
	and	a
	ret	z
	out	(VDPDATA),a
	xor	a
	out	(VDPDATA),a
	jr	1B

ramstr:	push	af
	push	de
	ld	a,(hl)
	ld	e,a
	ld	d,0
	inc	hl
	push	hl
	ld	hl,status
	add	hl,de
	ex	de,hl
	pop	hl
1	ld	a,(hl)
	inc	hl
	and	a
	jr	z,1F
	ld	(de),a
	inc	de
	xor	a
	ld	(de),a
	inc	de
	jr	1B
1	pop	de
	pop	af
	ret

;; Song player, adapted from the Genesis code

songptr	# 2
vol	# 3
wait	# 1

music:	ld	hl,wait
	dec	(hl)
	jr	nz,.decay
	ld	hl,(songptr)
	ld	a,(hl)
	and	a
	jr	nz,.nolp
	ld	hl,segno
	ld	a,(hl)
.nolp:	ld	(wait),a
	inc	hl
	ld	a,(hl)
	inc	hl
	and	a
	jr	z,.v2
	;; Voice 1
	out	(PSGPORT),a
	ld	a,(hl)
	inc	hl
	out	(PSGPORT),a
	ld	a,7
	ld	(vol),a
	;; Voice 2
.v2:	ld	a,(hl)
	inc	hl
	and	a
	jr	z,.v3
	out	(PSGPORT),a
	ld	a,(hl)
	inc	hl
	out	(PSGPORT),a
	ld	a,7
	ld	(vol+1),a
	;; Voice 3
.v3:	ld	a,(hl)
	inc	hl
	and	a
	jr	z,.vdone
	out	(PSGPORT),a
	ld	a,(hl)
	inc	hl
	out	(PSGPORT),a
	ld	a,7
	ld	(vol+2),a
.vdone:	ld	(songptr),hl
.decay:	ld	a,(vol)
	cp	0x1f
	jr	z,.ndec1
	inc	a
	ld	(vol),a
.ndec1:	srl	a
	or	0x90
	out	(PSGPORT),a
	ld	a,(vol+1)
	cp	0x1f
	jr	z,.ndec2
	inc	a
	ld	(vol+1),a
.ndec2:	srl	a
	or	0xb0
	out	(PSGPORT),a
	ld	a,(vol+2)
	cp	0x1f
	jr	z,.ndec3
	inc	a
	ld	(vol+2), a
.ndec3:	srl	a
	or	0xd0
	out	(PSGPORT),a
	ret

h1str:	defw	$3886
	defb	"SPRITE AND CONTROLLER TEST",0
h2str:	defw	$3d46
	defb	"BUMBERSHOOT SOFTWARE, 2025",0
upstr:	defb	22,"UP",0
dnstr:	defb	148,"DOWN",0
lfstr:	defb	74,"LEFT",0
rtstr:	defb	94,"RIGHT",0
b1str:	defb	112,"1",0
b2str:	defb	116,"2",0

spriteattrs:
	defb	$fb,$bb,$60,$bb,$fb,$d0
	defb	$04,$01,$04,$01,$80,$02,$fc,$01,$fc,$01

palette:
	defb	$00,$3f,$05,$0a,$0f
spritegfx:
	defd	$810000,$420000,$240000,$180000,$180000,$240000,$420000,$810000
	defd	$8000,$c000,$e040,$f060,$f870,$fc40,$c000,$8000
font:
	incbin	"sinestra.bin"

song:
	incbin	"../genesis/res/nyansong.bin"
segno	equ	song+130
