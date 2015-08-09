        .word   $c000
        .org    $c000

        jsr     $b1aa
        lda     #$00
        iny
        jmp     ($0005)
