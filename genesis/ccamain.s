        seg     data
CurBuf: ds      4

        seg     text
CCAInit:
        bsr     srnd
        move.l  #CCA_buf_0, CurBuf
        move.b  #0, mirror_ready
        ;; Fall through to CCAReset

CCAReset:
        movem.l d2-d3/a2, -(sp)
        movea.l CurBuf, a2
        move.w  #4095, d2
@lp:    bsr     rnd
        moveq   #3, d3
@cell:  move.w  d0, d1
        and.b   #$0f, d1
        move.b  d1, (a2)+
        lsr.w   #4, d0
        dbra    d3, @cell
        dbra    d2, @lp
        movem.l (sp)+, d2-d3/a2
        ;; Fall through to CCARender
        ;; TODO: This is unlikely to survive the full implementation

CCARender:
        move.b  mirror_ready, d0
        bne     CCARender
        move.l  d2, -(sp)
        movea.l CurBuf, a0
        lea     CCA_vram_mirror, a1
        moveq   #63, d0         ; Pairs of rows
@rows:  moveq   #63, d1         ; Pairs of columns
@cols:  ;; Bottom row first
        move.w  #$0100, d2      ; after the shift, v-flip on
        move.b  128(a0), d2
        asl.w   #4, d2
        or.b    129(a0), d2
        move.w  d2, 8192(a1)
        ;; Then top row, advancing our pointers
        moveq   #$0, d2
        move.b  (a0)+, d2
        asl.w   #4, d2
        or.b    (a0)+, d2
        move.w  d2, (a1)+
        dbra    d1, @cols
        ;; Skip the row we just dealt with
        add.w   #128, a0
        dbra    d0, @rows
        ;; Clean up, we're done
        move.b  #2, mirror_ready
        move.l  (sp)+, d2
        rts

CCAStep:
        movem.l d2-d6/a0-a1, -(sp)
        movea.l CurBuf, a0      ; Source buffer
        move.l  a0, d0          ; Compute destination buffer by
        eor.w   #$4000, d0      ; flipping the $4000 bit
        move.l  d0, a1          ; Destination buffer
        move.l  a1, CurBuf      ; Which will be the next source buffer

        ;; Check the internal points first
        move.w  #125, d2       ; 126 non-edge rows
@lp:    move.w  #125, d3       ; 126 non-edge columns
@lp2:   bsr.s   @index
        add.w   #129, d0
        move.b  (a0, d0), d4    ; d4 = this cell's color
        move.b  d4, d5
        addq    #1, d5
        and.b   #$0f, d5        ; d5 = (d4 + 1) & 0x0f = target color
        move.w  d0, d6          ; Cache displacement
        cmp.b   -128(a0, d0), d5
        beq.s   @eat
        cmp.b   -1(a0, d0), d5
        beq.s   @eat
        cmp.b   1(a0, d0), d5
        beq.s   @eat
        addq    #1, d0          ; 8-bit displacement means we can't offset 128!
        cmp.b   127(a0, d0), d5
        bne.s   @next
@eat:   move.b  d5, d4
@next:  move.b  d4, (a1, d6)
        dbra    d3, @lp2
        dbra    d2, @lp

        ;; Now check the corners
        move.w  #127, d6
@lp3:   move.w  d6, d2
        moveq   #0, d3
        bsr.s   @dopt
        exg     d2, d3
        bsr.s   @dopt
        move.w  #127, d2
        bsr.s   @dopt
        exg     d2, d3
        bsr.s   @dopt
        dbra    d6, @lp3

        movem.l (sp)+, d2-d6/a0-a1
        rts

@index: move.w  d2, d0          ; d0 = (y & 0x7f) * 128
        lsl.w   #7, d0
        move.w  d3, d1          ; d1 = (x & 0x7f)
        or.w    d1, d0          ; d0 = ((y & 0x7f) * 128) + (x & 0x7f)
        rts
@check: bsr     @index
        cmp.b   (a0, d0), d5
        bne.s   @done
        move.b  d5, d4
@done:  rts

@dopt:  bsr     @index
        move.b  (a0, d0), d4    ; d4 = this cell's color
        move.b  d4, d5
        addq    #1, d5
        and.b   #$0f, d5        ; d5 = (d4 + 1) & 0x0f = target color
        subq    #1, d2
        and.w   #$7f, d2
        bsr.s   @check
        addq    #2, d2
        and.w   #$7f, d2
        bsr.s   @check
        subq    #1, d2
        and.w   #$7f, d2
        subq    #1, d3
        and.w   #$7f, d3
        bsr.s   @check
        addq    #2, d3
        and.w   #$7f, d3
        bsr.s   @check
        subq    #1, d3
        and.w   #$7f, d3
        bsr.s   @index
        move.b  d4, (a1, d0)
        rts
