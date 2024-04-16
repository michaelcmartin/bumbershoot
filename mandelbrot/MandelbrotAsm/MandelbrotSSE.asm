;;; *********************************************************************
;;; MANDELBROT SET GENERATOR
;;; Vectorized SSE2 x86_64 floating-point implementation
;;; (c) 2024, Michael C. Martin
;;; Made available under the MIT License; see README.md
;;; *********************************************************************

	_text	SEGMENT

mandelbrotSSE	PROC FRAME
	push	rdi
	.PUSHREG rdi
	push	rsi
	.PUSHREG rsi
	sub	rsp, 104
	.ALLOCSTACK 104
	movdqa	[rsp], xmm6
	.SAVEXMM128 xmm6, 0
	movdqa	[rsp+16], xmm7
	.SAVEXMM128 xmm7, 16
	movdqa	[rsp+32], xmm8
	.SAVEXMM128 xmm8, 32
	movdqa	[rsp+48], xmm9
	.SAVEXMM128 xmm9, 48
	movdqa	[rsp+64], xmm10
	.SAVEXMM128 xmm10, 64
	movdqa	[rsp+80], xmm11
	.SAVEXMM128 xmm11, 80
	.ENDPROLOG
	;; Juggle arguments so that they look like we used the Linux ABI internally
	mov	edi, r9d
	mov	rsi, [rsp+160]

	;; Quit immediately if edge is nonpositive or vals is null.
	test	edi,edi
	jle	finis
	test	rsi,rsi
	jz	finis

	;; Set up constants we'll use in the main loop. Rarely used constants
	;; are put into xmm8+ since instructions using those are longer.
	movsd	xmm8,four		; xmm8 = {4.0, 4.0}
	movapd	xmm9,xmm0		; xmm9 = xmin
	movapd	xmm10,xmm1		; xmm10 = ymax
	cvtsi2sd	xmm11,edi	; xmm11 = step (width / edge)
	divsd	xmm2,xmm11
	movapd	xmm11,xmm2
	unpcklpd	xmm8,xmm8	; Replicate constants to both
	unpcklpd	xmm9,xmm9	; halves of the XMM registers
	unpcklpd	xmm10,xmm10
	unpcklpd	xmm11,xmm11
	;; At this point xmm0-7 are all free for use in the inner loop.

	;; Row and column iterators. Set up row or point-specific constants.
	xor	r8d,r8d			; Row iterator
rows:	neg	r8d
	cvtsi2sd	xmm1,r8d	; y = (-iy * step) + ymax
	neg	r8d
	mulsd	xmm1,xmm11
	addsd	xmm1,xmm10
	unpcklpd	xmm1,xmm1	; Both pixels have identical y

	xor	r9d,r9d			; Column iterator
cols:	inc	r9d
	cvtsi2sd	xmm0,r9d	; x = (ix * step) + xmin
	unpcklpd	xmm0,xmm0	; high double uses ix+1 here
	dec	r9d
	cvtsi2sd	xmm0,r9d
	mulpd	xmm0,xmm11
	addpd	xmm0,xmm9

	;; Apply Z = Z*Z+C until |Z|>4 or 1000 iterations
	xor	edx,edx			; Clear iteration count
	pxor	xmm2,xmm2		; Start at 0 + 0i
	pxor	xmm3,xmm3
	pxor	xmm7,xmm7		; Start at 0 count
do_pt:	movapd	xmm4,xmm2		; store squares of Z's
	movapd	xmm5,xmm3		; components
	mulpd	xmm4,xmm2
	mulpd	xmm5,xmm3
	movapd	xmm6,xmm4		; |Z| <= 4?
	addpd	xmm6,xmm5
	cmplepd	xmm6,xmm8
	psubq	xmm7,xmm6		; Contribute true results to sum
	movmskpd	ecx,xmm6	; Were *any* cells incremented?
	test	ecx,ecx
	jz	found
	mulpd	xmm3,xmm2		; b=2ab+y
	subpd	xmm4,xmm5		; a2 = a2-b2+x
	addpd	xmm3,xmm3
	addpd	xmm4,xmm0
	addpd	xmm3,xmm1
	movapd	xmm2,xmm4		; a = a2
	inc	edx
	cmp	edx,1000
	jb	do_pt

	;; Write iteration count into output buffer and increment result
found:	movd	edx,xmm7
	mov	[rsi],dx
	unpckhpd	xmm7,xmm7
	movd	edx,xmm7
	mov	[rsi+2],dx
	add	rsi,4

	;; Wrap up the column and row loops.
	add	r9d,2
	cmp	r9d,edi
	jl	cols
	inc	r8d
	cmp	r8d,edi
	jl	rows

finis:
	movdqa	xmm11, [rsp+80]
	movdqa	xmm10, [rsp+64]
	movdqa	xmm9, [rsp+48]
	movdqa	xmm8, [rsp+32]
	movdqa	xmm7, [rsp+16]
	movdqa	xmm6, [rsp]
	add	rsp, 104
	pop	rsi
	pop	rdi
	ret
mandelbrotSSE	ENDP

	_text	ENDS

	_data	SEGMENT
	align 16
four REAL8 4.0
	_data	ENDS
	END
