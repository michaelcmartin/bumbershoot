;;; ----------------------------------------------------------------------
;;;   Sprite graphics library
;;;   (c) 2026 Michael C. Martin / Bumbershoot Software. Made available
;;;   under the MIT license: see the LICENSE file at the root of this
;;;   repository for details.
;;;
;;;   This library is designed for use with 16x16 sprites with
;;;   pre-assigned color attributes. Three routines are defined:
;;;
;;;   reverse_sprite: HL and DE point to src and destination buffers
;;;                   respectively; places a horizontally-mirrored copy
;;;                   of the sprite in HL in DE. Trashes ABC; HL and DE
;;;                   are advanced just past the buffers read/written.
;;;                   This function may be called repeatedly to convert
;;;                   multiple sprites in bulk.
;;;   shift_sprites:  Bakes all assets for efficient blitting later.
;;;                   B holds a sprite count, HL an array of 16x16 source
;;;                   images, and IX an array of 24x16x4 destination
;;;                   buffers. Trashes AB; HL and IX are advanced past
;;;                   the regions read or written.
;;;   draw_sprite:    Renders a sprite on-screen. HL points to the graphic
;;;                   array (the one created by shift_sprites); D holds
;;;                   the Y coordinate (-15 - 191), and E holds the X
;;;                   coordinate (-7 - 127). X coordinates are doubled as
;;;                   part of processing. Trashes ABCDEHL.
;;;   row_addr:       Converts a row in A (0-191) to a screen address in
;;;                   DE representing the left edge of that row.
;;;                   Trashes AB.
;;; ----------------------------------------------------------------------

;; TODO: Harmonize API with reverse and shift sprites. Make row_addr
;; more friendly and give complete addresess so shots can use it too.

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

