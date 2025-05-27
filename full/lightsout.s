        .alias  chrout  $ffd2
        .alias  rdtim   $ffde
        .alias  getin   $ffe4
        .alias  stop    $ffe1

        .word   $0801
        .org    $0801

        .data
        .alias  sprpat  $3000
        .org    $4000
        .text

        ;;  BASIC program that just calls our machine language code
.scope
        .word   _next, 2015     ; Next line and current line number
        .byte   $9e," 2062",0   ; SYS 2062
_next:  .word   0               ; End of program
.scend
        jsr     randomize
        jsr     init_sound

        ;; Black screen
        lda     #$00
        sta     $d020
        sta     $d021
        ;; Red for BG Color 2
        lda     #$02
        sta     $d023
        ;; Copy over character set
        sei
        lda     #$33
        sta     $01
        ldy     #$00
*       lda     $d000,y
        sta     $2000,y
        lda     $d100,y
        sta     $2100,y
        iny
        bne     -
        lda     #$37
        sta     $01
        cli
        ;; Load in custom graphics
        ldy     #$67
*       lda     gfx, y
        sta     $2190, y
        dey
        bpl     -
        ldy     #$1f
*       lda     gfx2,y
        sta     $2118,y
        dey
        bpl     -
        iny                             ; ldy #$00
*       lda     gfx3, y
        sta     $2400, y
        iny
        cpy     #$e0
        bne     -
        ;; Enable display interrupt to manage ECM and centering
        jsr     enable_display_irq
        lda     #$18
        sta     $d018
        ;; Draw screen
        lda     #<screen
        ldx     #>screen
        jsr     multistr
        jsr     draw_letters
        jsr     draw_shadow
maingo: lda     #<stclr
        ldx     #>stclr
        jsr     multistr
        lda     #<stwait
        ldx     #>stwait
        jsr     multistr
        jsr     initpuzzle
        lda     #<stclr
        ldx     #>stclr
        jsr     multistr
        lda     #<stinst
        ldx     #>stinst
        jsr     multistr
mainlp: jsr     stop
        beq     finis
        jsr     getin
        cmp     #$85            ; F1
        beq     maingo
        cmp     #'A
        bcc     mainlp
        cmp     #'Z
        bcs     mainlp
        sec
        sbc     #'A
        pha
        jsr     move
        jsr     wonpuzzle
        bpl     victry
        pla
        jsr     move_sound
        jmp     mainlp
        ;; Victory!
victry: pla
        jsr     win_sound
        lda     #<stclr
        ldx     #>stclr
        jsr     multistr
        lda     #<stwin
        ldx     #>stwin
        jsr     multistr
winlp:  jsr     getin
        cmp     #'Y
        beq     maingo
        cmp     #'N
        bne     winlp

        ;; Clean up and quit
finis:  lda     #$0e            ; Light blue border
        sta     $d020
        lda     #$06            ; Blue background
        sta     $d021
        lda     #$14            ; Restore normal charset
        sta     $d018
        jsr     disable_display_irq
        jsr     deinit_sound
        lda     #$00
        sta     $d015           ; Reset sprite config
        sta     $d017
        sta     $d01d
        sta     $c6             ; Clear keyboard buffer
        lda     #<bye
        ldx     #>bye
        jsr     multistr
        jmp     ($a002)         ; Back to BASIC

        .scope
draw_letters:
        lda     #$d5
        sta     $fb
        lda     #$04
        sta     $fc
        ldy     #$00
        ldx     #$05
        sty     $fd
_lp:    inc     $fd
        lda     $fd
        sta     ($fb),y
        lda     $fc
        eor     #$dc
        sta     $fc
        lda     #$0b
        sta     ($fb),y
        lda     $fc
        eor     #$dc
        sta     $fc
        iny
        iny
        iny
        cpy     #$0f
        bne     _lp
        ldy     #$00
        clc
        lda     #$78
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        dex
        bne     _lp
        rts
.scend

.scope
draw_shadow:
        ldx     #$00
*       lda     shadow_nw,x
        sta     sprpat,x
        lda     shadow_nw+256,x
        sta     sprpat+256,x
        inx
        bne     -
        ldx     #$10
*       lda     shadow_loc,x
        sta     $d000,x
        dex
        bpl     -
        ldx     #$07
*       lda     #$0b
        sta     $d027,x
        lda     shadow_pat,x
        sta     $7f8,x
        dex
        bpl     -
        lda     #$06
        sta     $d017
        lda     #$30
        sta     $d01d
        lda     #$ff
        sta     $d015
        rts
.scend

.scope
        .data
        .space  _bits  4
        .space  _index 1
        .space  _tries 1
        .text

