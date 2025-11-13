	define	SMS
	include	"sega8bios.asm"

fontbuf	# 8
cursor  # 1

main:	ld	a,$3f
	ld	de,$800f
	rst	write_vram
	ld	e,$1f
	rst	write_vram
	xor	a
	ld	(cursor),a

	call	makefont
	call	mkscr
	call	setpal

	ei
	ld	hl,$01e0
	rst	set_vdp_register

1	halt
	halt
	halt
	call	setpal
	jr	1B

setpal:	ld	de,$8007
	ld	hl,colorcycle
	ld	a,(cursor)
	add	l
	jr	nc,1F
	inc	h
1	ld	l,a
	ld	bc,2
	rst	blit_vram
	ld	de,$8001
	ld	bc,6
	rst	blit_vram
	ld	de,$8017
	ld	bc,2
	rst	blit_vram
	ld	de,$8011
	ld	bc,6
	rst	blit_vram
	ld	de,$8009
	ld	a,l
	add	17
	jr	nc,1F
	inc	h
1	ld	l,a
	ld	bc,6
	rst	blit_vram
	ld	de,$8019
	ld	bc,6
	inc	hl
	inc	hl
	rst	blit_vram
	ld	a,(cursor)
	inc	a
	and	15
	ld	(cursor),a
	ret

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

mkscr:	ld	hl,0
	push	hl
	ld	de,$3800+9*64+20
	ld	hl,msg
	ld	c,7
1	call	prep_vram_write
	ld	b,12
2	ld	a,(hl)
	out	(VDPDATA),a
	inc	hl
	ex	(sp),hl
	ld	a,l
	out	(VDPDATA),a
	ex	(sp),hl
	djnz	2B
	ld	a,e
	add	64
	ld	e,a
	jr	nc,2F
	inc	d
2	ex	(sp),hl
	ld	a,l
	xor	8
	ld	l,a
	ex	(sp),hl
	dec	c
	jr	nz,1B
	pop	hl
	ret

colorcycle:
	defb	$02,$02,$07,$07,$0f,$0f,$08,$08
	defb	$28,$28,$20,$20,$32,$32,$33,$33
	defb	$02,$02,$07,$07,$0f,$0f,$08,$08
	defb	$28,$28,$20,$20,$32,$32,$33
	defb	$01,$01,$06,$06,$0a,$0a,$04,$04
	defb	$14,$14,$10,$10,$21,$21,$22,$22
	defb	$01,$01,$06,$06,$0a,$0a,$04,$04
	defb	$14,$14,$10,$10,$21,$21,$22

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
