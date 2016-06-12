        .alias halfsec  $2710
        .alias speaker  $c030
        .alias snd_hwl  $2000
        .alias snd_duration $2002
        .alias index    $2004

        .org    $0801
        .word   +, 2016
        .byte   $8c, " 2062",0
*       .word   0

        lda     #$00
        sta     index
        sta     snd_hwl+1

mainlp: ldy     index
        lda     scale, y
        beq     done
        inc     index
        sta     snd_hwl
        lda     #<halfsec
        sta     snd_duration
        lda     #>halfsec
        sta     snd_duration+1
        jsr     snd_lp
        jmp     mainlp
done:   rts


scale:  .byte $26,$22,$1e,$1c,$19,$16,$14,$13,$00

snd_del_1:                      ; 15
        nop                     ; 17
        nop                     ; 19
        nop                     ; 21
snd_del_2:                      ; 21
        txa                     ; 23
        ldx #$04                ; \
snd_dl: dex                     ;  > 44
        bne snd_dl              ; /
        bit $00                 ; 47
        tax                     ; 49
        bne snd_in              ; 51

snd_lp: ldx     snd_hwl+1       ;  4
        ldy     snd_hwl         ;  8
        inx                     ; 10

snd_in: dey                     ; 12
        bne     snd_del_1       ; 14
        dex                     ; 16
        bne     snd_del_2       ; 18
        sta     speaker         ; 22

        sec                     ; 24
        lda     snd_duration    ; 28
        sbc     snd_hwl         ; 32
        sta     snd_duration    ; 36
        lda     snd_duration+1  ; 40
        sbc     snd_hwl+1       ; 44
        sta     snd_duration+1  ; 48
        bpl     snd_lp          ; 51
        rts
