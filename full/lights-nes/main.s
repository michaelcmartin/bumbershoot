        .include "charmap.inc"

.macro  vflush
        .local lp
lp:     bit     vstat
        bmi     lp
.endmacro

        .import __OAM_START__
        .importzp vstat, j0stat, frames
        .import vidbuf, srnd
        .export main

        .zeropage
zptr:   .res    2

        .code

main:
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
@done:
        ;; Enable graphics
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

        ;; Wait for START button.
:       lda     #$10
        and     j0stat
        beq     :-

        ;; Re-seed the RNG based on frame count.
        lda     frames
        ora     #$01
        jsr     srnd

        ;; Put the in-game instructions in place.
        lda     #<instructions
        ldx     #>instructions
        jsr     vblit
        vflush

hang:   jmp     hang

vblit:  sta     zptr
        stx     zptr+1
        ldy     #$42
:       lda     (zptr),y
        sta     vidbuf,y
        dey
        bpl     :-
        lda     #$80
        sta     vstat
        rts

        .segment "RODATA"
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

        ;; Temporary: Set some stuff in the attribute tables so we
        ;; have a pretty pattern
        .byte   3
        .word   $23d3
        .byte   $50,$40,$10
        .byte   3
        .word   $23db
        .byte   $41,$51,$01
        .byte   3
        .word   $23e3
        .byte   $51,$41,$11

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

instructions:
        .byte   63
        .word   $2321
        .byte   "   D-PAD: MOVE        A: FLIP   "
        .byte   "      SELECT: RESET PUZZLE     "
        .byte   0

victory_msg:
        .byte   63
        .word   $2321
        .byte   "        CONGRATULATIONS!        "
        .byte   "      PRESS START TO RESET     "
        .byte   0
