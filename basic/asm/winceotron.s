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
        dec     $fd
        lda     $fd
        cmp     #$32
        bne     nowrap
        inc     $fc
        lda     #$3a
        sta     $fd
nowrap: lda     $fc
        sta     $d021
        lda     $fd
done:   sta     $d012
        sta     $fb
        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc
