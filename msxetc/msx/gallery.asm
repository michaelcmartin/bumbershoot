;;;----------------------------------------------------------------------
;;;  Shooting Gallery Shell: MSX edition
;;;  See ../gallerycore.asm file for platform-independent logic.
;;;----------------------------------------------------------------------

	include	"msxbios.asm"

	org	$8000
	map	$e000
	dw	$4241,INIT,0,0,0,0,0,0

INIT:	ld	hl,0			; Set up VRAM tables
	ld	(T32NAM),hl
	ld	h,$08
	ld	(T32CGP),hl
	ld	(T32PAT),hl
	ld	hl,$0300
	ld	(T32ATR),hl
	ld	l,$80
	ld	(T32COL),hl
	ld	a,$f
	ld	(FORCLR),a
	ld	a,1
	ld	(BAKCLR),a
	ld	(BDRCLR),a
	call	INIT32
	ld	bc,$e101		; Magnify sprites
	call	WRTVDP

	;; Draw static screen
	ld	a,$07			; Draw divider line
	ld	bc,$0020
	ld	hl,$0020
	call	FILVRM
	ld	a,$68			; Draw ground
	ld	bc,$0060
	ld	hl,$02a0
	call	FILVRM
	ld	a,$22			; Ground is green
	ld	hl,$38d
	call	WRTVRM
	ld	hl,gfx_score
	ld	bc,$000b		; Score display
	ld	de,$0014
	call	LDIRVM
	;; Initialize graphics patterns
	ld	hl,gfx_pat
	ld	bc,$0088		; Tile graphics
	ld	de,$0808
	call	LDIRVM
	ld	hl,gfx_sprpat
	ld	bc,$0018		; Sprite graphics
	ld	de,$0b00
	call	LDIRVM
	ld	hl,gfx_sprattr
	ld	bc,$0030		; Load sprite attrs to CPU RAM
	ld	de,sprattrs
	ldir
	ld	bc,$0031		; Then blit them to VRAM
	ld	de,$0300
	ld	hl,gfx_sprattr
	call	LDIRVM

	ld	hl,0
	ld	(score),hl

mainlp:	ld	hl,JIFFY
	ld	a,(hl)
1	halt
	cp	(hl)
	jr	z,1b

	ld	a,(STATFL)
	and	$20
	ld	(collision),a
	call	irq
	jr	mainlp

blit_sprites:
	ld	hl,sprattrs
	ld	de,$0300
	ld	bc,$0030
	call	LDIRVM
	ret

blit_score:
	ld	hl,scorebuf
	ld	de,$001b
	ld	bc,$0004
	call	LDIRVM
	ret

read_joystick:
	push	bc
	push	de
	xor	a
	ld	d,a
	call	GTTRIG
	and	a
	jr	nz,1f
	inc	a
	call	GTTRIG
	and	a
	jr	nz,1f
	ld	a,3
	call	GTTRIG
1	ld	(fire),a
	xor	a
	call	GTSTCK
	and	a
	jr	nz,1f
	inc	a
	call	GTSTCK
1	add	a
	ld	e,a
	ld	hl,directions
	add	hl,de
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	pop	de
	pop	bc
	ret

directions:
	dw	$0000,$00fe,$02fe,$0200,$0202,$0002,$fe02,$fe00,$fefe

	include	"../common/gallerycore.asm"

	ds	$a000-$,$ff
