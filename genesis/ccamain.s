        seg     data
CurBuf: ds      4

        seg     text
CCAInit:
        move.l  #CCA_buf_0, CurBuf
        move.w  #0, mirror_ready ; Also clears reset_requested
        ;; Fall through to CCAReset

CCAReset:
        movem.l d2-d3/a2, -(sp)
        movea.l CurBuf, a2
        move.w  #4095, d2
.lp:    bsr     rnd
        moveq   #3, d3
.cell:  move.w  d0, d1
        and.b   #$0f, d1
        move.b  d1, (a2)+
        lsr.w   #4, d0
        dbra    d3, .cell
        dbra    d2, .lp
        ;; A reset has happened. Don't allow new reset requests until
        ;; START has been released for at least one frame.
        move.b  #2, reset_requested
        movem.l (sp)+, d2-d3/a2
        ;; Fall through to CCARender

CCARender:
        move.b  mirror_ready, d0
        bne     CCARender
        move.l  d2, -(sp)
        movea.l CurBuf, a0
        lea     CCA_vram_mirror, a1
        moveq   #63, d0         ; Pairs of rows
.rows:  moveq   #63, d1         ; Pairs of columns
.cols:  ;; Bottom row first
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
        dbra    d1, .cols
        ;; Skip the row we just dealt with
        add.w   #128, a0
        dbra    d0, .rows
        ;; Clean up, we're done
        move.b  #2, mirror_ready
        move.l  (sp)+, d2
        rts

        list macro

        macro check_cell base, north, west, east, south
        move.b  d4, d5
        addq    #1, d5
        and.b   #$0f,d5         ; d5 = (d4 + 1) & 0x0f = target color
        cmp.b   north(base),d5     ; Check N neighbor
        beq.s   .eat ## \?
        cmp.b   west(base),d5       ; Check W neighbor
        beq.s   .eat ## \?
        cmp.b   east(base),d5         ; Check E neighbor
        beq.s   .eat ## \?
        cmp.b   south(base),d5      ; Check S neighbor
        bne.s   .next ## \?
.eat ## \?
        move.b  d5, d4          ; Final color is one step up
.next ## \?
        endm

CCAStep:
        ;; Before anything else, check if we should reset instead
        move.b  reset_requested, d0
        btst    #0, d0
        bne     CCAReset

        movem.l d2-d5/a2-a3, -(sp)
        movea.l CurBuf, a0      ; Source buffer
        move.l  a0, d0          ; Compute destination buffer by
        eor.w   #$4000, d0      ; flipping the $4000 bit
        move.l  d0, a1          ; Destination buffer
        move.l  a1, CurBuf      ; Which will be the next source buffer

        ;; Check the internal points first
        move.w  #(126*128-3), d2 ; 126 non-edge rows and 128 columns, skipping
                                 ; the first and last
        lea     129(a0),a2      ; Point a2 to first non-edge cell
        lea     129(a1),a3      ; And do the same with a3 and target
.lp:    move.b  (a2)+,d4        ; d4 = this cell's color
        move.b  d4, d5
        addq    #1, d5
        and.b   #$0f,d5         ; d5 = (d4 + 1) & 0x0f = target color
        cmp.b   -129(a2),d5     ; Check N neighbor
        beq.s   .eat
        cmp.b   -2(a2),d5       ; Check W neighbor
        beq.s   .eat
        cmp.b   (a2),d5         ; Check E neighbor
        beq.s   .eat
        cmp.b   127(a2),d5      ; Check S neighbor
        bne.s   .skip
.eat:   move.b  d5, (a3)+       ; Store updated color in target
        dbra    d2, .lp
        bra.s   .cdone
.skip:  move.b  d4, (a3)+       ; Store initial color in target
        dbra    d2, .lp
.cdone:
        ;; Now check the corners
        move.b  (a0),d4
        check_cell a0, 1, 127, 128, $3f80
        move.b  d4,(a1)
        move.b  $7f(a0),d4
        check_cell a0, 0, $7e, $ff, $3fff
        move.b  d4,$7f(a1)
        move.b  $3f80(a0),d4
        check_cell a0, 0, $3f00, $3f81, $3fff
        move.b  d4,$3f80(a1)
        move.b  $3fff(a0),d4
        check_cell a0, $7f, $3f7f, $3f80, $3ffe
        move.b  d4,$3fff(a1)

        ;; Finally test the edges
        lea     1(a0),a2        ; Horizontal src pointer
        lea     1(a1),a3        ; Horizontal dest pointer
        lea     128(a0),a0      ; Vertical src pointer
        lea     128(a1),a1      ; Vertical dest pointer
        moveq   #125,d2         ; 126 cells
.lp2:   move.b  $3f80(a2),d4
        check_cell a2,0,$3f00,$3f7f,$3f81
        move.b  d4,$3f80(a3)
        move.b  (a2)+,d4
        check_cell a2,-2,0,127,$3f7f
        move.b  d4,(a3)+
        move.b  (a0),d4
        check_cell a0,-128,1,127,128
        move.b  d4,(a1)
        move.b  127(a0),d4
        check_cell a0,-1,0,126,255
        move.b  d4,127(a1)
        lea     128(a0),a0
        lea     128(a1),a1
        dbra    d2,.lp2

        movem.l (sp)+, d2-d5/a2-a3
        rts
