        .outfile "gallery.xex"
        .word   $ffff,start,end-1
        .org    $0700

start:  lda     #$00
        tax
clrpm:  sta     $c00,x
        sta     $d00,x
        sta     $e00,x
        sta     $f00,x
        inx
        bne     clrpm

        ldx     #$00
*       lda     score_msg,x
        beq     +
        sta     $0c08,x
        inx
        bne     -

*       ldx     #40
        lda     #$55
*       sta     $0c13,x
        dex
        bne     -

        ldx     #$00
*       lda     dlist,x
        sta     dlist_loc,x
        inx
        cpx     #dlist_len
        bne     -

*       lda     #$0c
        sta     $d407                   ; PMBASE
        lda     #$00
        sta     $022f                   ; SDMCTL
        lda     #<dlist_loc
        sta     $0230                   ; SDLSTL
        lda     #>dlist_loc
        sta     $0231                   ; SDLSTH
        lda     #$2e
        sta     $022f                   ; SDMCTL

        lda     #$11                    ; 5 players over playfield
        sta     $26f                    ; GPRIOR
        lda     #124                    ; X coordinates
        sta     $d000
        sta     $d002
        lda     #92
        sta     $d001
        lda     #156
        sta     $d003
        lda     #48
        sta     $d004
        lda     #206
        sta     $d005
        lda     #76
        sta     $d006
        lda     #140
        sta     $d007
        lda     #$03                    ; Enable players and missiles
        sta     $d01d
        lda     #$3a                    ; Orange blaster
        sta     $2c0
        lda     #$46                    ; Red targets
        sta     $2c1
        sta     $2c2
        sta     $2c3
        lda     #$d4                    ; Green mode 0 BG
        sta     $2c6
        lda     #$1c                    ; Yellow missiles
        sta     $2c7

        ldx     #$06                    ; Draw blaster
*       lda     gfx_blaster,x
        sta     $e00+93,x
        dex
        bpl     -
        ldx     #$07                    ; Draw targets
*       lda     gfx_target,x
        sta     $e80+38,x
        sta     $f00+38,x
        sta     $f80+38,x
        dex
        bpl     -

        lda     #$09                    ; M0 and M1 mark left and right
        sta     $d80+40
        sta     $d80+42
        lda     #$06
        sta     $d80+41

        lda     #$10                    ; M2 and M3 just hang out
        sta     $d80+85
        sta     $d80+45                 ; With M2 in two Y locations
        sta     $d80+86
        sta     $d80+46
        sta     $d80+87
        sta     $d80+47
        lda     #$40
        sta     $d80+76
        sta     $d80+77
        sta     $d80+78

        lda     #$ff                    ; P0 also marks top/bottom boundaries
        sta     $e00+16                 ; Top line at Y=16
        sta     $e00+111                ; Bottom line at Y=111

loop:   jmp     loop

score_msg:
        .byte   $33,$23,$2f,$32,$25,$1a,$00

gfx_blaster:
        .byte   $10,$38,$ba,$ba,$fe,$fe,$92
gfx_target:
        .byte   $00,$3c,$42,$5a,$5a,$42,$3c,$00

dlist:  .byte   $70,$70,$70             ; 24 blank lines
        .byte   $47,$00,$0c             ; One line GR 2 at $0c00
        .byte   $10,$0d                 ; 2 blank and 1 big pixel for divider
        .byte   $50,$70,$70,$70,$70,$70,$70,$70,$70
        .byte   $70,$70,$70,$70,$70,$70,$70,$70 ; Main playfield
        .byte   $60,$60                 ; Space for blaster
        .byte   $02,$02,$02             ; Ground
        .byte   $41                     ; End of list
        .word   dlist_loc               ; Display list backpointer

        .alias  dlist_len ^-dlist
        .alias  dlist_loc $0c00-dlist_len
        .checkpc dlist_loc

end:    .word   $02e0,$02e1,start
