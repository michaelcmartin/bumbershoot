        .export make_move, randomize_board, is_solved, move_edge
        .importzp crsr_x, crsr_y, grid, rndval, scratch

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

        ;; Checks to see if the puzzle is solved. Zero flag set if it is.
.proc   is_solved
        ldx     #$05
lp:     lda     grid-1,x
        bne     done
        dex
        bne     lp
done:   rts
.endproc

        .rodata
move_edge:
        .byte   $10,$08,$04,$02,$01
move_center:
        .byte   $18,$1C,$0E,$07,$03
