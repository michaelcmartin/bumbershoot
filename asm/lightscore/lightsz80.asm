;;; ----------------------------------------------------------------------
;;;   Generic Lights-Out Core for Z80 processors
;;;   For use with the Sjasm assembler
;;;
;;;   Copyright 2026 Michael C. Martin. Available under 2-clause BSD
;;;      license.
;;;
;;;   Configure your ORG and your MAP before including this file. Seven
;;;   bytes of space in the map will be allocated. Called function may
;;;   use up to 16 bytes of stack.
;;;
;;;   Exported functions: (all functions trash ABCDEHL unless noted.)
;;;   - new_puzzle: Randomizes the board.
;;;   - move: Makes a move, specified by a value 0-24 in A.
;;;   - movexy: Makes a move, specified by values 0-4 in A (column) and
;;;             B (row).
;;;   - won_game: Zero flag is set on return if the puzzle is solved.
;;;               Only trashes ABHL.
;;;
;;;   Exported value:
;;;   - board: a 5-byte array representing board state. One byte per row,
;;;            top to bottom, low five bits represent the cell in each
;;;            column (1 if lit, least significant bit on the left).
;;;
;;;   Imported function:
;;;   - rnd: Randomizer function that generates a 16-bit random value and
;;;          returns it in HL.
;;; ----------------------------------------------------------------------

lightsout_scratch	# 1
board	# 5
.dummy	# 1

;;; NEW_PUZZLE: Randomizes the board state.
;;;             Trashes ABCDEHL.
new_puzzle:
	ld	b,5
	ld	hl,board
	xor	a
1	ld	(hl),a
	inc	hl
	djnz	1B
	call	rnd
	push	hl
	call	rnd
	pop	de
	ld	b,25
1	add	hl,hl
	rl	e
	rl	d
	jr	nc,2F
	push	bc
	push	de
	push	hl
	ld	a,b
	dec	a
	call	move
	pop	hl
	pop	de
	pop	bc
2	djnz	1B
	ret

;;; MOVE: Make the move at location 0-24, as provided in A. Divides by
;;;       5 so that A and B hold column and row 0-4, then falls through
;;;       to MOVEXY. Trashes ABCDEHL.
move:	ld	b,0
1	sub	5
	jr	c,2F
	inc	b
	jr	1B
2	add	5
	;; FALL THROUGH to MOVEXY, below

;;; MOVEXY: Make the move at column A, row B, both 0-4.
;;;         Trashes ABCDEHL.
movexy:	ld	hl,.flips
	ld	de,board-1
	add	l
	jr	nc,1F
	inc	h
1	ld	l,a
	ld	a,e
	add	b
	jr	nc,1F
	inc	d
1	ld	e,a
	ld	a,(de)
	xor	(hl)
	ld	(de),a
	inc	de
	inc	de
	ld	a,(de)
	xor	(hl)
	ld	(de),a
	dec	de
	ld	bc,5
	add	hl,bc
	ld	a,(de)
	xor	(hl)
	ld	(de),a
	ret
.flips:	defb	1,2,4,8,16
	defb	3,7,14,28,24

;;; WON_GAME: Zero flag is set if game is won. Trashes ABHL.
won_game:
	ld	hl,board
	xor	a
	ld	b,5
1	or	(hl)
	ret	nz
	inc	hl
	djnz	1B
	ret
