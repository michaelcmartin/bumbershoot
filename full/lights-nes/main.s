        .include "charmap.inc"

        .import __OAM_START__
        .importzp scratch, vstat, j0stat, frames
        .import vidbuf, randomize_board
        .export main
        .exportzp crsr_x, crsr_y, grid

.macro  vflush
        .local lp
        lda     #$80
        sta     vstat
lp:     bit     vstat
        bmi     lp
.endmacro

        .zeropage
crsr_x: .res    1               ; X loc of cursor (0-4)
crsr_y: .res    1               ; Y loc of cursor (0-4)
        .res    1               ; Scratch byte to make moves easier
grid:   .res    5               ; The grid
        .res    1               ; Scratch byte to make moves easier

        .code
main:   ;; Draw the initial screen, except for the board cells
        ldy     #$00
@lp:    ldx     screen_base,y
        beq     @done
        iny
        lda     screen_base+1,y
        sta     $2006
        lda     screen_base,y
        sta     $2006
        iny
        iny
@blk:   lda     screen_base,y
        sta     $2007
        iny
        dex
        bne     @blk
        beq     @lp
@done:  ;; Enable graphics
        lda     #$80
        sta     $2000
        lda     #$0e
        sta     $2001

        ;; Draw the cells one row per frame...
        lda     #<cell_row_tiles
        ldx     #>cell_row_tiles
        jsr     vblit
        vflush
        ;; Change the upper-left tile for mid-board rows
        lda     #$09
        sta     vidbuf+3

        ;; And draw four more copies of it down the screen
        ldx     #$04
:       clc
        lda     vidbuf+1
        adc     #64
        sta     vidbuf+1
        bcc     :+
        inc     vidbuf+2
:       lda     #$80
        sta     vstat
        vflush
        dex
        bne     :--

game_start:
        ;; Nothing to do until player hits START.
        lda     #$10
        and     j0stat
        beq     game_start

        ;; Update status bar.
        lda     #<randomizing_msg
        ldx     #>randomizing_msg
        jsr     vblit
        vflush

        ;; Amount of time from poweron to here determines initial puzzle state.
@scramble:
        jsr     randomize_board
        jsr     grid_to_attr
        ;; If start button is pressed, keep randomizing...
        lda     #$10
        and     j0stat
        bne     @scramble

@scrambled:
        ;; Make sure we didn't actually create a pre-solved puzzle.
        ldx     #$04
:       lda     grid,x
        bne     @puzzle_ok
        dex
        bpl     :-
        ;; Whoops! Try again.
        jsr     randomize_board
        jsr     grid_to_attr
        jmp     @scrambled

        ;; Put the in-game instructions in place.
@puzzle_ok:
        lda     #<instructions
        ldx     #>instructions
        jsr     vblit
        vflush

        ;; No game yet; go back to out-of-game state
        jmp     game_start


;;; --------------------------------------------------------------------------
;;; * GRAPHICS ROUTINES
;;; --------------------------------------------------------------------------

.proc   vblit
        sta     scratch
        stx     scratch+1
        ldy     #$42
lp:     lda     (scratch),y
        sta     vidbuf,y
        dey
        bpl     lp
        rts
.endproc

.proc   next_frame
        pha
        lda     frames
lp:     cmp     frames
        beq     lp
        pla
        rts
.endproc

.proc   grid_to_attr
        row = scratch
        col = scratch+1
        curr = scratch+2

        lda     #<attr_base
        ldx     #>attr_base
        jsr     vblit
        lda     #$04
        sta     row
        ldy     #$00
rowlp:  lda     #$05
        sta     col
        ldx     row
        lda     grid,x
        sta     curr
collp:  lsr     curr
        bcc     next
        ldx     attr_offsets,y
        lda     attr_bit,y
        ora     vidbuf,x
        sta     vidbuf,x
next:   iny
        dec     col
        bne     collp
        dec     row
        bpl     rowlp
        vflush
        rts
.endproc

        .rodata
attr_offsets:
        .byte   17,16,16,15,15,17,16,16,15,15
        .byte   11,10,10,9,9,11,10,10,9,9
        .byte   5,4,4,3,3
attr_bit:
        .byte   $10,$40,$10,$40,$10,$01,$04,$01,$04,$01
        .byte   $10,$40,$10,$40,$10,$01,$04,$01,$04,$01
        .byte   $10,$40,$10,$40,$10
attr_base:
        .byte   3
        .word   $23d3
        .byte   0,0,0
        .byte   3
        .word   $23db
        .byte   0,0,0
        .byte   3
        .word   $23e3
        .byte   0,0,0
        .byte   0

screen_base:
        ;; Palette
        .byte   32
        .word   $3f00
        .byte   $0f,$00,$0f,$10,$0f,$00,$16,$10,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
        .byte   $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

        ;; Logo
        .byte   12
        .word   $208b
        .byte   14,15,16,17,18,19,20,21,22,23,24,25
        .byte   16
        .word   $20a9
        .byte   26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41

        ;; Board edges
        .byte   12
        .word   $212b
        .byte   5,6,6,6,6,6,6,6,6,6,6,7
        .byte   12
        .word   $228b
        .byte   11,12,12,12,12,12,12,12,12,12,12,13

        ;; Initial instructions
        .byte   31
        .word   $2321
        .byte   "      PRESS START TO BEGIN     "
        .byte   0

cell_row_tiles:
        .byte   44
        .word   $214b
        .byte   8,1,2,1,2,1,2,1,2,1,2,10,0,0,0,0
        .byte   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        .byte   9,3,4,3,4,3,4,3,4,3,4,10
        .byte   0

randomizing_msg:
        .byte   63
        .word   $2321
        .byte   "         RANDOMIZING...         "
        .byte   "                               "
        .byte   0

instructions:
        .byte   63
        .word   $2321
        .byte   "   D-PAD: MOVE        A: FLIP   "
        .byte   "      START:  RESET PUZZLE     "
        .byte   0

victory_msg:
        .byte   63
        .word   $2321
        .byte   "        CONGRATULATIONS!        "
        .byte   "      PRESS START TO RESET     "
        .byte   0
