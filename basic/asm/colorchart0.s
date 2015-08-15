        ;; Reconstructed in part from a sample program in "Mapping the
        ;; Commodore 64" by Sheldon Leemon. The "Color Chart Madness"
        ;; series on the Bumbershoot blog evolves this into a more
        ;; accurate and friendly program.
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
