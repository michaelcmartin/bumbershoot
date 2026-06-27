	org	$7000
	map	bss_start
	;; Graphics data:  must be first
reversed_blaster # 32
target_gfx # 192
blaster_lgfx # 192
blaster_rgfx # 192
blank_gfx # 192
	;; Game logic data
blaster_x # 1
blaster_old_x # 1
blaster_facing # 1
blaster_old_facing # 1
target_y # 1
target_x # 3
target_old_r1 # 2
target_old_r2 # 2


	;; Prepare the sprite graphics with the necessary mirroring...
	ld	hl,gfx+32
	ld	de,reversed_blaster
	call	reverse_sprite
	;; ... and shifting
	ld	hl,gfx
	ld	ix,target_gfx
	ld	b,3
	call	shift_sprites
	;; ... and clearing
	xor	a
	ld	b,192
1	ld	a,(hl)
	inc	hl
	djnz	1B

	;; Initialize score
	ld	a,$30
	ld	hl,score
	ld	b,4
1	ld	(hl),a
	inc	hl
	djnz	1B

	;; Initialize remaining game logic
	ld	a,64
	ld	(blaster_x),a
	ld	(blaster_old_x),a
	ld	a,1
	ld	(blaster_facing),a
	ld	(blaster_old_facing),a
	ld	a,28
	ld	(target_x),a
	add	32
	ld	(target_x+1),a
	add	32
	ld	(target_x+2),a
	ld	a,20
	ld	(target_y),a
	ld	hl,0
	ld	(target_old_r1),hl

	;; Generate the main screen display
	ld	a,$02			;; Black screen, red text
	call	clrto			;; for main screen (shots/targets)
	ld	hl,$5a60		;; Blaster track
	ld	a,$06
	ld	b,64
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	a,$20			;; Ground
	ld	b,96
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	hl,$5800		;; Header
	ld	a,$38
	ld	b,32
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	hl,header
	call	print

	;; Main Game Loop here
main:	halt
	ld	hl,(target_old_r1)
	ld	a,h
	or	a
	jr	z,.draw_targets
	;; Erase two rows at target_old_r1 and target_old_r2
	push	hl
	xor	a
	ld	(hl),a
	ld	d,h
	ld	e,l
	inc	de
	ld	bc,31
	ldir
	pop	hl
	ld	de,(target_old_r2)
	ld	bc,32
	ldir
.draw_targets:
	ld	a,(target_y)
	ld	d,a
	ld	b,3
	ld	hl,target_x
1	ld	e,(hl)
	inc	hl
	push	hl
	push	de
	push	bc
	ld	hl,target_gfx
	call	draw_sprite
	pop	bc
	pop	de
	pop	hl
	djnz	1B
	;; Erase blaster if necessary
	ld	a,(blaster_old_x)
	ld	hl,blaster_x
	cp	(hl)
	jr	z,1F
	ld	hl,blaster_old_facing
	sub	2
	bit	0,(hl)
	jr	z,2F
	sub	3
2	ld	e,a
	ld	d,152
	ld	hl,blank_gfx
	call	draw_sprite
1	;; Now draw the blaster
	ld	a,(blaster_x)
	sub	5
	ld	e,a
	ld	d,152
	ld	a,(blaster_facing)
	ld	hl,blaster_lgfx
	or	a
	jr	nz,1F
	ld	hl,blaster_rgfx
	ld	a,e
	add	3
	ld	e,a
1	call	draw_sprite
	;; Rendering complete. Copy current values to old.
	ld	hl,blaster_x
	ld	b,2
1	ld	a,(hl)
	inc	hl
	ld	(hl),a
	inc	hl
	djnz	1B
	;; Handle input
	call	read_keys
	jr	z,.end
	ld	de,blaster_x
	ld	a,(de)
	add	l
	cp	4
	jr	z,1F
	cp	123
	jr	nz,2F
1	sub	l
2	ld	(de),a
	ld	a,l
	or	a
	jr	z,1F
	rlca
	and	1
	ld	(blaster_facing),a
1	ld	de,target_y
	ld	a,(de)
	add	h
	add	h
	cp	$08
	jr	z,1F
	cp	$8a
	jr	nz,2F
1	sub	h
	sub	h
2	ld	(de),a
	;; Prepare row clears if needed
	ld	de,0
	ld	l,a
	ld	a,h
	or	a
	jr	z,1F
	jp	m,.up
	ld	a,(target_y)
	sub	2
	jr	2F
.up:	ld	a,(target_y)
	add	16
2	push	af
	call	row_addr
1	ld	(target_old_r1),de
	ld	a,d
	or	a
	jr	z,1F
	pop	af
	inc	a
	call	row_addr
1	ld	(target_old_r2),de
	;; Move targets left
	ld	hl,target_x
	ld	b,3
1	ld	a,(hl)
	dec	a
	cp	-32
	jr	nz,2F
	ld	a,128
2	ld	(hl),a
	inc	hl
	djnz	1B
	jp	main

	;; Quit program: clear back to normal display
.end:	ld	a,$38
	jp	clrto

;;; ----------------------------------------------------------------------
;;;  Game support routines
;;; ----------------------------------------------------------------------

;;; QAOP controls. Returns DY in H, DX in L
;;;   Zero-flag set if Space is pressed
read_keys:
	ld	hl,0
	ld	bc,$fbfe		; Check Q
	in	a,(c)
	rra
	jr	c,1F
	dec	h
1	ld	b,$fd			; Check A
	in	a,(c)
	rra
	jr	c,1F
	inc	h
1	ld	b,$df			; Check P
	in	a,(c)
	rra
	jr	c,1F
	inc	l
1	rra				; Check O
	jr	c,1F
	dec	l
1	ld	b,$7f			; Check SPACE
	in	a,(c)
	and	1			; Set Z if SPACE pressed
	ret

row_addr:
	ld	d,a
	and	7
	ld	b,a
	ld	a,d
	rra
	scf
	rra
	rra
	and	$58
	or	b
	ld	b,a
	ld	a,d
	ld	d,b
	add	a
	add	a
	and	$e0
	ld	e,a
	ret

;;; ----------------------------------------------------------------------
;;;   Sprite graphics generation routines
;;; ----------------------------------------------------------------------

reverse_sprite:
	push	hl
	push	de
	ld	de,16
	add	hl,de
	pop	de
	call	.col
	pop	hl
	call	.col
	push	de
	ld	de,16
	add	hl,de
	pop	de
	ret
.col:	ld	c,16
1	push	de
	ld	a,(hl)
	ld	b,8
2	rra
	rl	d
	djnz	2B
	ld	a,d
	pop	de
	ld	(de),a
	inc	hl
	inc	de
	dec	c
	jr	nz,1B
	ret

;;  B: Number of sprites
;; HL: Pointer to "base" graphics (B*32 bytes)
;; IX: Pointer to output buffer (B*48*4 bytes)
shift_sprites:
	push	de
1	call	.shift
	djnz	1B
	pop	de
	ret
.shift:	push	bc
	push	hl			; IX += 96; PUSH IX; LD IX,HL
	ld	de,96			; shift IX so it reaches all
	add	ix,de			; 192 bytes
	ex	(sp),ix			; (Cache dest ptr, IX=src ptr)
	ld	b,16			; 16 pixel rows
1	xor	a			; Load gfx
	ld	h,(ix)
	ld	l,(ix+16)
	inc	ix			; Advance src ptr
	ex	(sp),ix			; Swap to dest ptr
	ld	(ix-96),h		; Write unshifted
	ld	(ix-80),l
	ld	(ix-64),a
	add	hl,hl			; stay in the 0-127 offset range
	rla
	add	hl,hl			; Shift left 2 for the "right 6" sprite
	rla
	ld	(ix+48),a
	ld	(ix+64),h
	ld	(ix+80),l
	add	hl,hl			; Now for "right 4"
	rla
	add	hl,hl
	rla
	ld	(ix),a
	ld	(ix+16),h
	ld	(ix+32),l
	add	hl,hl			; Finally "right 2"
	rla
	add	hl,hl
	rla
	ld	(ix-48),a
	ld	(ix-32),h
	ld	(ix-16),l
	inc	ix			; Next dest row
	ex	(sp),ix			; And swap focus to src
	djnz	1B
	push	ix			; src ptr back in HL
	pop	hl
	ld	e,16			; Advance src (D is still 0)
	add	hl,de
	pop	ix			; dest ptr back in IX
	ld	e,80			; Advance dest
	add	ix,de
	pop	bc			; Restore BC for outer loop
	ret

;;; ----------------------------------------------------------------------
;;;   Sprite rendering routines
;;; ----------------------------------------------------------------------

;;; draw_sprite
;;; HL = source ptr
;;; D = Y coord (-15 - 191)
;;; E = X coord (-7 - 127)
draw_sprite:
	;; Quit immediately if we're entirely off the top or bottom
	ld	a,d
	add	15
	cp	192+15
	ret	nc
	;; src += 48 * (x & 3)
	ld	a,e
	and	3
	jr	z,.x_aligned
	ld	bc,48
