        .text
        .word   $0801
        .org    $0801
        .outfile "sha256test.prg"

        ;; Program header
        .word   +, 2019
        .byte   $9e," 2062",0
*       .word   0

        .data
        .org    $c000
        .data zp
        .org    $0002

        .text
        jsr     sha256_prep_zp
        ldy     #$3f
*       lda     buf, y
        sta     sha256_chunk,y
        dey
        bpl     -
        jsr     sha256_init
        jsr     sha256_update
        jsr     sha256_restore_zp

        lda     #<msg1
        ldy     #>msg1
        jsr     $ab1e
        ldy     #$00
*       lda     sha256_result, y
        jsr     printhex
        iny
        cpy     #$20
        bne     -
        lda     #<msg2
        ldy     #>msg2
        jmp     $ab1e

printhex:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr     print4
        pla
        and     #$0f
        ;; Fall through to print4
print4: clc
        adc     #$30
        cmp     #$3a
        bcc     +
        adc     #$06
*       jmp     $ffd2

buf:    .byte   "The quick brown fox jumps over the lazy dog."
        .byte   $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$60

msg1:   .byte   "RESULT:",13,0
msg2:   .byte   13,13,"EXPECTED:",13,"EF537F25C895BFA782526529A9B63D97AA631564D5D789C2B765448C8635FB6C",13,0

        .include "sha256.s"
