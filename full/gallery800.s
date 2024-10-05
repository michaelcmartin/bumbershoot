        .outfile "gallery.xex"
        .word   $ffff,start,end-1
        .org    $0700

        .data
        .org    $0b00
        .space  player_x 1
        .space  target_x 3
        .space  target_y 1

        .text

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

*       jsr     reset_score

        ldx     #40
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
        sta     player_x
        sta     $d002
        sta     target_x+1
        lda     #92
        sta     $d001
        sta     target_x
        lda     #156
        sta     $d003
        sta     target_x+2
        lda     #$03                    ; Enable players and missiles
        sta     $d01d
        lda     #$3a                    ; Orange blaster
        sta     $2c0
        lda     #$46                    ; Red targets
        sta     $2c1
        sta     $2c2
        sta     $2c3
        lda     #$0c                    ; White text/divider
        sta     $2c4
        lda     #$d4                    ; Green mode 0 BG
        sta     $2c6
        lda     #$1c                    ; Yellow missiles
        sta     $2c7

        ldx     #$06                    ; Draw blaster
*       lda     gfx_blaster,x
        sta     $e00+93,x
        dex
        bpl     -
        lda     #38
        sta     target_y

loop:   lda     $14                     ; Jiffy clock
*       cmp     $14                     ; Wait for next jiffy
        beq     -
        jsr     award_score
        lda     $0278                   ; STICK0
        ldx     player_x                ; Update player and target coordinates
        ldy     target_y                ; based on joystick directions
        lsr
        bcs     +
        dey
*       lsr
        bcs     +
        iny
*       lsr
        bcs     +
        dex
*       lsr
        bcs     +
        inx
*       cpx     #47                     ; Bounds-check new coordinates
        bne     +
        ldx     #48
*       cpx     #202
        bne     +
        ldx     #201
*       cpy     #25
        bne     +
        ldy     #26
*       cpy     #86
        bne     +
        ldy     #85
*       stx     player_x                ; Save new coordinates
        sty     target_y
        stx     $d000                   ; Place player
        ldx     #$02                    ; Move targets 1 pixel left
*       lda     target_x,x
        jsr     move_target
        sta     target_x,x
        sta     $d001,x
        dex
        bpl     -
        ldx     #$00                    ; Redraw targets
        ldy     target_y
*       lda     gfx_target,x
        sta     $e80,y
        sta     $f00,y
        sta     $f80,y
        iny
        inx
        cpx     #$08
        bne     -
        jmp     loop

reset_score:
        lda     #$10
        ldx     #$03
*       sta     $0c0f,x
        dex
        bpl     -
        rts

award_score:
        ldx     #$03
*       lda     $0c0f,x                 ; Load digit
        clc                             ; and increment it
        adc     #$01
        cmp     #$1a                    ; Need to carry?
        bne     +                       ; If not, store value and done
        lda     #$10                    ; Otherwise, write a zero...
        sta     $0c0f,x
        dex                             ; move one digit back...
        bpl     -                       ; ... and increment that if it's there
        rts                             ; just quit if we wrapped 9999 though
*       sta     $0c0f,x
        rts

move_target:
        sec
        sbc     #$01
        cmp     #39
        bne     +
        lda     #207
*       rts

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
        .checkpc $0b00

        .data
        .checkpc dlist_loc

        .text

end:    .word   $02e0,$02e1,start
