        .include "charmap.inc"

.macro  vflush
        .local lp
        lda     #$80
        sta     vstat
lp:     bit     vstat
        bmi     lp
.endmacro

        .import __OAM_START__
        .importzp vstat, j0stat, frames, rndval
        .import vidbuf
        .export main

        .zeropage
        ;; Reserve 16 bytes for scratch space. This can be trashed by
        ;; any function call, potentially.
scratch:
        .res    16

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

        ;; Amount of time from poweron to here determines initial puzzle state.
        jsr     randomize_board

        ;; Update status bar.
        lda     #<randomizing_msg
        ldx     #>randomizing_msg
        jsr     vblit
        vflush

scramble:
        ;; If start button is pressed, keep randomizing...
        jsr     next_frame
        lda     #$10
        and     j0stat
        beq     scrambled
        jsr     randomize_board
        jsr     grid_to_attr
        jmp     scramble

scrambled:
        ;; Put the in-game instructions in place.
        lda     #<instructions
        ldx     #>instructions
        jsr     vblit
        vflush

        ;; No game yet; go back to out-of-game state
        jmp     game_start


;;; --------------------------------------------------------------------------
;;; * SUPPORT ROUTINES
;;; --------------------------------------------------------------------------

        .zeropage
crsr_x: .res    1
crsr_y: .res    1
        .res    1               ; Scratch byte to make moves easier
grid:   .res    5               ; The grid
        .res    1               ; Scratch byte to make moves easier

        .code
        ;; Makes a move at (crsr_x, crsr_y). Doesn't touch scratch.
.proc   make_move
        ldx     crsr_y
        ldy     crsr_x
        lda     move_edge,y
        eor     grid-1,x
        sta     grid-1,x
        lda     move_edge,y
        eor     grid+1,x
        sta     grid+1,x
        lda     move_center,y
        eor     grid,x
        sta     grid,x
        rts
.endproc

.proc   randomize_board
        count = scratch
        index = scratch+1
        curr  = scratch+2

        ldx     #$01
        stx     count
        dex
        stx     index
        lda     #$04
        sta     crsr_y
row:    lda     #$04
        sta     crsr_x
cell:   dec     count
        bne     :+
        ;; Out of bits, reset counter, load next rndval
        ldx     index
        lda     rndval,x
        sta     curr
        lda     #$08
        sta     count
        inc     index
:       lsr     curr
        bcc     :+
        jsr     make_move
:       dec     crsr_x
        bpl     cell
        dec     crsr_y
        bpl     row
        ;; Reset cursor on the way out
        lda     #$02
        sta     crsr_x
        sta     crsr_y
        rts
.endproc

        .rodata
move_edge:
        .byte   $10,$08,$04,$02,$01
move_center:
        .byte   $18,$1C,$0E,$07,$03

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
        out = scratch           ; 3 bytes used

        ;; Copy template to vidbuf
        lda     #<attr_base
        ldx     #>attr_base
        jsr     vblit           ; Trashes first two 'out' bytes

        ;; Compute top attr row from tow board row
        jsr     clear
        lda     grid
        jsr     trans
        jsr     shift4
        ldx     #$03
        jsr     attrcpy

        ;; Compute second attr row from middle two board rows
        jsr     clear
        lda     grid+2
        jsr     trans
        jsr     shift4
        lda     grid+1
        jsr     trans
        ldx     #$09
        jsr     attrcpy

        ;; Compute final attr row from final two board rows
        jsr     clear
        lda     grid+4
        jsr     trans
        jsr     shift4
        lda     grid+3
        jsr     trans
        ldx     #$0f
        jsr     attrcpy

        ;; Board is ready. Let it be rendered.
        vflush
        rts

attrcpy:
        lda     out
        sta     vidbuf,x
        lda     out+1
        sta     vidbuf+1,x
        lda     out+2
        sta     vidbuf+2,x
        rts

trans:  lsr
        bcc     @rtblk
        pha
        lda     out+2
        ora     #$01
        sta     out+2
        pla
@rtblk: pha
        and     #$03
        tax
        lda     cell_attrs,x
        ora     out+1
        sta     out+1
        pla
        lsr
        lsr
        and     #$03
        tax
        lda     cell_attrs,x
        ora     out
        sta     out
        rts

shift4: ldx     #$04
@lp:    asl     out
        asl     out+1
        asl     out+2
        dex
        bne     @lp
        rts

clear:  ldx     #$00
        stx     out
        stx     out+1
        stx     out+2
        rts
.endproc                        ; End of grid_to_attr

        .rodata
cell_attrs:
        .byte   $00,$04,$01,$05
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
