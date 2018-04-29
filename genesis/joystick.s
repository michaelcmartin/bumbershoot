ReadJoy1:
        moveq   #0, d0
        moveq   #0, d1
        movea.l #$a10003, a0
        move.b  #$40, 6(a0)
        move.b  #$40, (a0)
        move.b  (a0), d0
        move.b  d0, d1
        andi.b  #$0f, d1
        asl.b   #1, d0
        and.b   #$60,d0
        or.b    d0, d1
        move.b  #$00, (a0)
        move.b  (a0), d0
        asl.b   #2, d0
        asr.b   #2, d0
        and.b   #$90, d0
        or.b    d1, d0
        eor.b   #$ff, d0
        rts
