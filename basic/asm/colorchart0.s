        .word   $c000
        .org    $c000

main:   lda     #$5a
        sta     $fb
        lda     #$00
        sta     $d021
        ldx     #$0f
        sei
lp:     lda     $d011
        bmi     lp
lp2:    lda     $d012
        cmp     $fb
        bne     lp2
        inc     $d021
        clc
        adc     #$08
        sta     $fb
        dex
        bpl     lp
        bmi     $c000

       
