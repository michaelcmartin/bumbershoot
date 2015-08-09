        .word   $c000
        .org    $c000

main:   bit     $d011
        bpl     main
vblank: bit     $d011
        bmi     vblank
        lda     #$00
        sta     $d021
        ldx     #$0e
        sei
        lda     #$5a
lp:     cmp     $d012
        bne     lp
        inc     $d021
        clc
        adc     #$08
        dex
        bpl     lp
        cli
        jsr     $ffe4           ; GETIN
        beq     $c000
        rts
