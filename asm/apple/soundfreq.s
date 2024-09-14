        .alias halfsec  $30bb
        .alias speaker  $c030

        .data
        .org    $2000
        .space  snd_freq     2
        .space  snd_current  2
        .space  snd_duration 2
        .space  index        1

        .text
        .org    $801
        .word   +, 2024
        .byte   $8c, " 2062",0
*       .word   0


        lda     #$00
        sta     index

mainlp: ldy     index
        lda     scale,y
        sta     snd_freq
        iny
        lda     scale,y
        beq     done
        sta     snd_freq+1
        iny
        sty     index
        lda     #<halfsec
        sta     snd_duration
        lda     #>halfsec
        sta     snd_duration+1
        jsr     note
        jmp     mainlp
done:   rts

scale:  .word   $55e,$606,$6c3,$72a,$80b,$907,$a22,$abc,0

note:   lda     #$00
        sta     snd_current
        sta     snd_current+1
        ldy     snd_duration+1
        ldx     snd_duration
        beq     snd_lp
        iny
snd_lp: clc                     ;  2
        lda     snd_freq        ;  6
        adc     snd_current     ; 10
        sta     snd_current     ; 14
        lda     snd_freq+1      ; 18
        adc     snd_current+1   ; 22
        sta     snd_current+1   ; 26
        bcc     snd_dl          ; 28
        sta     speaker         ; 32
snd_bk: dex                     ; 34
        bne     snd_d2          ; 36
        dey                     ; 38
        bne     snd_lp          ; 41
        rts
snd_dl: bcc     snd_bk          ; 32
snd_d2: jmp     snd_lp          ; 41
