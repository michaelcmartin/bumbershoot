        .zeropage
x_:     .res    2
y_:
rndval: .res    4

        .export   srnd, rnd
        .exportzp rndval

        .code
.proc   srnd
        sta     x_
        sta     y_
        stx     x_+1
        stx     y_+1
        rts
.endproc

        ;; Roll the RNG twice, so that each frame has 32 random bits
        ;; to work with. That's the most we'll ever need.
.proc   rnd
        jsr     step
        lda     rndval
        sta     rndval+2
        lda     rndval+1
        sta     rndval+3
        ;; fall through to step.

        ;; x ^= x << 5
step:   lda     x_
        ldy     x_+1
        ldx     #$05
lp:     asl
        rol     x_+1
        dex
        bne     lp
        eor     x_
        sta     x_
        tya
        eor     x_+1
        sta     x_+1
        ;; x ^= x >> 3
        ldy     x_              ; .A already has x_+1
        ldx     #$03
lp2:    lsr
        ror     x_
        dex
        bne     lp2
        eor     x_+1
        sta     x_+1
        tya
        eor     x_
        sta     x_
        ;; push y
        lda     y_
        pha
        lda     y_+1
        pha
        ;; x, y = y, y ^ (y >> 1) ^ x
        lsr
        ror     y_
        eor     x_+1
        sta     y_+1
        pla
        sta     x_+1
        eor     y_+1
        sta     y_+1
        pla
        tax
        eor     y_
        eor     x_
        sta     y_
        stx     x_
        rts
.endproc
