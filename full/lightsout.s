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
        lda     #$00            ; Clear keyboard buffer
        sta     $c6
        lda     #<bye
        ldx     #>bye
        jsr     multistr
        jmp     ($a002)         ; Back to BASIC

        .scope
initpuzzle:
        lda     #$ff
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
        cpy     #$0a
        bne     _lp
        ldy     #$00
        clc
        lda     #$50
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
        lda     #$ff
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
        cpy     #$0a
        bne     _lp
        ldy     #$00
        clc
        lda     #$50
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

point:  lda     #$ff
        sta     $fb
        lda     #$04
        sta     $fc
        cpy     #$00
        beq     _px
_pylp:  clc
        lda     #$50
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
        rts

flip:   cpx     #$05
        bcs     _bad
        cpy     #$05
        bcs     _bad
        jsr     point
        lda     ($fb),y
        eor     #$80
        sta     ($fb),y
        bmi     _fon
        lda     #$0b
        .byte   $2c             ; BIT Absolute; skip next instruction
_fon:   lda     #$0a
        pha
        lda     $fc
        eor     #$dc
        sta     $fc
        pla
        sta     ($fb),y
_bad:   rts

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
        
.scope
screen: .word   _clr,_spc,_name,_spc,_top,_spc,_let,_mid,_spc
        .word   _let,_mid,_spc,_let,_mid,_spc,_let,_mid,_spc
        .word   _let,_bot,0
stclr:  .word   _stat,_spc,_spc20,_spc,_spc20,_spc,_spc20,0
stinst: .word   _stat, _inst,0
stwait: .word   _stat, _wait,0
stwin:  .word   _stat, _win,0
bye:    .word   _bye,0
_clr:   .byte   147,13,0
_name:  .byte   $97,"L",$98,"I",$9b,"G",$05,"HTS O"
        .byte   $9b,"U",$98,"T",$97,"!",13,13,$9b,0
_let:   .byte   $dd,$20,$dd,$20,$dd,$20,$dd,$20,$dd,$20,$dd
_spc:   .byte   13,"              ",0
_mid:   .byte   $ab,$c0,$db,$c0,$db,$c0,$db,$c0,$db,$c0,$b3,0
_top:   .byte   $b0,$c0,$b2,$c0,$b2,$c0,$b2,$c0,$b2,$c0,$ae,0
_bot:   .byte   $ad,$c0,$b1,$c0,$b1,$c0,$b1,$c0,$b1,$c0,$bd,0
_stat:  .byte   $13,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d
        .byte   $0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,$0d,0
_spc20: .byte   "                         ",0
_inst:  .byte   13,"         PRESS LETTERS TO MOVE",13
        .byte   "        PRESS F1 FOR NEW PUZZLE",13
        .byte   "         PRESS RUN/STOP TO END",0
_wait:  .byte   13,13,$99,"    PLEASE WAIT, CREATING PUZZLE...",$9b,0
_win:   .byte   13,"       CONGRATULATIONS, YOU WIN!",13,13
        .byte   "           PLAY AGAIN (Y/N)?",0
_bye:   .byte   $93,$9a,13,"THANKS FOR PLAYING!",13
        .byte   "   -- MICHAEL MARTIN, 2015",13,0
.scend