initpuzzle:
        jsr     rerandomize
        lda     #30
        sta     _tries
_toplp: jsr     rnd
        lda     rndval
        sta     _bits
        lda     rndval+1
        sta     _bits+1
        jsr     rnd
        lda     rndval
        sta     _bits+2
        lda     rndval+1
        sta     _bits+3
        lda     #24
        sta     _index
_lp:    asl     _bits
        rol     _bits+1
        rol     _bits+2
        rol     _bits+3
        bcc     +
        lda     _index
        jsr     move
*       dec     _index
        bpl     _lp
        lda     frames
*       cmp     frames
        bne     -
        dec     _tries
        bne     _toplp
        rts
.scend

        .scope
;;; ORs all the letter spots together. If it's positive, you've won!
wonpuzzle:
        lda     #$d5
        sta     $fb
        lda     #$04
        sta     $fc
        ldy     #$00
        ldx     #$05
        sty     $fd
_lp:    lda     $fd
        ora     ($fb),y
        sta     $fd
        iny
        iny
        iny
        cpy     #$0f
        bne     _lp
        ldy     #$00
        clc
        lda     #$78
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        dex
        bne     _lp
        lda     $fd
        rts
.scend

;;; Functions about making moves
.scope
rowcol: ldx     #$00
        ldy     #$00
_rclp:  sec
        sbc     #$05
        bmi     _rcend
        iny
        bne     _rclp
_rcend: clc
        adc      #$05
        tax
        rts

point:  lda     #$d5
        sta     $fb
        lda     #$04
        sta     $fc
        cpy     #$00
        beq     _px
_pylp:  clc
        lda     #$78
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        dey
        bne     _pylp
_px:    txa
        asl
        clc
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        txa
        clc
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        rts

flip:   cpx     #$05
        bcs     _bad
        cpy     #$05
        bcs     _bad
        jsr     point
        ;; Subtract 41 from the "point" pointer to hit the upper left
        sec
        lda     $fb
        sbc     #$29
        sta     $fb
        lda     $fc
        sbc     #$00
        sta     $fc
        ;; Then flip all 9 characters.
        jsr     _frow
        ldy     #$28
        jsr     _frow
        ldy     #$50
        jsr     _frow
        ;; Then set the color of the center cell.
        ldy     #$29
        lda     ($fb), y
        bmi     _fon
        lda     #$0b
        .byte   $2c             ; BIT Absolute; skip next instruction
_fon:   lda     #$01
        pha
        lda     $fc
        eor     #$dc
        sta     $fc
        pla
        sta     ($fb),y
        lda     $fc
        eor     #$dc
        sta     $fc
_bad:   rts
_frow:  jsr     _fchar
        iny
        jsr     _fchar
        iny
        ;; Fall through to _fchar
_fchar: lda     ($fb),y
        eor     #$80
        sta     ($fb),y
        rts

move_sound:
        jsr     rowcol
        jsr     point
        ldy     #$00
        lda     ($fb),y
        bmi     +
        jsr     low_ding
        rts
*       jsr     high_ding
        rts

move:   jsr     rowcol
        stx     $fd
        sty     $fe
        ldx     $fd
        ldy     $fe
        jsr     flip
        ldx     $fd
        ldy     $fe
        dex
        jsr     flip
        ldx     $fd
        ldy     $fe
        inx
        jsr     flip
        ldx     $fd
        ldy     $fe
        dey
        jsr     flip
        ldx     $fd
        ldy     $fe
        iny
        jmp     flip
.scend

;;; Display interrupt and its management
.scope
        .data
        .space  frames 1
        .text

enable_display_irq:
        lda     #$00
        sta     frames
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$48
        sta     $d012
        lda     #<_irq
        sta     $314
        lda     #>_irq
        sta     $315
        lda     #$01
        sta     $d01a
        rts

disable_display_irq:
        lda     #$00
        sta     $d01a
        lda     #$31
        sta     $314
        lda     #$ea
        sta     $315
        lda     #$81
        sta     $dc0d
        lda     #$1b            ; Restore normal graphics in case we were
        sta     $d011           ; Mid screen at the time
        lda     #$08
        sta     $d016
        rts

_irq:   lda     #$01            ; Acknowledge interrupt
        sta     $d019

        lda     $d012           ; Midscreen or bottom?
        bmi     _bot

        lda     #$5b            ; At top; Enable ECM for board
        sta     $d011
        lda     #$0c            ; And scroll 4 to the right to center it
        sta     $d016           ; and the instructions
        lda     #$fb            ; Next IRQ is at the bottom
        bne     _done

