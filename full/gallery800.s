        .outfile "gallery.xex"
        .word   $ffff,start,end-1
        .org    $0700

start:  lda     #$0b
        sta     $0342
        lda     #<msg
        sta     $0344
        lda     #>msg
        sta     $0345
        lda     #<msglen
        sta     $0348
        lda     #>msglen
        sta     $0349
        ldx     #$00
        jsr     $e456

        lda     #$00
        tax
clrpm:  sta     $c00,x
        sta     $d00,x
        sta     $e00,x
        sta     $f00,x
        inx
        bne     clrpm

        lda     #$0c
        sta     $d407                   ; PMBASE
        lda     #$2e
        sta     $22f                    ; SDMACTL
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

msg:    .byte   $9b,$9b,$9b
        .byte   "    PLAYER/MISSILE GRAPHICS TEST",$9b
        .byte   $9b,$9b,$9b,$9b,$9b
        .byte   " This display will eventually be a",$9b
        .byte   "custom playfield showing the score",$9b
        .byte   "and some terrain but for now it is",$9b
        .byte   "just this greeting message.",$9b
        .byte   $9b,$9b

        .alias  msglen  ^-msg

gfx_blaster:
        .byte   $10,$38,$ba,$ba,$fe,$fe,$92
gfx_target:
        .byte   $00,$3c,$42,$5a,$5a,$42,$3c,$00

end:    .word   $02e0,$02e1,start
