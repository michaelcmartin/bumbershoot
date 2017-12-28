        .alias  chrout  $ffd2
        .alias  getin   $ffe4
        .alias  stop    $ffe1
        
        .word   $0801
        .org    $0801

        .data
        .org    $4000
        .text
        
        ;;  BASIC program that just calls our machine language code
.scope
        .word   _next, 2015     ; Next line and current line number
        .byte   $9e," 2062",0   ; SYS 2062
_next:  .word   0               ; End of program
.scend
        jsr     randomize
        
        ;; Black screen
        lda     #$00
        sta     $d020
        sta     $d021
        ;; Red for BG Color 2
        lda     #$02
        sta     $d023
        ;; Copy over character set so we can have graphics for ECM
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
        ldy     #$3f
*       lda     gfx, y
        sta     $2190, y
        dey
        bpl     -
        ;; Enable ECM and custom graphics
        lda     #$db
        sta     $d011
        lda     #$18
        sta     $d018
        ;; Draw screen
        lda     #<screen
        ldx     #>screen
        jsr     multistr

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
        jsr     move
        jsr     wonpuzzle
        bmi     mainlp
        ;; Victory!
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
        lda     #$9b            ; Disable ECM
        sta     $d011
        lda     #$14            ; Restore normal charset
        sta     $d018
        lda     #$00            ; Clear keyboard buffer
        sta     $c6
        lda     #<bye
        ldx     #>bye
        jsr     multistr
        jmp     ($a002)         ; Back to BASIC

        .scope
initpuzzle:
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
        stx     $4000
_rlp:   lda     #$19
        jsr     get_rnd
        jsr     move
        inc     $4000
        bne     _rlp
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

move:   jsr     rowcol
        stx     $fd
        sty     $fe
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

.scope
randomize:
        jsr     $ffde           ; RDTIM
        sty     $63
        stx     $64
        sta     $65
        ldy     #$00
        sta     $62
        sta     $68
        jsr     $bcd5           ; Turn QINT to FAC1, sort of
        lda     #$ff
        sta     $66             ; Force sign negative
        jsr     $e097           ; RND(FAC1)
        ;; Something about this RND call is wrecking the state of the
        ;; FAC system, so we reset it all to 0s and this seems to fix
        ;; stuff.
        ldx     #$10            ; Clear out both FACs
        lda     #$00
_lp:    sta     $60,x
        dex
        bne     _lp
        rts

get_rnd:
        pha
        lda     #$01            ; Accumulator = 1
        jsr     $bc3c           ; FAC1 = accumulator
        jsr     $e097           ; FAC1 = RND(FAC1)
        jsr     $bc0c           ; FAC2 = FAC1 (rounded)
        pla                     ; Accumulator = argument
        jsr     $bc3c           ; FAC1 = accumulator
        jsr     $ba2b           ; FAC1 = FAC2 * FAC1
        jsr     $bccc           ; FAC1 = INT(FAC1)
        jsr     $b1aa           ; .YA = FAC1
        tya
        rts
.scend

        ;; 207, 183, 208  - $cf, $b7, $d0
        ;; 165,  32, 170  - $a5, $d0, $aa
        ;; 204, 175, 186  - $cc, $af, $ba
.scope
screen: .word   _clr,_name,_row,_row,_row,_row,_row,0
stclr:  .word   _stat,_spc38,_spc38,_spc38,0
stinst: .word   _stat, _inst,0
stwait: .word   _stat, _wait,0
stwin:  .word   _stat, _win,0
bye:    .word   _bye,0
_clr:   .byte   147,13,0
_name:  .byte   13,"              ",$97,"L",$98,"I",$9b,"G",$05,"HTS O"
        .byte   $9b,"U",$98,"T",$97,"!",13,13,$9b,0
_row:   .byte   "            234234234234234",13
        .byte   "            5 65 65 65 65 6",13
        .byte   "            789789789789789",13,0
_stat:  .byte   $13,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
        .byte   $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,0
_spc38: .byte   13,"                                      ",0
_inst:  .byte   13,"         PRESS LETTERS TO MOVE",13
        .byte   "        PRESS F1 FOR NEW PUZZLE",13
        .byte   "         PRESS RUN/STOP TO END",0
_wait:  .byte   13,13,$99,"    PLEASE WAIT, CREATING PUZZLE...",$9b,0
_win:   .byte   13,"       CONGRATULATIONS, YOU WIN!",13,13
        .byte   "           PLAY AGAIN (Y/N)?",0
_bye:   .byte   $93,$9a,13,"THANKS FOR PLAYING!",13
        .byte   "   -- MICHAEL MARTIN, 2017",13,0

gfx:    .byte   $ff,$ff,$e0,$c0,$c0,$c0,$c0,$c0
        .byte   $ff,$ff,$00,$00,$00,$00,$00,$00
        .byte   $ff,$ff,$07,$03,$03,$03,$03,$03
        .byte   $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
        .byte   $03,$03,$03,$03,$03,$03,$03,$03
        .byte   $c0,$c0,$c0,$c0,$c0,$e0,$ff,$ff
        .byte   $00,$00,$00,$00,$00,$00,$ff,$ff
        .byte   $03,$03,$03,$03,$03,$07,$ff,$ff
.scend
