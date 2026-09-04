;;; ZX Spectrum sound test: Frequency-coded internal beeper
;;; Unlike other programs in this directory, this program is
;;; ORG $8000 and Spectralink must be configured accordingly!
;;; It is incompatible with the 16K Spectrum; see ROMBEEPER.ASM
;;; for code that works there.

	org	$8000
	map	bss_start

	ld	b,8
	ld	hl,scale
1	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	push	hl
	push	bc
	ld	bc,$2000
	call	sound
	pop	bc
	pop	hl
	djnz	1B
	ret

sound:	ld	hl,0
	ld	a,($5c48)		; BORDCR
	and	$38
	rrca
	rrca
	rrca
	or	$08
	di
.lp:	add	hl,de			; +11 = 11
	jp	nc,2F			; +10 = 21
	xor	$10			; + 7 = 28
	out	($fe),a			; +11 = 39
1	nop				; + 4 = 43
	nop				; + 4 = 47
	nop				; + 4 = 51
	nop				; + 4 = 55
	nop				; + 4 = 59
	nop				; + 4 = 63
	nop				; + 4 = 67
	nop				; + 4 = 71
	nop				; + 4 = 75
	nop				; + 4 = 79
	jp	3F			; +10 = 89
3	add	hl,de			; +11 = 11
	jp	nc,5F			; +10 = 21
	xor	$10			; + 7 = 28
	out	($fe),a			; +11 = 39
4	dec	bc			; + 6 = 45
	ld	(.scratch),a		; +13 = 58
	ld	a,b			; + 4 = 62
	or	c			; + 4 = 66
	ld	a,(.scratch)		; +13 = 79
	jp	nz,.lp			; +10 = 89
	ei
	ret
2	nop				; + 4 = 25
	nop				; + 4 = 29
	jp	1B			; +10 = 39
5	nop				; + 4 = 25
	nop				; + 4 = 29
	jp	4B			; +10 = 39
.scratch # 1

scale:	dw	$0367,$03d2,$044a,$048b,$051a,$05ba,$066e,$06cf

bss_start:
