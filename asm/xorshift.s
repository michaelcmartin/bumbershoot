        .scope
        .data
        .space  _x      2
rndval:
        .space  _y      2

        .text
        ;; Seed randomizer with .AX in both values. Calling RDTIM
        ;; ($FFDE) is a good way to get values for .AX.
srnd:   sta     _x
        sta     _y
        stx     _x+1
        stx     _y+1
        rts

        ;; x ^= x << 5
rnd:    lda     _x
        ldy     _x+1
        ldx     #$05
_lp:    asl
        rol     _x+1
        dex
        bne     _lp
        eor     _x
        sta     _x
        tya
        eor     _x+1
        sta     _x+1
        ;; x ^= x >> 3
        ldy     _x              ; .A already has _x+1
        ldx     #$03
_lp2:   lsr
        ror     _x
        dex
        bne     _lp2
        eor     _x+1
        sta     _x+1
        tya
        eor     _x
        sta     _x
        ;; push y
        lda     _y
        pha
        lda     _y+1
        pha
        ;; x, y = y, y ^ (y >> 1) ^ x
        lsr
        ror     _y
        eor     _x+1
        sta     _y+1
        pla
        sta     _x+1
        eor     _y+1
        sta     _y+1
        pla
        tax
        eor     _y
        eor     _x
        sta     _y
        stx     _x
        rts
        .scend
