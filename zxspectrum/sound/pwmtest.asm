	org	$8100

	ld	hl,pcmdat
	ld	bc,pcmlen
	call	pcm
	ret

pcm:	di
	exx
	push	bc
	push	de
	push	hl
	exx
	call	.lp
	exx
	pop	hl
	pop	de
	pop	bc
	exx
	ei
	ret
.step:	;; Enter .step on cycle 85
	ld	b,18			; + 7 ( 92)
1	djnz	1B			; 229 (321) (17*13+8)
	exx				; + 4 (325)
	dec	bc			; + 6 (331)
	ld	a,b			; + 4 (335)
	or	c			; + 4 (339)
	ret	z			; + 5 (344)
.lp:	ld	a,(hl)			; + 7 (351)
	inc	hl			; + 6 (357)
	rrca				; + 4 (361)
	rrca				; + 4 (365)
	and	$1e			; + 7 (372)
	exx				; + 4 (376)
	ld	h,.table / 256		; + 7 (383)
	add	.table & $ff		; + 7 (390)
	ld	l,a			; + 4 (394)
	ld	e,(hl)			; + 7 (401)
	inc	l			; + 4 (405)
	ld	d,(hl)			; + 7 (412)
	ex	de,hl			; + 4 (416)
	ld	a,$17			; + 7 (423)
	jp	(hl)			; + 4 (427)
	align	32
.table: dw	.s0,.s0,.s0,.s0
	dw	.s0,.s0,.s3,.s6
	dw	.s9,.s12,.s15,.s15
	dw	.s15,.s15,.s15,.s15

	;; Enter on cycle 427, exit on cycle 85
	macro	pcmstep i		; 86 cycles
	out	($fe),a			; 11
	xor	$10			;  7
	repeat	i
	nop				; 4*i
	endrepeat
	out	($fe),a			; 11
	repeat	15-i			; 60-4*i
	nop
	endrepeat
	jp	.step
	endmacro

.s0:	pcmstep 0
.s3:	pcmstep 3
.s6:	pcmstep 6
.s9:	pcmstep 9
.s12:	pcmstep 12
.s15:	pcmstep 15

pcmdat:	INCBIN	"wow_pcm.dat"
pcmlen	EQU	$-pcmdat