1	add	hl,bc
	dec	a
	jr	nz,1B
.x_aligned:
	sra	e			; Move E from X coord to char offset
	sra	e
	ld	a,3			; Number of columns to render
	;; Skip any columns off the left edge. X>127 reads as negative, so
	;; this catches being completely offscreen on left *and* right edges
	ld	bc,16			; BC = 16 = column size in src
1	bit	7,e			; X coord negative?
	jr	z,.blit			; Once we're on-screen go blit
	add	hl,bc			; Otherwise skip a column...
	inc	e			; ... move a character cell right...
	dec	a			; ... decrement the column count...
	ret	z			; ... quit if it's zero...
	jr	1B			; ... and check again if it's not.
.blit:	ld	c,a			; Column count in C
	ld	b,16			; Default row count in B
	;; Adjust source pointer and row count if we're off the top
	ld	a,b			; ... are we off the top?
	add	d
	jr	nc,1F
	ld	b,a			; If so, correct height...
	ld	a,16			; ... compute ptr offset...
	sub	b
	add	l			; ...and apply it to source...
	jr	nc,2F
	inc	h
2	ld	l,a
	ld	d,0			; ... and set Y to top of screen
	jr	.y_ok
	;; Adjust row count if we're off the bottom
1	ld	a,192-16
	sub	d
	jr	nc,.y_ok
	add	b
	ld	b,a			; Wow this code is unfortunate
	;; Convert final X/Y to write coords in DE
.y_ok:	ld	a,b			; Store row count in loop
	ld	(.row_count),a
	ld	a,16
	sub	b
	ld	(.stride),a
	ld	a,d
	and	7
	ld	b,a
	ld	a,d
	rra
	scf
	rra
	rra
	and	$58
	or	b
	ld	b,a
	ld	a,d
	ld	d,b
	add	a
	add	a
	and	$e0
	or	e
	ld	e,a
	;; Blit out C columns of 16 rows each.
	;; The .row_count and .stride variables are constants
	;; here modified by the prep code; .row_count is the
	;; number of rows actually copied, and .stride the number
	;; skipped. Their sum should always be 16.
1	push	de
	ld	b,16
.row_count equ $-1
2	ld	a,(hl)
	inc	hl
	ld	(de),a
	inc	d
	ld	a,7
	and	d
	jr	nz,3F
	ld	a,e
	add	32
	ld	e,a
	jr	c,3F
	ld	a,d
	sub	8
	ld	d,a
3	djnz	2B
	pop	de
	inc	de
	ld	a,e
	and	31
	ret	z
	ld	a,0
.stride equ $-1
	add	l
	jr	nc,4F
	inc	h
4	ld	l,a
	dec	c
	jr	nz,1B
	ret


;;; ----------------------------------------------------------------------
;;;   Other graphical support routines
;;; ----------------------------------------------------------------------

clrto:	ld	(iy+83),a		; ATTR-P
	and	$38
	ld	(iy+14),a		; BORDCR
	rrca
	rrca
	rrca
	out	($fe),a
	xor	a
	ld	(iy+84),a		; MASK-P
	ld	(iy+87),a		; P-FLAGS
	call	$0d6b			; CLS
	ld	a,2
	jp	$1601			; CHAN-OPEN

print:	ld	a,(hl)
	inc	hl
	cp	$ff
	ret	z
	rst	$10
	jr	print

;;; ----------------------------------------------------------------------
;;;   Graphics data
;;; ----------------------------------------------------------------------

header:	db	$10,0,$11,7,$16,0,20,"SCORE: "
score:	db	"----",$ff

	;; "gfx" must be last so that the start of the BSS map bumps up against
	;; it. That lets the mirrored sprites show up as part of a contiguous
	;; block for the sprite shifter.
gfx:	defb	$03,$0f,$1c,$30,$63,$66,$cc,$c9,$c9,$cc,$66,$63,$30,$1c,$0f,$03
	defb	$c0,$f0,$38,$0c,$c6,$66,$33,$93,$93,$33,$66,$c6,$0c,$38,$f0,$c0
	defb	$00,$00,$00,$00,$00,$00,$00,$fa,$8b,$ea,$ef,$88,$80,$db,$3c,$18
	defb	$00,$00,$20,$20,$70,$a8,$f8,$aa,$fe,$fa,$ff,$01,$01,$ed,$1e,$0c
bss_start:
