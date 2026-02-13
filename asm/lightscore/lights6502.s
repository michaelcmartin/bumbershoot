;;; ----------------------------------------------------------------------
;;;   Generic Lights-Out Core for 6502 processors
;;;   For use with the Ophis assembler
;;;
;;;   Copyright 2026 Michael C. Martin. Available under 2-clause BSD
;;;      license.
;;;
;;;   Configure your origins for both .text and .data segments before
;;;   including this file. Twelve bytes of space in the .data segment
;;;   will be allocated.
;;;
;;;   Exported functions: (all functions trash .AXY)
;;;   - new_puzzle: Randomizes the board.
;;;   - move: Makes a move, specified by a value 0-24 in .A.
;;;   - movexy: Makes a move, specified by values 0-4 in .X and .Y.
;;;   - won_game: Zero flag is set on return if the puzzle is solved.
;;;
;;;   Exported value:
;;;   - board: a 5-byte array representing board state. One byte per row,
;;;            top to bottom, low five bits represent the cell in each
;;;            column (1 if lit, least significant bit on the left).
;;;
;;;   Imported function:
;;;   - rnd: Randomizer function that generates a 16-bit random value.
;;;
;;;   Imported value:
;;;   - rndval: 16-bit random value updated by the rnd function.
;;; ----------------------------------------------------------------------

.scope
        .data
        .org    ^+1                     ; Buffer for board
        .space  board   6               ; 5 byte board plus 1-byte buffer
        .space  _scratch 5              ; workspace for routines

        .text
;;; MOVE: Makes a move on the Lights-Out board.
;;;       Input: 0-24 in .A.
;;;       Trashes: .AXY
move:   ldx     #$00
        ldy     #$00
        sec
*       sbc     #$05
        bcc     +
        iny                             ; Doesn't update carry
        bcs     -
*       adc     #$05
        tax
        ;; Fall through to MOVEXY

;;; MOVEXY: Makes a move on the Lights-out board.
;;;         Input: column (0-4) in .X, row (0-4) in .Y.
;;;         Trashes: .AXY
movexy: lda     _flips,x
        eor     board-1,y
        sta     board-1,y
        lda     _flips+5,x
        eor     board,y
        sta     board,y
        lda     _flips,x
        eor     board+1,y
        sta     board+1,y
        rts
_flips: .byte   1,2,4,8,16
        .byte   3,7,14,28,24

;;; WON_GAME: Zero flag set if game is won.
;;;           Trashes: .AX
won_game:
        ldx     #$04
        lda     #$00
*       ora     board,x
        dex
        bpl     -
        ora     #$00
        rts

;;; NEW_PUZZLE: Randomizes the board.
;;;             Trashes: .AXY, entire _scratch region.
new_puzzle:
        lda     #$00
        ldx     #$04
*       sta     board,x
        dex
        bpl     -
        jsr     rnd
        lda     rndval
        sta     _scratch
        lda     rndval+1
        sta     _scratch+1
        jsr     rnd
        lda     rndval
        sta     _scratch+2
        lda     rndval
        sta     _scratch+3
        lda     #24
        sta     _scratch+4
*       lsr     _scratch+3
        ror     _scratch+2
        ror     _scratch+1
        ror     _scratch
        bcc     +
        lda     _scratch+4
        jsr     move
*       dec     _scratch+4
        bpl     --
        rts
.scend
