        .word   $0801
        .org    $0801
        .outfile "diffusion.prg"

        .word   +, 2018
        .byte   $9e," 2062",0
*       .word   0

        .data
        .org    $c000
        .text

        lda     #$00
        sta     $d020
        sta     $d021
        lda     #<h1msg
        ldy     #>h1msg
        jsr     $ab1e
        lda     #<h2msg
        ldy     #>h2msg
        jsr     $ab1e
        lda     #<tab9
        ldy     #>tab9
        jsr     $ab1e
        lda     #<h3msg
        ldy     #>h3msg
        jsr     $ab1e
        lda     #<tab11
        ldy     #>tab11
        jsr     $ab1e
        lda     #<gtop
        ldy     #>gtop
        jsr     $ab1e
        lda     #$0f
        sta     $fb
*       lda     #<tab11
        ldy     #>tab11
        jsr     $ab1e
        lda     #<gmid
        ldy     #>gmid
        jsr     $ab1e
        dec     $fb
        bne     -
        lda     #<tab11
        ldy     #>tab11
        jsr     $ab1e
        lda     #<gbot
        ldy     #>gbot
        jsr     $ab1e

        jsr     $ffde
        jsr     srnd

main:   jsr     rnd
        jsr     anchor
        ldy     #$28
        lda     ($fb), y
        and     #$0f
        beq     next
        cmp     #$01
        beq     next
        sta     $fd
        lda     rndval+1
        and     #$03
        tay
        lda     offs, y
        tay
        lda     ($fb), y
        and     #$0f
        bne     next
        lda     $fd
        sta     ($fb), y
        ldy     #$28
        lda     #$00
        sta     ($fb), y

next:   jsr     $ffe4
        beq     main

        lda     #$0e
        sta     $d020
        lda     #$06
        sta     $d021
        lda     #<fin
        ldy     #>fin
        jmp     $ab1e

        ;; Find the anchor point for a given location and load it into
        ;; $fb-$fc. The anchor point is $d8ac+(40*y)+x. The argument is
        ;; passed in the accumulator as (16*y)+x.
        ;;
        ;; Trashes the accumulator, result in $fb-$fc, no other
        ;; registers or memory are touched.
anchor: pha
        and     #$0f            ; .A = X
        clc
        adc     #$ac            ; Never carries; max value here is $bb
        sta     $fb
        lda     #$d8
        sta     $fc
        pla
        and     #$f0
        pha
        lsr                     ; .A = Y*8
        clc
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        pla
        asl                     ; .A = Y*32, with carry holding MSB
        pha
        lda     #$00
        adc     $fc
        sta     $fc
        pla
        clc
        adc     $fb
        sta     $fb
        lda     #$00
        adc     $fc
        sta     $fc
        rts

        .include "../asm/xorshift.s"

        ;; Strings to be printed out to draw the board. Some strings
        ;; are suffixes of other ones.
h1msg:  .byte   5,147
tab11:  .byte   "  "
tab9:   .byte   "         ",0
h2msg:  .byte   "DIFFUSION CHAMBER",13,0
h3msg:  .byte   "PRESS ANY KEY TO QUIT",13,17,17,0
gtop:   .byte   176,195,195,195,195,195,195,195
        .byte   195,195,195,195,195,195,195,195,174,13,0
gmid:   .byte   5,221,18,28,"       ",144," "
        .byte   30,"       ",146,5,221,13,0
gbot:   .byte   173,195,195,195,195,195,195,195
        .byte   195,195,195,195,195,195,195,195,189,13,0
fin:    .byte   154,147,0
        ;; Offsets from the position above the target cell to reach
        ;; cell N/W/E/S of target cell.
offs:   .byte   $00,$27,$29,$50
