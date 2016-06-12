
        .outfile "BUMBER.II#fc0801.BAS"
        .org	$0801
        .word	next, 2016
        .byte	$8c, " 2062", 0
next:   .word   0

        .data
        .org    $2000
        .text

        ;; Enter lo-res mixed mode
        lda     $c050
        lda     $c056
        lda     $c054
        lda     $c053

        ;; Display the screen
        jsr     rldecode

        ;; Play our song
        lda     #<notes
        sta     song_notes
        lda     #>notes
        sta     song_notes+1
        lda     #<durations
        sta     song_durs
        lda     #>durations
        sta     song_durs+1
        jsr     playsong

        ;; Clear the screen
        ldy     #119
        lda     #$a0
*       sta     $0400,y
        sta     $0480,y
        sta     $0500,y
        sta     $0580,y
        sta     $0600,y
        sta     $0680,y
        sta     $0700,y
        sta     $0780,y
        dey
        bpl     -

        ;; Back to text mode
        lda     $c051
        rts

.scope

.data
        .space  _hwl    1
        .space  _dur    1
        .space  _ind    1

        ;; Woohoo, 82-byte playroutine
.text
playsong:
        lda     #$00
        sta     _ind
*       ldy     _ind
        .alias  song_notes ^+1
        lda     $ffff, y
        sta     _hwl
        .alias  song_durs  ^+1
        lda     $ffff, y
        sta     _dur
        beq     _done
        jsr     note
        inc     _ind
        bne     -
_done:  rts

note:   ldy     _hwl
        ldx     #$00
        sec
        lda     _dur
        sbc     #$03
        sta     _dur
_lp:    dey                     ;  2
        bne     _dl             ;  4
        sta     $c030           ;  8
        ldy     _hwl            ; 12
_tk:    dex                     ; 14
        bne     _d2             ; 16
        dec     _dur            ; 22
        bne     _lp             ; 25
        ldy     #$0f
*       dex
        bne     -
        dey
        bne     -
        rts
_dl:    nop                     ;  7
        nop                     ;  9
        jmp     _tk             ; 12
_d2:    nop                     ; 19
        bit     $00             ; 22
        jmp     _lp             ; 25

        .checkpc [note & $ff00] + $100
.scend

.scope
rldecode:
        lda     #<logo
        sta     rlsrc
        lda     #>logo
        sta     rlsrc+1
        lda     #$04
        sta     rldst+1
        lda     #$00
        sta     rldst
        ldy     #$08

_lp:    jsr     rlrd
        cmp     #$00
        bne     +
        jsr     rlskip
        dey
        bne     _lp
        beq     _done
*       bpl     _block
        ;; Run
        and     #$7f
        tax
        jsr     rlrd
*       jsr     rlst
        dex
        bne     -
        beq     _lp
_block: tax
*       jsr     rlrd
        jsr     rlst
        dex
        bne     -
        beq     _lp

        .alias  rlsrc   ^+1
rlrd:   lda     logo
        inc     rlsrc
        bne     _done
        inc     rlsrc+1
_done:  rts

        .alias  rldst   ^+1
rlst:   sta     $0400
        inc     rldst
        bne     +
        inc     rldst+1
*       rts

rlskip: clc
        lda     rldst
        adc     #$08
        sta     rldst
        lda     rldst+1
        adc     #$00
        sta     rldst+1
        rts
.scend

notes:
        .byte   $23,$34,$2e,$29,$27,$23,$34,$34
        .byte   $1f,$27,$23,$1f,$1c,$1a,$34,$34
        .byte   $27,$23,$27,$29,$2e,$29,$27,$29,$2e,$34
        .byte   $37,$34,$2e,$29,$34,$29,$2e
        .byte   $23,$34,$2e,$29,$27,$23,$34,$34
        .byte   $1f,$27,$23,$1f,$1c,$1a,$34,$34
        .byte   $27,$23,$27,$29,$2e,$29,$27,$29,$2e,$34
        .byte   $2e,$29,$2e,$34,$37,$34
        .byte   $00

durations:
        .byte   $50,$28,$28,$28,$28,$50,$50,$50
        .byte   $50,$28,$28,$28,$28,$50,$50,$50
        .byte   $50,$28,$28,$28,$28,$50,$28,$28,$28,$28
        .byte   $50,$28,$28,$28,$28,$50,$a0
        .byte   $50,$28,$28,$28,$28,$50,$50,$50
        .byte   $50,$28,$28,$28,$28,$50,$50,$50
        .byte   $50,$28,$28,$28,$28,$50,$28,$28,$28,$28
        .byte   $50,$28,$28,$28,$28,$f0
        .byte   $00

logo:   .byte $a8,$ef,$01,$44,$84,$66,$01,$46,$84,$66,$01,$86
        .byte $84,$66,$01,$46,$84,$66,$01,$44,$92,$00,$88,$44
        .byte $05,$48,$88,$84,$88,$48,$89,$44,$92,$40,$01,$44
        .byte $00,$a8,$cd,$15,$44,$44,$46,$46,$44,$44,$44,$46
        .byte $46,$44,$88,$88,$46,$46,$44,$44,$44,$46,$46,$44
        .byte $44,$87,$00,$04,$40,$44,$44,$40,$87,$00,$a9,$44
        .byte $00,$b2,$44,$02,$88,$88,$89,$44,$87,$00,$84,$44
        .byte $87,$00,$01,$44,$a8,$dc,$00,$86,$44,$89,$64,$86
        .byte $44,$92,$04,$8b,$44,$02,$88,$88,$89,$44,$88,$00
        .byte $02,$04,$04,$88,$00,$01,$44,$a8,$fe,$00,$84,$44
        .byte $01,$64,$8b,$66,$01,$64,$84,$44,$88,$00,$01,$20
        .byte $87,$f0,$02,$00,$00,$8b,$44,$02,$88,$88,$89,$44
        .byte $92,$00,$01,$44,$88,$a0,$16,$20,$02,$15,$0d,$02
        .byte $05,$12,$13,$08,$0f,$0f,$14,$20,$13,$0f,$06,$14
        .byte $17,$01,$12,$05,$20,$8a,$a0,$00,$03,$44,$44,$64
        .byte $8f,$66,$03,$64,$44,$44,$88,$00,$01,$22,$87,$ff
        .byte $02,$00,$00,$8b,$44,$02,$88,$88,$89,$44,$88,$00
        .byte $02,$88,$88,$88,$00,$01,$44,$91,$a0,$04,$20,$0f
        .byte $0e,$20,$93,$a0,$00,$01,$44,$93,$66,$01,$44,$88
        .byte $00,$01,$22,$87,$ff,$02,$00,$40,$8b,$44,$02,$88
        .byte $88,$89,$44,$88,$00,$02,$88,$88,$88,$00,$01,$44
        .byte $8c,$a0,$0e,$20,$14,$08,$05,$20,$01,$10,$10,$0c
        .byte $05,$20,$09,$09,$20,$8e,$a0,$00,$01,$44,$93,$66
        .byte $01,$44,$92,$00,$8b,$44,$02,$88,$88,$89,$44,$88
        .byte $00,$02,$08,$08,$88,$00,$01,$44,$a8,$a0,$00
