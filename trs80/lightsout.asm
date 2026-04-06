KBWAIT	EQU	$0049
CLS	EQU	$01c9
DISPA	EQU	$033A
SCRNMEM	EQU	$3c00
CURSOR	EQU	$4020
TIMER	EQU	$4216

	org	$6a00
	map	$7000

	ld	hl,(TIMER)
	call	srnd
	call	init_game
main:	call	new_game
.play:	call	KBWAIT
	cp	48
	jr	z,.bye
	cp	49
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
.winlp:	call	KBWAIT
	res	5,a
	cp	89
	jr	z,main
	cp	78
	jr	nz,.winlp
.bye:	call	CLS
	ld	hl,$3cc0
	ld	(CURSOR),hl
	ld	hl,goodbye_str
	call	pstr
	ld	hl,goodbye2_str
	jp	pstr

init_game:
	call	CLS
	ld	hl,title_str
	call	pstr
	ld	hl,$3d18
	ld	(hl),$9c
	ld	b,15
	ld	a,$8c
1	inc	hl
	ld	(hl),a
	djnz	1B
	inc	hl
	ld	(hl),$ac
	ld	hl,$3e97
	ld	a,$83
	ld	b,17
1	inc	hl
	ld	(hl),a
	djnz	1B
	push	ix
	ld	ix,$3d58
	ld	de,64
	ld	b,5
1	ld	(ix),$95
	ld	(ix+16),$aa
	add	ix,de
	djnz	1B
	pop	ix
	ld	a,65
	ld	hl,$3d5a
	ld	de,49
	ld	c,5
1	ld	b,5
2	ld	(hl),a
	inc	a
	inc	hl
	inc	hl
	inc	hl
	djnz	2B
	add	hl,de
	dec	c
	jr	nz,1B
	ret

new_game:
	call	clrstat
	ld	hl,wait_str
	call	pstr
	ld	b,30
.lp:	push	bc
	call	new_puzzle
	call	render_board
	ld	hl,TIMER		; Wait 1/30 sec
	ld	a,(hl)
1	cp	(hl)
	jr	z,1B
	pop	bc
	djnz	.lp
	call	clrstat
	ld	hl,instr1_str
	call	pstr
	ld	hl,instr2_str
	jp	pstr

clrstat:
	ld	hl,$3f80
	ld	de,$3f81
	ld	(hl),32
	ld	bc,127
	ldir
	ret

render_board:
	ld	hl,$3d59
	ld	de,board
	ld	c,5
1	ld	b,5
	ld	a,(de)
	inc	de
	push	de
	ld	d,a
2	ld	a,32
	ld	e,a
	srl	d
	jr	nc,3F
	ld	a,91
	ld	e,93
3	ld	(hl),a
	inc	hl
	inc	hl
	ld	(hl),e
	inc	hl
	djnz	2B
	ld	de,49
	add	hl,de
	pop	de
	dec	c
	jr	nz,1B
	ret

	INCLUDE	"../asm/lightscore/lightsz80.asm"

srnd:	ld	a,h
	or	l
	jr	nz,1F
	inc	hl
1	ld	(rnd.x),hl
	ld	(rnd.y),hl

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

title_str:
	defw	$3c1b
	defb	"LIGHTS OUT!",0
wait_str:
	defw	$3f8f
	defb	"Please wait - randomizing puzzle...",0
instr1_str:
	defw	$3f96
	defb	"Press letters to move",0
instr2_str:
	defw	$3fcb
	defb	"Press 1 for new puzzle      Press 0 to quit",0
won1_str:
	defw	$3f94
	defb	"Congratulations, you win!",0
won2_str:
	defw	$3fd8
	defb	"Play again (Y/N)?",0
goodbye_str:
	defw	$3c00
	defb	"Thanks for playing!",0
goodbye2_str:
	defw	$3c43
	defb	"-- Bumbershoot Software, 2026",0
