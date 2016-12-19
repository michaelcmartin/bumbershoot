
!zone random {

        +define ~data, ~random_val, 4 ; Current random number
        +define ~data, ~.mult32_1, 4
        +define ~data, ~.mult32_2, 4
        +define ~data, ~.mult32_result, 8


random_seed:
        lda     #$00
        sta     random_val
        sta     random_val+1
        sta     random_val+2
        sta     random_val+3
        rts

random_update:
        lda     .multiplier
        sta     .mult32_1
        lda     .multiplier+1
        sta     .mult32_1+1
        lda     .multiplier+2
        sta     .mult32_1+2
        lda     .multiplier+3
        sta     .mult32_1+3
        lda     random_val
        sta     .mult32_2
        lda     random_val+1
        sta     .mult32_2+1
        lda     random_val+2
        sta     .mult32_2+2
        lda     random_val+3
        sta     .mult32_2+3
        jsr     .mult32
        clc
        lda     .mult32_result
        adc     .offset
        sta     random_val
        lda     .mult32_result+1
        adc     .offset+1
        sta     random_val+1
        lda     .mult32_result+2
        adc     .offset+2
        sta     random_val+2
        lda     .mult32_result+3
        adc     .offset+3
        sta     random_val+3
        rts


;;; 32 bit multiply with 64 bit product

.mult32:
        lda     #$00
        sta     .mult32_result+4        ; Clear upper half of
        sta     .mult32_result+5        ; product
        sta     .mult32_result+6
        sta     .mult32_result+7
        ldx     #$20                    ; Set binary count to 32
-:      lsr     .mult32_1+3             ; Shift multiplyer right
        ror     .mult32_1+2
        ror     .mult32_1+1
        ror     .mult32_1
        bcc     +                       ; Go rotate right if c = 0
        lda     .mult32_result+4        ; Get upper half of product
        clc                             ; and add multiplicand to
        adc     .mult32_2               ; it
        sta     .mult32_result+4
        lda     .mult32_result+5
        adc     .mult32_2+1
        sta     .mult32_result+5
        lda     .mult32_result+6
        adc     .mult32_2+2
        sta     .mult32_result+6
        lda     .mult32_result+7
        adc     .mult32_2+3
+:      ror                             ; Rotate partial product
        sta     .mult32_result+7        ; right
        ror     .mult32_result+6
        ror     .mult32_result+5
        ror     .mult32_result+4
        ror     .mult32_result+3
        ror     .mult32_result+2
        ror     .mult32_result+1
        ror     .mult32_result
        dex                             ; Decrement bit count and
        bne     -                       ; loop until 32 bits are done
        rts

.multiplier:
        !32     $9010836d

.offset:
        !32     $2aa01d31

}
