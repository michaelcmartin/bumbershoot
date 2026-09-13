	org	$8100
	map	bss_start

	ld	a,$0f			; White on Blue
	call	clrto

	ld	hl,menu
	call	print

1	call	getkey
	sub	$31			; Subtract ord('1') for 0-5
	cp	7			; Check if out of range
	jr	nc,1B
	call	vector
	jr	1B

exit:	pop	hl			; Return to toplevel
	ld	a,$38			; Black on white
	;; Fall through to CLRTO

clrto:	ld	(iy+83),a
	and	$38
	ld	(iy+14),a
	rrca
	rrca
	rrca
	out	($fe),a
	xor	a
	ld	(iy+84),a
	ld	(iy+87),a
	call	$0d6b			; CLS
	ld	a,2
	jp	$1601			; CHAN-OPEN

print:	ld	a,(hl)
	inc	hl
	inc	a
	ret	z
	dec	a
	rst	$10
	jr	print

getkey:	res	5,(iy+1)
1	halt
	bit	5,(iy+1)
	jr	z,1B
	ld	a,(iy-50)
	res	5,(iy+1)
	ret

vector:	add	a
	ld	e,a
	ld	d,0
	ld	hl,choices
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)

menu:	db	$16,0,2,"BEEPING WITH THE BUMBERSHOOT",13,13,13,13,13
	db	13,"     1. SIMPLE SCALE"
	db	13,"     2. ARPEGGIO CHORDS"
	db	13,"     3. CHANNEL-SUM CHORDS"
	db	13,"     4. INTERLEAVED CHORDS"
	db	13,"     5. 1-BIT PCM"
	db	13,"     6. 3-BIT PCM WITH PWM"
	db	13,"     7. EXIT PROGRAM"
	db	$16,16,7,"YOUR CHOICE (1-7)?",255
choices:
	dw	tech0,tech1,tech2,tech3,tech4,tech5,exit

	;; Technique 1: Scale with custom player

tech0:	ld	b,8
	ld	hl,scale
	di
	ld	a,1
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
	ei
	ret

	;; Technique 2: Frame-level arpeggio
macro	play1	3
	ld	hl,@1
	ld	de,@2
	ld	bc,@3
	call	chord1
endmacro

tech1:	play1	$0367,$0441,$051a	; I
	play1	$0367,$048b,$05ba	; IV
	play1	$0367,$0441,$051a	; I
	play1	$0336,$03d2,$051a	; V
	play1	$0367,$0441,$051a	; I
	ret

chord1:	ld	(.f1),hl
	ld	(.f2),de
	ld	(.f3),bc
	ld	a,($5c48)		; BORDCR
	and	$38
	rrca
	rrca
	rrca
	or	$08
	di
	ld	b,$18
	ld	hl,0
1	push	bc
	ld	bc,$0d0
.f1	equ	$+1
	ld	de,$0000
	call	sound
	ld	bc,$0d0
.f2	equ	$+1
	ld	de,$0000
	call	sound
	ld	bc,$0d0
.f3	equ	$+1
	ld	de,$0000
	call	sound
	pop	bc
	djnz	1B
	ei
	ret

sound:
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
	ret
2	nop				; + 4 = 25
	nop				; + 4 = 29
	jp	1B			; +10 = 39
5	nop				; + 4 = 25
	nop				; + 4 = 29
	jp	4B			; +10 = 39
.scratch # 1

scale:	dw	$0367,$03d2,$044a,$048b,$051a,$05ba,$066e,$06cf


;;; Technique 3: Channel-summed chords
;; Notes:
;;   B      C    D     E     F     G     A
;; $061b $0678 $0743 $0826 $08a2 $09b1 $0ae1

macro	play2	4
	ld	hl,@2
	ld	(freq1),hl
	ld	hl,@3
	ld	(freq2),hl
	ld	hl,@4
	ld	(freq3),hl
	ld	bc,@1
	call	chord2
endmacro

tech2:	play2	$2000,$0678,$0826,$09b1	; I
	play2	$2000,$0678,$08a2,$0ae1	; IV
	play2	$2000,$0678,$0826,$09b1	; I
	play2	$2000,$061b,$0743,$09b1	; V
	play2	$4000,$0678,$0826,$09b1	; I
	ret

	;; count_channel: 91 cycles
macro	count_channel	count,freq
	ld	hl,(count)		; +16
	ld	de,(freq)		; +20
	add	hl,de			; +11
	bit	7,h			; + 8
	jp	m,1F			; +10
	jp	2F			;     +10
1	inc	a			;           + 4
	dec	de			;           + 6
2	ld	(count),hl		; +16
endmacro

freq1 # 2
freq2 # 2
freq3 # 2
counter1 # 2
counter2 # 2
counter3 # 2
chord2:	ld	hl,0
	ld	(counter1),hl
	ld	(counter2),hl
	ld	(counter3),hl
	di
	;; 338 cycles per loop:
.lp:	xor	a			; + 4
	count_channel counter1,freq1	; +91
	count_channel counter2,freq2	; +91
	count_channel counter3,freq3	; +91
	add	a			; + 4
	add	a			; + 4
	add	a			; + 4
	and	$10			; + 7
	or	$09			; + 7
	out	($fe),a			; +11
	dec	bc			; + 6
	ld	a,b			; + 4
	or	c			; + 4
	jp	nz,.lp			; +10
	ei
	ret

