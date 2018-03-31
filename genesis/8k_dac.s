SetupDAC:
        move.l  a2, -(sp)
        moveq   #0, d0
        move.w  #$100, d1
        ;; Capture bus from Z80
        movea.l #$00a11100, a0
        move.w  d1,(a0)
        move.w  d1,$100(a0)
@ZWait: btst    d0,(a0)
	bne.s   @ZWait

        ;; Load Z80 player program
        move.l  #$00a00000, a0
        lea     @PlayerProg(pc), a1
        move.w  #(@PlayerProgEnd - @PlayerProg - 1),d0
@ZFill: move.b  (a1)+,(a0)+
        dbra    d0,@ZFill

        ;; Give control back to Z80
        movea.l #$00a11100, a0
        moveq   #0, d0
        move.w  d0,$100(a0)
        move.w  d0,(a0)
        move.w  d1,$100(a0)

        move.l  (sp)+, a2
        rts

@PlayerProg:
        include "8k_dac.s80"
@PlayerProgEnd:

        align   2

PlaySample:
        movea.l #$00a00008, a0
        movea.l #$00a11100, a1
        move.w  #$0100,(a1)
        move.l  4(sp), d0
        moveq   #0, d1
        move.w  8(sp), d1
@z1:    btst    #0, (a1)
        bne.s   @z1
        move.b  d1, (a0)+
        lsr.l   #8, d1
        move.b  d1, (a0)+
        move.b  d0, (a0)+
        lsr.l   #8, d0
        move.b  d0, (a0)+
        lsr.l   #8, d0
        move.b  d0, (a0)
        move.w  #$00, (a1)
        rts