_bot:   lda     #$1b            ; At bottom; disable ECM for logo
        sta     $d011
        lda     #$08            ; And scroll 0 for centered logo
        sta     $d016
        inc     frames          ; Tick frame counter
        lda     #$48            ; Next IRQ is between logo and board

_done:  sta     $d012           ; Register next IRQ line
        lda     $dc0d           ; Check if there'd have been a timer IRQ
        beq     _notim
        jmp     $ea31           ; If so, jump to it
_notim: jmp     $febc           ; If not, clean up
.scend

;;; Utility functions
.scope
multistr:
        sta     _lp1+1
        sta     _p+1
        stx     _lp1+2
        stx     _p+2
        ldx     #$00
_lp1:   lda     $ffff,x
        sta     _lp2+1
        inx
_p:     lda     $ffff,x
        sta     _lp2+2
        beq     _done
        inx
        ldy     #$00
_lp2:   lda     $ffff,y
        beq     _lp1
        jsr     chrout
        iny
        bne     _lp2
        beq     _lp1
_done:  rts
.scend

        .include "../asm/xorshift.s"

randomize:
        jsr     rdtim
        ora     #$01            ; Make sure .AX isn't zero
        jmp     srnd

rerandomize:
        jsr     rdtim
        clc
        adc     rndval
        ora     #$01
        pha
        txa
        adc     rndval+1
        tax
        pla
        jmp     srnd

deinit_sound:
        ldx     #$18            ; Clear all registers including volume
        .byte   $2c             ; Nullify next instruction
reset_sound:
        ldx     #$17            ; Clear all registers but volume
*       lda     #$00
*       sta     $d400,x
        dex
        bpl     -
        rts

init_sound:
        jsr     reset_sound
        lda     #$08
        sta     $d402           ; Pulse waves are square
        sta     $d403
        sta     $d409
        sta     $d40a
        lda     #$0f            ; Max volume
        sta     $d418
        rts

low_ding:
        lda     #$00            ; Degate any earlier note
        sta     $d404
        lda     #$08            ; 300ms decay
        sta     $d405
        lda     #$25            ; Play C4
        sta     $d400
        lda     #$11
        sta     $d401
        lda     #$41            ; Play a pulse-wave note
        sta     $d404
        rts

high_ding:
        lda     #$00            ; Degate any earlier note
        sta     $d404
        lda     #$08            ; 300ms decay
        sta     $d405
        lda     #$4b            ; Play C5
        sta     $d400
        lda     #$22
        sta     $d401
        lda     #$41            ; Play a pulse-wave note
        sta     $d404
        rts

win_sound:
        lda     #$00            ; Degate any earlier notes
        sta     $d404
        sta     $d40b
        lda     #$0a            ; 1500ms decay
        sta     $d405
        sta     $d40c
        lda     #$34            ; Voice 1: E5
        sta     $d400
        lda     #$2b
        sta     $d401
        lda     #$95            ; Voice 2: C6
        sta     $d407
        lda     #$44
        sta     $d408
        lda     #$41            ; Play first note
        sta     $d404
        sta     $d40b
        lda     #$08            ; Wait 8 jiffies
        sta     $fb
*       jsr     rdtim
        sta     $fc
*       jsr     rdtim
        cmp     $fc
        beq     -
        dec     $fb
        bne     --
        lda     #$00            ; Regate for second note
        sta     $d404
        sta     $d40b
        lda     #$41
        sta     $d404
        sta     $d40b
        rts

.scope
screen: .word   _top,_row,_row,_row,_row,_row,_bot,0
stclr:  .word   _stat,_spc38,_spc38,_spc38,0
stinst: .word   _stat, _inst,0
stwait: .word   _stat, _wait,0
stwin:  .word   _stat, _win,0
bye:    .word   _bye,0
_top:  .byte   147,"              ",$9b,$12,"@ABCDEFGHIJK",$92
        .byte   13,"            ",$12,"LMNOPQRSTUVWXYZ[",$92,13,13
        .byte   "           <===============>",13,0
_row:   .byte   "           :234234234234234;",13
        .byte   "           :5 65 65 65 65 6;",13
        .byte   "           :789789789789789;",13,0
_bot:   .byte   "           #$$$$$$$$$$$$$$$%",13,0
_stat:  .byte   $13,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
        .byte   $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,0
_spc38: .byte   13,"                                      ",0
_inst:  .byte   13,"         PRESS LETTERS TO MOVE",13
        .byte   "        PRESS F1 FOR NEW PUZZLE",13
        .byte   "         PRESS RUN/STOP TO END",0
