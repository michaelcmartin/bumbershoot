	org	$7000

macro	AY	index,val:(hl)
	ld	a,index
	ld	d,val
	call	ayreg
endmacro

	;; Initialize AY-3 voice
	AY	$0b,$10			; Envelope length: 1sec
	AY	$0c,$1b
	AY	$08,$10			; Use envelope on channel A

	ld	b,8
	ld	hl,scale
1	push	bc
	AY	$00			; Read frequency from (HL) table
	inc	hl			; And advance pointer as we go
	AY	$01
	inc	hl
	AY	$0d,$09			; Start a decaying envelope
	AY	$07,$fe			; Enable Channel A
	call	pause
	pop	bc
	djnz	1B

	AY	$07,$ff			; Disable channel A
	ret

ayreg:	ld	bc,$fffd		; AY-3 Index
	out	(c),a
	ld	b,$bf			; AY-3 Value
	ld	a,d
	out	(c),a
	ret

pause:	push	af
	push	hl
	ld	hl,$5c78		; FRAMES
	ld	a,(hl)
	add	25
1	halt
	cp	(hl)
	jr	nz,1B
	pop	hl
	pop	af
	ret

;;; [hex(int(3546900 / (32 * f))) for f in freqs]
scale:	dw	$01a7,$0179,$0150,$013d,$011a,$00fb,$00e0,$00d3
