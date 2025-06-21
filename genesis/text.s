;;; ------------------------------------------------------------------
;;; Text display routines for Sega Genesis.
;;;
;;; The font used lives in $A000-$A7FF of VRAM and is 64 characters in
;;; ASCII order, codes 32-95.
;;;
;;; These functions use the standard 68000 calling convention:
;;; arguments are pushed onto the stack right-to-left, a0-1/d0-1 are
;;; scratch registers, and return values if any are in d0.
;;; ------------------------------------------------------------------

	;; Mode values for VRAM access
VRAM_READ	EQU	0
VRAM_WRITE	EQU	1
CRAM_WRITE	EQU	3
VSRAM_READ	EQU	4
VSRAM_WRITE	EQU	5
CRAM_READ	EQU	8

	seg text

	;; Useful constants for these routines

VRAM_DATA:
	dc.l	$C00000
VRAM_CONTROL:
	dc.l	$C00004

;;; void SetVRAMPtr(short mode, short addr)
;;;   1st: [CD1-0|A13-0]  2nd: [0*8|CD5-2|0|0|A15-14]
SetVRAMPtr:
	move.l	4(a7),d0
	lsl.l	#2,d0
	swap	d0
	move.w	d0,d1
	andi.w	#$00F3,d1	; d1 holds the second write value now
	;; D0 is [A13-0|0*2][0*8|CD5-0|A15-14]
	lsr.w	#2,d0
	ror.l	#2,d0
	swap	d0		; d0 holds the first write value now
	movea.l	VRAM_CONTROL(pc),a0
	move.w	d0,(a0)
	move.w	d1,(a0)
	rts

;;; void LoadFont(char *font)
;;;   Loads the font into VRAM $A000-$A7FF. This is an 8-bit
;;;   monochrome font of 64 characters, so the source array must be
;;;   512 bytes long.
LoadFont:
	move.l	#((VRAM_WRITE << 16) | $A000),-(sp)
	bsr.s	SetVRAMPtr
	addq.l	#4,sp
	movea.l	VRAM_DATA(pc),a0
	movea.l	4(sp),a1
	movem.l	d2-d3,-(sp)
	move.w	#$1ff,d0
.lp:	move.b	(a1)+,d1
	moveq	#7,d2
.lp2:	asl.l	#4,d3
	asl.b	#1,d1
	bcc.s	.nobit
	ori.b	#1,d3
.nobit: dbra	d2,.lp2
	move.l	d3,(a0)
	dbra	d0,.lp
	movem.l	(a7)+,d2-d3
	rts

;;; char *WriteStr(short target, short palette, char *str)
;;;   - Returns the word-aligned address just past the string you wrote.
WriteStr:
	move.w	4(sp),d0
	move.w	d0,-(sp)
	move.w	#VRAM_WRITE,-(sp)
	bsr.s	SetVRAMPtr
	addq.l	#4,sp
	move.w	6(sp),d0
	andi.b	#3,d0
	lsl.w	#8,d0
	lsl.w	#5,d0
	movea.l	VRAM_DATA(pc),a0
	move.l	8(sp),a1
.lp:	move.b	(a1)+,d0
	beq.s	.done
	add.w	#$4e0,d0
	move.w	d0,(a0)
	andi.w	#$6000,d0
	bra.s	.lp
.done:	move.l	a1,d0
	addq.l	#1,d0
	andi.b	#$fe,d0
	rts
