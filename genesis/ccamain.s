	seg	data
CurBuf: ds	4

	seg	text
CCAInit:
	move.l	#CCA_buf_0,CurBuf
	move.w	#0,mirror_ready		; Also clears reset_requested
	;; Fall through to CCAReset

CCAReset:
	movem.l	d2/a2-a3,-(sp)
	movea.l	CurBuf,a2
	lea	rnd(pc),a3
	move.w	#(CCA_buf_size/2-1),d2
.lp:	jsr	(a3)
	move.w	d0,(a2)+
	dbra	d2,.lp
	;; A reset has happened. Don't allow new reset requests until
	;; START has been released for at least one frame.
	move.b	#2,reset_requested
	movem.l	(sp)+,d2/a2-a3
	;; Fall through to CCARender

CCARender:
	move.b	mirror_ready,d0
	bne	CCARender
	move.l	d2,-(sp)
	movea.l	CurBuf,a0
	lea	CCA_vram_mirror,a1
	moveq	#(CCA_height/2-1),d0	; Pairs of rows
.rows:	moveq	#(CCA_row_bytes-1),d1	; One two-cell byte becomes one nametable word
.cols:	;; Bottom row first
	move.w	#$1000,d2		; v-flip on
	move.b	CCA_row_bytes(a0),d2
	move.w	d2,CCA_vram_size(a1)
	;; Then top row, advancing our pointers
	moveq	#$0,d2
	move.b	(a0)+,d2
	move.w	d2,(a1)+
	dbra	d1,.cols
	;; Skip the row we just dealt with
	add.w	#CCA_row_bytes,a0
	dbra	d0,.rows
	;; Clean up, we're done
	move.b	#2,mirror_ready
	move.l	(sp)+,d2
	rts

	list macro

	;; SWARCMPNE PSEUDO-INSTRUCTION
	;; For each lane, if any bits in that lane differ between srca and srcb,
	;; the top bit of that lane in dest is set, otherwise it is cleared
	;; The other bits in dest are garbage
	;; mask delineates the lanes, i.e. $77777777 for a vector of nybbles
	;; srca is preserved, srcb is clobbered
	macro swarcmpne mask, srca, srcb, dest
	eor.l	srca,srcb
	move.l	srcb,dest
	and.l	mask,dest
	add.l	mask,dest
	or.l	srcb,dest
	endm

	;; UPDATE EIGHT CELLS
	;; west is offset to west neighbor after postincrement (-5, except at west edge)
	;; east is offset to east neighbor after postincrement (0, except at east edge)
	;; a1 points to source buffer
	;; a2 points to destination buffer
	;; a3 points to north neighbor row (a1 - CCA_row_bytes, except at north edge)
	;; a4 points to south neighbor row (a1 + CCA_row_bytes, except at south edge)
	;; a5 is reserved for an outer loop end condition
	;; a6 must contain #$11111111 (vector of 1s added to cells to get target values)
	;; d0 and d1 are scratch
	;; d2 is reserved for an inner loop counter
	;; d3 holds eight initial cell values
	;; d4 holds eight target cell values
	;; d5 accumulates a bitmask of cells that *don't* match any adjacent cells
	;; d6 must contain #$77777777 (lane-delineating mask used in SWAR operations)
	;; d7 must contain #$88888888 (lane-delineating mask used in SWAR operations)

	macro updateeight west, east
	;; get initial values and do SWAR addition to get target values
	move.l	(a1)+,d3	; d3 = initial cell values
	move.l	d3,d4
	and.l	d6,d4		; (andi.l #$77777777,d4)
	add.l	a6,d4		; (addi.l #$11111111,d4)
	move.l	d3,d0
	and.l	d7,d0		; (andi.l #$88888888,d0)
	eor.l	d0,d4		; d4 = target cell values
	;; compare with north neighbors
	move.l	(a3)+,d0
	swarcmpne d6, d4, d0, d5
	;; compare with south neighbors
	move.l	(a4)+,d0
	swarcmpne d6, d4, d0, d1
	and.l	d1,d5
	;; compare with west neighbors
	moveq	#$F0,d0		; sign extends to $FFFFFFF0
	and.l	d3,d0		; abcdefgh -> abcdefg0
	moveq	#$0F,d1
	and.b	west(a1),d1	; 0L
	or.l	d1,d0		; abcdefg0 -> abcdefgL
	ror.l	#4,d0		; abcdefgL -> Labcdefg
	swarcmpne d6, d4, d0, d1
	and.l	d1,d5
	;; compare with east neighbors
	;; the east byte is the high byte of a longword, so the initial cells
	;; and the new byte have to shift in opposite directions
	move.l	d3,d0
	lsl.l	#4,d0		; abcdefgh -> bcdefgh0
	moveq	#0,d1
	move.b	east(a1),d1	; R_
	lsr.b	#4,d1		; 0R
	or.l	d1,d0		; bcdefgh0 -> bcdefghR
	swarcmpne d6, d4, d0, d1
	and.l	d1,d5
	;; make writeback mask (1111 = no match, keep d3; 0000 = match, keep d4)
	;; mask out garbage bits, then multiply by 15 / 8 without overflowing
	and.l	d7,d5		; (andi.l #$88888888,d5)
	move.l	d5,d0
	move.l	d5,d1		; d0 = d1 = d5 = 8 * mask
	lsr.l	#3,d0		; d0 = 1 * mask
	sub.l	d0,d5		; d5 -= 1 * mask
	add.l	d1,d5		; d5 += 8 * mask
	;; ((d3 ^ d4) & d5) ^ d4 = (d3 & d5) | (d4 & ~d5)
	eor.l	d4,d3
	and.l	d5,d3
	eor.l	d4,d3
	move.l	d3,(a2)+
	endm

lastrow  equ CCA_buf_size-CCA_row_bytes
edgewest equ CCA_row_bytes-5
edgeeast equ -CCA_row_bytes

CCAStep:
	;; Before anything else, check if we should reset instead
	move.b	reset_requested,d0
	btst	#0,d0
	bne	CCAReset

	movem.l	d2-d7/a2-a6,-(sp)
	movea.l	#$11111111,a6
	move.l	#$77777777,d6
	move.l	d6,d7
	not.l	d7
	movea.l	CurBuf,a0		; Source buffer
	movea.l a0,a1
	move.l	a0,d0
	eor.w	#CCA_buf_xor,d0		; Opposite buffer
	movea.l	d0,a2			; ...is the destination buffer
	move.l	d0,CurBuf		; ...and also the next source buffer
	lea	lastrow(a0),a3		; north neighbor (wrap)
	lea	CCA_row_bytes(a0),a4	; south neighbor
	movea.l	a4,a5			; stop at the second row
	bsr.s	updaterows
	;; a1 now points to the second row
	;; a3 now points to the end of the buffer
	;; a4 now points to the third row
	movea.l a0,a3			; reset north neighbor
	lea	lastrow(a0),a5		; stop at the last row
	bsr.s	updaterows
	;; a1 now points to the last row
	;; a3 now points to the second last row
	;; a4 now points to the end of the buffer
	movea.l	a4,a5			; stop at the end of the buffer
	movea.l	a0,a4			; reset south neighbor (wrap)
	bsr.s	updaterows
	movem.l	(sp)+,d2-d7/a2-a6
	rts

	;; Does not preserve registers! Only to be called from CCAStep!
	;; This routine is a whole lot bigger than it looks--so big that
	;; the outer loop bne doesn't fit in a short branch
updaterows:
	updateeight edgewest, 0
	moveq	#(CCA_row_longs-3),d2
.cols	updateeight -5, 0
	dbra	d2,.cols
	updateeight -5, edgeeast
	cmpa.l	a1,a5
	bne	updaterows
	rts
