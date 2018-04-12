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
