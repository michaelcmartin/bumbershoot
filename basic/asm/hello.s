        .word   $033c
        .org    $033c

        ldy     #$00
lp:     lda     msg, y
        beq     done
        jsr     $ffd2           ; CHROUT
        iny
        bne     lp
done:   rts

msg:    .byte   "HELLO, WORLD!",13,0