_wait:  .byte   13,13,$99,"    PLEASE WAIT, CREATING PUZZLE...",$9b,0
_win:   .byte   13,"       CONGRATULATIONS, YOU WIN!",13,13
        .byte   "           PLAY AGAIN (Y/N)?",0
_bye:   .byte   $93,$9a,13,"THANKS FOR PLAYING!",13
        .byte   "   -- MICHAEL MARTIN, 2025",13,0

gfx:    .byte   $ff,$ff,$e0,$c0,$c0,$c0,$c0,$c0
        .byte   $ff,$ff,$00,$00,$00,$00,$00,$00
        .byte   $ff,$ff,$07,$03,$03,$03,$03,$03
        .byte   $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $c0,$c0,$c0,$c0,$c0,$e0,$ff,$ff
        .byte   $00,$00,$00,$00,$00,$00,$ff,$ff
        .byte   $03,$03,$03,$03,$03,$07,$ff,$ff
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
        .byte   $00,$00,$00,$00,$00,$01,$03,$06
        .byte   $00,$00,$00,$00,$00,$ff,$ff,$ff
        .byte   $00,$00,$00,$00,$00,$80,$c0,$60
gfx2:   .byte   $06,$03,$01,$00,$00,$00,$00,$00
        .byte   $ff,$ff,$ff,$00,$00,$00,$00,$00
        .byte   $60,$c0,$80,$00,$00,$00,$00,$00
gfx3:   .byte   $00,$01,$00,$01,$01,$03,$03,$06
        .byte   $00,$f0,$c0,$80,$80,$00,$00,$11
        .byte   $00,$f3,$66,$4c,$cc,$98,$98,$98
        .byte   $00,$d3,$31,$21,$01,$03,$02,$e6
        .byte   $00,$9e,$0c,$08,$08,$f8,$08,$08
        .byte   $00,$fe,$92,$10,$10,$10,$30,$30
        .byte   $00,$3a,$66,$62,$70,$38,$1c,$0e
        .byte   $00,$03,$06,$0c,$0c,$0c,$0c,$06
        .byte   $00,$c7,$63,$31,$19,$19,$19,$0c
        .byte   $00,$bb,$8a,$08,$0c,$84,$84,$84
        .byte   $00,$fd,$65,$20,$30,$30,$10,$18
        .byte   $00,$80,$80,$c0,$c0,$20,$20,$10
        .byte   $00,$00,$00,$00,$00,$05,$2a,$00
        .byte   $00,$00,$00,$00,$00,$ff,$ff,$00
        .byte   $06,$0c,$1f,$00,$00,$ff,$ff,$00
        .byte   $31,$63,$e7,$00,$00,$ff,$ff,$00
        .byte   $18,$18,$8f,$00,$00,$ff,$ff,$00
        .byte   $46,$c6,$8f,$00,$00,$ff,$ff,$00
        .byte   $18,$18,$3c,$00,$00,$ff,$ff,$00
        .byte   $30,$30,$78,$00,$00,$ff,$ff,$00
        .byte   $46,$66,$5c,$00,$00,$ff,$ff,$00
        .byte   $06,$03,$01,$00,$00,$ff,$ff,$00
        .byte   $0c,$18,$f0,$00,$00,$ff,$ff,$00
        .byte   $86,$c6,$7c,$00,$00,$ff,$ff,$00
        .byte   $08,$0c,$1e,$00,$00,$ff,$ff,$00
        .byte   $00,$18,$18,$00,$00,$ff,$ff,$00
        .byte   $00,$00,$00,$00,$00,$ff,$ff,$00
        .byte   $00,$00,$00,$00,$00,$a0,$54,$00

shadow_nw:
        .byte   $08,$00,$00,$40,$00,$00,$40,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0
        .byte   $00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00
        .byte   $00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00
        .byte   $c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$00
shadow_w:
        .byte   $c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0
        .byte   $00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00
        .byte   $00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00
        .byte   $c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$00
shadow_sw:
        .byte   $c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0
        .byte   $00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00
        .byte   $00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00,$c0,$00,$00
        .byte   $c8,$00,$00,$e0,$00,$00,$f0,$00,$00,$7f,$ff,$ff,$3f,$ff,$ff,$00
shadow_s:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff,$ff,$ff,$00
shadow_se:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$02,$00,$00,$00,$00,$00,$01,$ff,$ff,$fe,$ff,$ff,$fc,$00
shadow_ne:
        .byte   $00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

shadow_loc:
        .byte   $77,$51,$77,$66,$77,$90,$77,$ba,$8f,$ba,$bf,$ba,$de,$ba,$de,$51
        .byte   $00

shadow_pat:
        .byte   $c0,$c1,$c1,$c2,$c3,$c3,$c4,$c5
.scend
