        .word   $c000
        .org    $c000
        
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c5

        nop
        inc     $d021
        lda     #$01
        sta     $d019
        ldx     $d012
        bmi     done
        lda     #$0f
        sta     $d021
        lda     #$92
done:   sta     $d012
        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc
