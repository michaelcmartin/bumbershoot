	org	$7000
	map	bss_start
sprite_gfx	# 192
blank_gfx	# 192

	;; Make shifted copy of sprite
	ld	hl,gfx
	ld	ix,sprite_gfx
	call	shift_sprite
	;; Make blank sprite
	ld	hl,blank_gfx
	ld	b,192
	xor	a
1	ld	(hl),a
	inc	hl
	djnz	1B

	;; Initial sprite position
	ld	de,$583c

mainlp:	halt
	push	de
	ld	hl,blank_gfx
	call	draw_sprite
	call	read_dir
	pop	de
	jr	z,.end
	ld	a,d
	add	h
	add	h
	cp	-16
	jr	nz,1F
	ld	a,-14
1	cp	192
	jr	nz,1F
	ld	a,190
1	ld	d,a
	ld	a,e
	add	l
	cp	-8
	jr	nz,1F
	ld	a,-7
1	cp	128
	jr	nz,1F
	ld	a,127
1	ld	e,a
	push	de
	ld	hl,sprite_gfx
	call	draw_sprite
	pop	de
	jr	mainlp
.end:	ret

;;; Returns DY in H, DX in L, and zero-flag set if Space is pressed
; Q,A,P, and SPACE are the 1 bit in ports 64510, 65022, 57342, and 32766 respectively, while O is the 2 bit in port 57342.
read_dir:
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
	ld	c,16			; BC = 16 = column size in src
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

;; HL: Pointer to "base" graphics (B*32 bytes)
;; IX: Pointer to output buffer (B*48*4 bytes)
shift_sprite:
	push	bc
	push	de
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
	add	hl,hl
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
	pop	de			; Restore registers
	pop	bc
	ret

gfx:	defb	$ff,$ff,$e0,$d0,$c8,$c4,$c2,$c1,$c1,$c2,$c4,$c8,$d0,$e0,$ff,$ff
	defb	$ff,$ff,$07,$0b,$13,$23,$43,$83,$83,$43,$23,$13,$0b,$07,$ff,$ff
bss_start:
