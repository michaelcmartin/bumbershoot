        .alias halfsec  $4e
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
        lda     #halfsec
        sta     snd_duration
        lda     #>halfsec
        sta     snd_duration+1
        jsr     note
        jmp     mainlp
done:   rts


scale:  .byte $4E,$45,$3E,$3A,$34,$2E,$29,$27,$00

note:   ldy     snd_hwl
        ldx     #$00
        sec
        lda     snd_duration
        sbc     #$03
        sta     snd_duration
snd_lp: dey                     ;  2
        bne     snd_dl          ;  4
        sta     speaker         ;  8
        ldy     snd_hwl         ; 12
snd_tk: dex                     ; 14
        bne     snd_d2          ; 16
        dec     snd_duration    ; 22
        bpl     snd_lp          ; 25
        ldy     #$0f
*       dex
        bne     -
        dey
        bne     -
        rts
snd_dl: nop                     ;  7
        nop                     ;  9
        jmp     snd_tk          ; 12
snd_d2: nop                     ; 19
        bit     $00             ; 22
        jmp     snd_lp          ; 25
