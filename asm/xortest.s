        .text
        .word   $0801
        .org    $0801

.scope
        .word   _next, 2015
        .byte   $9e, " 2062",0
_next:  .word   0
.scend

        .data
        .org    $c000
        .space  count   1

        .text
        lda     #$01
        ldx     #$00
        jsr     srnd            ; Reset seed
        lda     #64
        sta     count
mainlp: jsr     rnd
        jsr     output
        lda     #$20
        jsr     $ffd2
        jsr     $ffd2
        jsr     $ffd2
        jsr     $ffd2
        dec     count
        lda     #$03
        and     count
        bne     mainlp
        lda     #$0D
        jsr     $ffd2
        lda     count
        bne     mainlp
        rts

output: lda     rndval+1
        jsr     printhex
        lda     rndval
        ;; Fall through to printhex
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

        .include "xorshift.s"
