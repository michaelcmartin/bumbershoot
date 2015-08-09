        .word   $c000
        .org    $c000

intr:   lda     #$01
        sta     $d019
        nop
        lda     $fb
        clc
        inc     $d021
        adc     #$08
        bcc     done
        lda     #$00
        sta     $d021
        lda     #$3a
done:   sta     $d012
        sta     $fb
        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc
