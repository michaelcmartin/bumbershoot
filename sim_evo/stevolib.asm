;;; ----------------------------------------------------------------------
;;;              SIMULATED EVOLUTION: ATARI ST SUPPORT LIBRARY
;;;
;;;  This library provides routines for the Atari ST port of Simulated
;;;  Evolution that are impossible or inconvenient to provide in C.
;;;
;;;  It is designed to be built with VASM, and it is compatible with the
;;;  vbccm68ks ABI (16-bit ints).
;;;
;;;  See STEVOLIB.H for usage information for the functions themselves.
;;;  See SIMEVOST.C for more information about the Atari ST port.
;;;  See SIMEVO.H for authorship, provenance, and copyright information.
;;; ----------------------------------------------------------------------
	text

	;; Exports
	public	_init_line_a
	public	_fill_box
	public	_seed_random
	public	_random
	public	_get_ticks

;;; void init_line_a(void)
;;; Initializes the graphics system. This should be called once, at
;;; program start, before any calls to fill_box.
_init_line_a:
	movem.l	a2/d2,-(sp)
	dc.w	$a000			; Line-A: INIT
	move.l	a0,a_line_vars
	movem.l	(sp)+,a2/d2
	rts

;;; void fill_box(short x1, short y1, short x2, short y2, short color)
;;; Draws a filled rectangle with the specified upper-left and
;;; lower-right corners, in the specified color.
;;; If drawing is incorrect or corrupted, make sure that your C
;;; compiler is using 16-bit ints. The "default" configuration of VBCC
;;; for TOS does not do this!
_fill_box:
	move.l	a_line_vars,a0
	clr.w	d0
	move.w	d0,$24(a0)		; Write mode replace
	move.w	d0,$32(a0)		; Pattern length 1
	move.w	d0,$34(a0)		; Single plane fill pattern
	move.w	d0,$36(a0)		; Clipping off
	move.l	#pattern,$2e(a0)	; Fill pattern array

	move.l	4(sp),$26(a0)		; Start coordinate (X1, Y1)
	move.l	8(sp),$2a(a0)		; End coordinate (X2, Y2)
	move.w	12(sp),d0		; Load "proper" color code
	movem.l	a2/d2,-(sp)
	moveq	#3,d2			; Turn color into bitplanes
	add.w	#$18,a0			; Move pointer to COLBIT0
.lp:	clr.w	d1
	move.w	d0,(a0)
	and.w	#$01,(a0)+
	lsr.w	#1,d0
	dbra.s	d2,.lp
	dc.w	$a005			; Line-A: FILLRECT
	movem.l	(sp)+,a2/d2
	rts

;;; void seed_random(unsigned long seed)
;;; Seeds the PRNG. The Atari ST edition uses the same 64-bit Xorshift-
;;; star PRNG as the modern Linux and Windows ports.
_seed_random:
	lea.l	rng_state,a0
	move.l	4(sp),d0
	or.l	#1,d0
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	rts

;;; unsigned long random(void)
;;; Returns a random 32-bit integer. The Atari ST edition uses the
;;; same 64-bit Xorshift-star PRNG as the modern Linux and Windows
;;; ports. All 32 bits in the return value are random enough to
;;; rely on, so using bitmask or modulus operators to limit the
;;; result is safe.
_random:
	lea.l	rng_state,a0
	movem.l	(a0),d0-d1
	movem.l	d2-d6,-(sp)

	;; rng_state = rng_state ^ (rng_state >> 12)
	moveq	#12,d3
	moveq	#20,d4
	move.l	d1,d2
	lsr.l	d3,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsl.l	d4,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsr.l	d3,d2
	eor.l	d2,d0

	;; rng_state = rng_state ^ (rng_state << 25)
	moveq	#25,d3
	move.l	d0,d2
	lsl.l	d3,d2
	eor.l	d2,d0
	move.l	d1,d2
	lsr.l	#7,d2
	eor.l	d2,d0
	move.l	d1,d2
	lsl.l	d3,d2
	eor.l	d2,d1

	;; rng_state = rng_state ^ (rng_state >> 27)
	moveq	#27,d3
	move.l	d1,d2
	lsr.l	d3,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsl.l	#5,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsr.l	d3,d2
	eor.l	d2,d0

	movem.l	d0-d1,(a0)

	;; Return the high 32 bits of the 64-bit product of the RNG
	;; state and the constant $2545F4914F6CDD1D
	move.l	#$2545F491,d2
	move.l	#$4F6CDD1D,d3
	clr.l	d4
	clr.l	d5
	moveq	#63,d6
.m64:	lsr.l	d0
	roxr.l	d1
	bcc.s	.m64_next
	add.l	d3,d5
	addx.l	d2,d4
.m64_next:
	lsl.l	d3
	roxl.l	d2
	dbra	d6,.m64
	move.l	d4,d0			; High dword of product as retval

	;; Restore all the registers and exit
	movem.l	(sp)+,d2-d6
	rts

;;; unsigned long get_ticks(void)
;;; Returns the number of ticks on the 200Hz system clock since
;;; power on. This function must be called from user mode.
_get_ticks:
	movem.l	a2/d2-3,-(sp)
	clr.l	-(sp)			; Enter supervisor mode
	move.w	#32,-(sp)
	trap	#1
	move.l	$04ba,d3		; Collect hz_200 value
	move.l	d0,2(sp)		; Leave supervisor mode
	move.w	#32,(sp)
	trap	#1
	addq.l	#6,sp
	move.l	d3,d0
	movem.l	(sp)+,a2/d2-3
	rts

	data
pattern:
	dc.w	$ffff			; Fill pattern for fill_box

rng_state:
	dc.w	0,1,0,1			; Current RNG state value

	bss
a_line_vars:
	ds.l	1			; Pointer to line-A parameter block
