	org	$7000

	ld	b,8			; Play 8 notes
	ld	hl,scale		; Load from pointer
1	push	bc
	ld	c,(hl)			; Load frequency into BC
	inc	hl
	ld	b,(hl)
	inc	hl
	ld	e,(hl)			; Load duration into HL
	inc	hl
	ld	d,(hl)
	inc	hl
	push	hl			; Stash pointer...
	ld	h,b			; ... Copy BC to HL...
	ld	l,c
	call	$03b5			; ... and let the ROM do the rest
	pop	hl
	pop	bc
	djnz	1B
	ret

scale:	dw	$066a,$0082,$05b3,$0092,$0511,$00a4,$04c6,$00ae
	dw	$043d,$00c3,$03c4,$00dc,$0357,$00f6,$0325,$0105
