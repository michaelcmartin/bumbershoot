        .alias halfsec  $34c9
        .alias speaker  $c030
        .alias snd_hwl  $2000
        .alias index    $2001
        .alias snd_duration $2002

        .org    $0801
        .word   +, 2016
        .byte   $8c, " 2062",0
*       .word   0

        lda     #$00
        sta     index

mainlp: ldy     index
        lda     scale, y
        beq     done
        inc     index
        sta     snd_hwl
        lda     #<halfsec
        sta     snd_duration
        lda     #>halfsec
        sta     snd_duration+1
        jsr     note
        jmp     mainlp
done:   rts


scale:  .byte $34,$2F,$29,$27,$23,$1F,$1B,$1A,$00

note:   ldy     snd_hwl

snd_lp: dey                     ;  2
        bne     snd_dl          ;  4
        sta     speaker         ;  8
        ldy     snd_hwl         ; 12
snd_tk: sec                     ; 14
        lda     snd_duration    ; 18
        sbc     #$01            ; 20
        sta     snd_duration    ; 24
        lda     snd_duration+1  ; 28
        sbc     #$00            ; 30
        sta     snd_duration+1  ; 34
        bpl     snd_lp          ; 37
        rts
snd_dl: nop                     ;  7
        nop                     ;  9
        jmp     snd_tk          ; 12
