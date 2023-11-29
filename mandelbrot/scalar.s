;;; *********************************************************************
;;; MANDELBROT SET GENERATOR
;;; Hand-crafted x86_64 scalar floating-point implementation
;;; (c) 2023, Michael C. Martin
;;; Made available under the MIT License; see README.md
;;; *********************************************************************

	section	.text
	global	mandelbrot
mandelbrot:
	;; Quit immediately if edge is nonpositive or vals is null.
	test	edi,edi
	jle	.end
	test	rsi,rsi
	jz	.end

	;; Set up constants we'll use in the main loop. Rarely used constants
	;; are put into xmm8+ since instructions using those are longer.
	movsd	xmm8,[rel four]		; xmm8 = 4.0
	movapd	xmm9,xmm0		; xmm9 = xmin
	movapd	xmm10,xmm1		; xmm10 = ymax
	cvtsi2sd	xmm11,edi	; xmm11 = step (width / edge)
	divsd	xmm2,xmm11
	movapd	xmm11,xmm2
	;; At this point xmm0-7 are all free for use in the inner loop. For
	;; this scalar implementation, xmm7 is unused, but we'll need it
	;; once we start parallelizing.

	;; Row and column iterators. Set up row or point-specific constants.
	xor	r8d,r8d			; Row iterator
.rows:	neg	r8d
	cvtsi2sd	xmm1,r8d	; y = (-iy * step) + ymax
	neg	r8d
	mulsd	xmm1,xmm11
	addsd	xmm1,xmm10
	xor	ecx,ecx			; Column iterator
.cols:	cvtsi2sd	xmm0,ecx	; x = (ix * step) + xmin
	mulsd	xmm0,xmm11
	addsd	xmm0,xmm9

	;; Apply Z = Z*Z+C until |Z|>4 or 1000 iterations
	xor	edx,edx			; Clear iteration count
	pxor	xmm2,xmm2		; Start at 0 + 0i
	pxor	xmm3,xmm3
.do_pt:	movapd	xmm4,xmm2		; store squares of Z's
	movapd	xmm5,xmm3		; components
	mulsd	xmm4,xmm2
	mulsd	xmm5,xmm3
	movapd	xmm6,xmm4		; |Z| > 4?
	addsd	xmm6,xmm5
	comisd	xmm6,xmm8
	ja	.found
	mulsd	xmm3,xmm2		; b=2ab+y
	subsd	xmm4,xmm5		; a2 = a2-b2+x
	addsd	xmm3,xmm3
	addsd	xmm4,xmm0
	addsd	xmm3,xmm1
	movapd	xmm2,xmm4		; a = a2
	inc	edx
	cmp	edx,1000
	jb	.do_pt

	;; Write iteration count into output buffer and increment result
.found:	mov	[rsi],dx
	add	rsi,2

	;; Wrap up the column and row loops.
	inc	ecx
	cmp	ecx,edi
	jl	.cols
	inc	r8d
	cmp	r8d,edi
	jl	.rows

.end:	ret

	section	.rodata
	align	8
four:	db	0,0,0,0,0,0,0x10,0x40	; 4.0 as a double

	;; gcc/ld gets mad if we don't include this dummy section
	section .note.GNU-stack
