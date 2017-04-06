        .text
        .word   $0801
        .org    $0801

.scope
        .word   _next, 2015
        .byte   $9e, " 2062",0
_next:  .word   0
.scend

        jsr     srnd            ; Reset seed
        lda     #64
        sta     count
mainlp: jsr     rnd
        jsr     output
        lda     #$20
        jsr     $ffd2
        jsr     $ffd2
        jsr     $ffd2
        jsr     $ffd2
        dec     count
        lda     #$03
        and     count
        bne     mainlp
        lda     #$0D
        jsr     $ffd2
        lda     count
        bne     mainlp
        rts

count:  .byte   0

output: lda     rndval+1
        jsr     printhex
        lda     rndval
        ;; Fall through to printhex
printhex:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     print4
        pla
        and     #$0f
        ;; Fall through to print4
print4: clc
        adc     #$30
        cmp     #$3a
        bcc     +
        adc     #$06
*       jmp     $ffd2

        .scope
_x:     .word   1
rndval:
_y:     .word   1

srnd:   ldx     #$01
        stx     _x
        stx     _y
        dex
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
