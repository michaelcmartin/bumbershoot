;;; ----------------------------------------------------------------------
;;;   Unframed LZ4 Decoder for Z80 processor
;;;   (c) Michael C. Martin, 2026. Available under MIT License.
;;; ----------------------------------------------------------------------

;;; lz4dec: Decompress a single unframed LZ4 block.
;;;    HL: Pointer to compressed data
;;;    DE: Pointer to destination buffer
;;;    On output, HL and DE point one byte past the final byte read/written
;;;    Trashes ABC
lz4dec:	ld	a,(hl)
	inc	hl
	push	af
	rrca
	rrca
	rrca
	rrca
	and	15
	jr	z,.bkref
	call	.rdlen
	ldir
.bkref:	ld	c,(hl)
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	a,c
	or	b
	jr	z,.done
	pop	af
	and	15
	push	hl
	ld	h,d
	ld	l,e
	or	a
	sbc	hl,bc
	ex	(sp),hl
	call	.rdlen
	ex	(sp),hl
	inc	bc
	inc	bc
	inc	bc
	inc	bc
	ldir
	pop	hl
	jr	lz4dec
.done:	pop	af
	ret
.rdlen:	ld	b,0
	ld	c,a
	cp	15
	ret	nz
1	ld	a,(hl)
	inc	hl
	push	af
	add	c
	jr	nc,2F
	inc	b
2	ld	c,a
	pop	af
	inc	a
	jr	z,1B
	ret
