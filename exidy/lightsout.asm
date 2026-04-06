KBREAD	EQU	$e018
VIDEO	EQU	$e01b

	org	$0100
	map	$1000
tape_start:
	call	init_gfx
	call	init_game
main:	call	new_game
.play:	call	kbwait
	cp	27
	jr	z,.bye
	cp	32
	jr	z,main
	res	5,a
	sub	65
	cp	25
	jr	nc,.play
	call	move
	call	render_board
	call	won_game
	jr	nz,.play
	call	clrstat
	ld	hl,won1_str
	call	pstr
	ld	hl,won2_str
	call	pstr
.winlp:	call	kbwait
	res	5,a
	cp	89
	jr	z,main
	cp	78
	jr	nz,.winlp
.bye:	ld	hl,goodbye_str
	jp	print

kbwait:	call	srnd
	call	KBREAD
	jr	z,kbwait
	ret

init_game:
	ld	hl,$f0d4
	ld	a,$9a
	ld	b,23
1	ld	(hl),a
	inc	a
	inc	hl
	djnz	1B
	ld	hl,$f10f
	ld	a,$c1
	ld	b,33
1	ld	(hl),a
	inc	a
	inc	hl
	djnz	1B
	ld	hl,$f211
	ld	(hl),$b8
	inc	hl
	ld	(hl),$b6
	ld	b,25
	ld	a,$b9
1	inc	hl
	ld	(hl),a
	djnz	1B
	inc	hl
	ld	(hl),$b6
	inc	hl
	ld	(hl),$ba
	ld	hl,$f611
	ld	(hl),$bd
	inc	hl
	ld	(hl),$b7
	ld	a,$be
	ld	b,25
1	inc	hl
	ld	(hl),a
	djnz	1B
	inc	hl
	ld	(hl),$b7
	inc	hl
	ld	(hl),$bf
	push	ix
	ld	ix,$f251
	ld	de,64
	ld	b,15
1	ld	(ix),$bb
	ld	(ix+28),$bc
	add	ix,de
	djnz	1B
	pop	ix
	xor	a
	ld	hl,board
	ld	b,5
1	ld	(hl),a
	inc	hl
	djnz	1B
	call	render_board
	call	clrstat
	ld	hl,welcome_str
	call	pstr
	jp	kbwait

new_game:
	call	clrstat
	ld	hl,wait_str
	call	pstr
	ld	b,30
.lp:	push	bc
	call	new_puzzle
	call	render_board
	call	vblank
	pop	bc
	djnz	.lp
	call	clrstat
	ld	hl,instr1_str
	call	pstr
	ld	hl,instr2_str
	jp	pstr

clrstat:
	ld	hl,$f6c0
	ld	a,32
	ld	b,128
1	ld	(hl),a
	inc	hl
	djnz	1B
	ret

render_board:
	ld	a,65
	ld	(cell_letter),a
	ld	hl,$f253
	ld	de,board
	ld	c,5
1	ld	b,5
	ld	a,(de)
	inc	de
	push	de
	ld	d,a
2	ld	e,0
	srl	d
	jr	nc,3F
	ld	e,64
3	call	draw_cell
	djnz	2B
	ld	de,167
	add	hl,de
	pop	de
	dec	c
	jr	nz,1B
	ret

	;; Draw a cell at HL with bias E, and increment the letter in it.
draw_cell:
	push	bc
	push	hl
	ld	bc,cell
.lp:	ld	a,(bc)
	inc	a
	jr	z,.done
	dec	a
	jr	z,.next
	add	e
	ld	(hl),a
	inc	hl
	inc	bc
	jr	.lp
.next:	ld	a,l
	add	59
	jr	nc,1F
	inc	h
1	ld	l,a
	inc	bc
	jr	.lp
.done:	ld	hl,cell_letter
	inc	(hl)
	pop	hl
	ld	bc,5
	add	hl,bc
	pop	bc
	ret

srnd:	push	hl
	ld	hl,(rnd.x)
	inc	hl
	ld	a,h
	or	l
	jr	nz,2F
	inc	l
	push	hl
	ld	hl,(rnd.y)
	inc	hl
	ld	a,h
	or	l
	jr	nz,1F
	inc	l
1	ld	(rnd.y),hl
	pop	hl
2	ld	(rnd.x),hl
	pop	hl
	ret

rnd:	defb	$21			; LD HL, rnd.x
.x	defw	$5a3f
	;; t = x ^ (x << 5)  [t = DE and HL]
	ld	d, h
	ld	e, l
	ld	b, 5
1	sla	l
	rl	h
	djnz	1B
	ld	a, h
	xor	a, d
	ld	d, a
	ld	h, a
	ld	a, l
	xor	a, e
	ld	e, a
	ld	l, a
	;; t = t ^ (t >>> 3) [t = DE]
	ld	b, 3
1	srl	h
	rr	l
	djnz	1B
	ld	a, h
	xor	a, d
	ld	d, a
	ld	a, l
	xor	a, e
	ld	e, a
	;; x = y
	defb	$21			; LD HL, rnd.y
.y	defw	$8e77
	ld	(.x), hl
	;; y = y ^ (y >>> 1) ^ t [t = DE, y = HL]
	ld	b, h
	ld	c, l
	srl	h
	rr	l
	ld	a, b
	xor	a, h
	xor	a, d
	ld	h, a
	ld	a, c
	xor	a, l
	xor	a, e
	ld	l, a
	ld	(.y), hl
	;; return y (still in HL)
	ret

pstr:	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
1	ld	a,(hl)
	or	a
	ret	z
	ld	(de),a
	inc	hl
	inc	de
	jr	1B

print:	ld	a,(hl)
	inc	hl
	and	a
	ret	z
	call	VIDEO
	jr	print

	;; This doesn't work on JSorcerer! It reports itself as
	;; permanently in VBLANK. We replace the code with a
	;; time delay loop instead.
	;; vblank:
	;;      in      a,($fe)
	;;      bit     5,a
	;;      jr      nz,vblank
	;;1     in      a,($fe)
	;;      bit     5,a
	;;      jr      z,1B
	;;      ret
vblank:	push	hl
	push	af
	ld	hl,2840
1	dec	hl
	ld	a,h
	or	l
	jr	nz,1B
	pop	af
	pop	hl
	ret

init_gfx:
	ld	a,12
	call	VIDEO
	ld	a,32			; Hide the cursor
	ld	($f080),a
	ld	hl,lz4gfx
	ld	de,$0c00
	call	lz4dec
	ld	hl,$fa08
	ld	de,$0c08
	ld	b,200
1	ld	a,(hl)
	xor	255
	ld	(de),a
	inc	hl
	inc	de
	djnz	1B
	ld	hl,$0c00
	ld	de,$fc00
	ld	bc,$0400
	ldir
	ret

	include	"../asm/lightscore/lightsz80.asm"
	include	"../asm/lz4core/lz4u_z80.asm"

welcome_str:
	defw	$f6d5
	defb	"Press any key to begin",0
wait_str:
	defw	$f6cf
	defb	"Please wait - randomizing puzzle...",0
instr1_str:
	defw	$f6d6
	defb	"Press letters to move",0
instr2_str:
	defw	$f708
	defb	"Press SPACE for new puzzle      Press ESC to quit",0
won1_str:
	defw	$f6d4
	defb	"Congratulations, you win!",0
won2_str:
	defw	$f718
	defb	"Play again (Y/N)?",0
goodbye_str:
	defb	12,13,10,"Thanks for playing!",13,10
	defb	"   -- Bumbershoot Software, 2026",13,10,0

cell:	defb	$b8,$b9,$b9,$b9,$ba,$00,$bb,$80
cell_letter:
	defb	$30,$80,$bc,$00,$bd,$be,$be,$be,$bf,$ff

lz4gfx:	incbin	"res/lightslz4.bin"
tape_end:
