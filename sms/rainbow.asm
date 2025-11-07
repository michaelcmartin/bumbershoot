	define	SMS
	include	"sega8bios.asm"

fontbuf	# 8

main:	ld	hl,palette
	ld	de,$8000
	ld	bc,16
	rst	blit_vram

	call	makefont
	call	mkscr
	ld	hl,$01c0
	rst	set_vdp_register

1	halt
	jr	1B

makefont:
	ld	de,$0400
	call	prep_vram_write
	ld	hl,font
	ld	c,64
.chrlp:	ld	de,bgpats		; Load first two backgrounds
	ld	ix,fontbuf
	ld	b,8
1	ld	a,(de)
	ld	(ix),a
	inc	de
	inc	ix
	djnz	1B
	ld	b,8
.rowlp:	push	bc
	ld	a,(hl)
	inc	hl
	push	hl
	ld	c,a
	ld	b,4
	ld	hl,fontbuf
1	ld	a,(hl)
	or	c
	ld	(hl),a
	inc	hl
	djnz	1B
	srl	c
	ld	a,(fontbuf+7)
	or	c
	ld	(fontbuf+7),a
	ld	ix,fontbuf
	ld	b,4
1	ld	a,(ix)
	out	(VDPDATA),a
	ld	a,(ix+4)
	ld	(ix),a
	ld	a,(de)
	inc	de
	ld	(ix+4),a
	inc	ix
	djnz	1B
	pop	hl
	pop	bc
	djnz	.rowlp
	dec	c
	jr	nz,.chrlp
	ret

mkscr:	ld	de,$3800+9*64+20
	ld	hl,msg
	ld	c,7
1	call	prep_vram_write
	ld	b,12
2	ld	a,(hl)
	out	(VDPDATA),a
	inc	hl
	xor	a
	out	(VDPDATA),a
	djnz	2B
	ld	a,e
	add	64
	ld	e,a
	jr	nc,2F
	inc	d
2	dec	c
	jr	nz,1B
	ret

palette:
	defb	$00,$0f,$08,$28,$20,$32,$33,$02
	defb	$07,$0a,$04,$14,$10,$21,$22,$3f

bgpats:	defd	$ffffff,$ff000000,$ff,$ff00,$ffff,$ff0000,$ff00ff,$ffff00

font:	incbin	"sinestra.bin",256,256
	incbin	"sinestra.bin",0,256

msg:	defb	"            "
	defb	"  ANIMATED  "
	defb	"            "
	defb	"   SHADOW   "
	defb	"            "
	defb	"  RAINBOWS  "
	defb	"            "
