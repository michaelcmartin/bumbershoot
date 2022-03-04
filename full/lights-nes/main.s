        .import __OAM_START__
        .importzp vstat
        .import vidbuf
        .export main

        .zeropage
zptr:   .res    2

        .code

.macro  vflush
        .local lp
lp:     bit     vstat
        bmi     lp
.endmacro

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

loop:   jmp     loop

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

        ;; Game text. Map characters to target tiles...
        .charmap $20, 0
        .charmap $41, 42
        .charmap $42, 43
        .charmap $43, 44
        .charmap $44, 45
        .charmap $45, 46
        .charmap $46, 47
        .charmap $47, 48
        .charmap $49, 49
        .charmap $4c, 50
        .charmap $4d, 51
        .charmap $4e, 52
        .charmap $4f, 53
        .charmap $50, 54
        .charmap $52, 55
        .charmap $53, 56
        .charmap $54, 57
        .charmap $55, 58
        .charmap $56, 59
        .charmap $5a, 60
        .charmap $21, 61
        .charmap $2d, 62
        .charmap $3a, 63

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
