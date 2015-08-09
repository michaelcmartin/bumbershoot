        .word   $c000
        .org    $c000

        jsr     $b7f7
        lda     $14
        ldy     $15
        jmp     $bba2
