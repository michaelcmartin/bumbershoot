        .alias halfsec  $56df
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


scale:  .byte $55,$4B,$43,$3F,$38,$32,$2D,$2A,$00

note:   ldy     snd_hwl
        lda     snd_duration+1
        ldx     snd_duration
        beq     snd_lp
        clc
        adc     #$01
snd_lp: dey                     ;  2
        bne     snd_dl          ;  4
        sta     speaker         ;  8
        ldy     snd_hwl         ; 12
snd_tk: dex                     ; 14
        bne     snd_d2          ; 16
        sec                     ; 18
        sbc     #$01            ; 20
        bne     snd_lp          ; 23
        rts
snd_dl: nop                     ;  7
        nop                     ;  9
        jmp     snd_tk          ; 12
snd_d2: bit     $00             ; 20
        jmp     snd_lp          ; 23