;;; Technique 4: Sample-interleaved chords
;;;   (Reuses the scratch space from previous technique)
macro	play3	4
	ld	hl,@2
	ld	(freq1),hl
	ld	hl,@3
	ld	(freq2),hl
	ld	hl,@4
	ld	(freq3),hl
	ld	bc,@1
	call	chord3
endmacro

;;;   A     B     C     D     E     F     G     A
;;; $0134 $015a $016f $019c $01ce $01ea $0226 $0269

tech3:	play3	$5000,$016f,$01ce,$0226	; I
	play3	$5000,$016f,$01ea,$0269	; IV
	play3	$5000,$016f,$01ce,$0226	; I
	play3	$5000,$015a,$019c,$0226	; V
	play3	$a000,$016f,$01ce,$0226	; I
	ret

	;; proc_channel: 140 cycles. With interleaved
	;; JP instructions to handle the Z flag on
	;; counter exit, 150 cycles between entries
	;; signal flips at 0x8000 instead of 0x10000
macro	count_channel2	count,freq
	ld	hl,(count)		; +16
	ld	de,(freq)		; +20
	add	hl,de			; +11
	add	hl,de			; +11
	add	hl,de			; +11
	ld	a,h			; + 4
	rrca				; + 4
	rrca				; + 4
	rrca				; + 4
	and	$10			; + 7
	or	$01			; + 7
	out	($fe),a			; +11
	ld	(count),hl		; +16
	dec	bc			; + 6
	ld	a,b			; + 4
	or	c			; + 4
endmacro

chord3:	ld	hl,0
	ld	(counter1),hl
	ld	(counter2),hl
	ld	(counter3),hl
	di
.lp:	count_channel2 counter1, freq1
	jp	z,.end
	count_channel2 counter2, freq2
	jp	z,.end
	count_channel2 counter3, freq3
	jp	nz,.lp
.end:	ei
	ret

;;; Technique 5: 1-bit PCM playback

tech4:	ld	hl,pcmdat
	ld	de,pcmlen
	di
	;; We enter .lp at the 24-cycle count
.lp:	ld	a,(hl)			; +  7 ( 31)
	inc	hl			; +  6 ( 37)
	rrca				; +  4 ( 41)
	rrca				; +  4 ( 45)
	rrca				; +  4 ( 49)
	ld	c,a			; +  4 ( 53)
	and	$10			; +  7 ( 60)
	or	$01			; +  7 ( 67)
	;; Delay 141 cycles with a no-op sequence...
	inc	hl			; +  6 ( 73)
	dec	hl			; +  6 ( 79)
	ld	b,9			; +  7 ( 86)
	jp	1F			; + 10 ( 96)
1	djnz	1B			; +112 (208)
	out	($fe),a			; + 11 (219)

	repeat	7
	rlc	c			; +  8 (  8)
	ld	c,a			; +  4 ( 12)
	and	$10			; +  7 ( 19)
	or	$01			; +  7 ( 26)
	;; Delay 182 cycles with a no-op sequence...
	ld	b,1			; +  7 ( 33)
	dec	b			; +  4 ( 37)
	ld	b,13			; +  7 ( 44)
1	djnz	1B			; +164 (208)
	out	($fe),a			; + 11 (219)
	endrepeat

	dec	de			; +  6 (  6)
	ld	a,d			; +  4 ( 10)
	or	e			; +  4 ( 14)
	jp	nz,.lp			; + 10 ( 24)
	ei
	ret

;;; Technique 6: Pulse-Width modulated digital sound
;;;   16 kHz playback from an 8kHz sample, each sample
;;;   doubled in-place
tech5:	ld	hl,pcmdat2
	ld	bc,pcmlen2

	di
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
.step:	;; Enter .step on cycle 307
	ld	b,0			; + 7 (314)
	ld	b,0			; + 7 (321)
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
	ld	a,$11			; + 7 (423)
	jp	(hl)			; + 4 (427)
	;; Align jump table so address computations can all
	;; be 8-bit math
	align	32
	;; The sample turns out to be kind of soft, so we
	;; do some volume compression along the way
.table: dw	.s0,.s0,.s0,.s0
	dw	.s0,.s0,.s3,.s6
	dw	.s9,.s12,.s15,.s15
	dw	.s15,.s15,.s15,.s15

	;; Enter macro on cycle 427, leave on cycle 307
	macro	pcmstep i
	out	($fe),a			; + 11 (438)
	xor	$10			; +  7 (  7)
	repeat	i
	nop				; 4*i
	endrepeat
	out	($fe),a			; 11
	repeat	15-i			; 60-4*i
	nop
	endrepeat			; + 71 ( 78)
	ld	b,9			; +  7 ( 85)
1	djnz	1B			; +112 (197)
	nop				; +  4 (201)
	xor	$10			; +  7 (208)
	out	($fe),a			; + 11 (219)
	xor	$10			; +  7 (226)
	repeat	i
	nop
	endrepeat
	out	($fe),a
	repeat	15-i
	nop
	endrepeat			; + 71 (297)
	jp	.step			; + 10 (307)
	endmacro

.s0:	pcmstep 0
.s3:	pcmstep 3
.s6:	pcmstep 6
.s9:	pcmstep 9
.s12:	pcmstep 12
.s15:	pcmstep 15

pcmdat	incbin	"sample.dat"
pcmlen	equ	$-pcmdat

pcmdat2	incbin	"wow_pcm.dat"
pcmlen2	equ	$-pcmdat2

bss_start:
