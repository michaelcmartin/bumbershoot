;;; ----------------------------------------------------------------------
;;;   EGA demo screen for the Apple IIgs
;;;   Build with this command:
;;;      ca65 ega_gs.s && ld65 -t none -o EGA.GRID#ff2000 ega_gs.o
;;; ----------------------------------------------------------------------
        .p816
        .a8
        .i16
        .org    $2000

        ;; Leave emulation mode, 8-bit accumulator/memory, 16-bit indices
        clc
        xce
        phb
        rep     #$10

        ;; Enter Super Hi-Res mode
        lda     #$c0
        tsb     $c029

        ;; Clear the screen
        lda     #$00
        sta     $e12000
        rep     #$20
        .a16
        lda     #$7cfe
        ldx     #$2000
        txy
        iny
        mvn     #$e1,#$e1

        ;; Load 9 palettes
        lda     #$011f
        ldx     #palettes
        ldy     #$9e00
        mvn     #$00,#$e1
        sep     #$20
        .a8

        ;; Select the control codes for each line: $80 for the top and
        ;; bottom 8, then 23 lines of 1-8 each. Two lines of 80-col
        ;; text, and the rest is 16-color graphics
        lda     #$80
        ldx     #$0000
        ldy     #8
:       sta     $9d00,x
        sta     $9dc0,x
        inx
        dey
        bne     :-

        lda     #$01            ; .X is 8 here, which we want
:       ldy     #23
:       sta     $9d00,x
        inx
        dey
        bne     :-
        inc     a
        cmp     #$09
        bne     :--

        ;; Thanks to the last MVN instruction, the DBR is now
        ;; #$E1. Fortunately for us, that's exactly where we want it!

        ldy     #64
        ldx     #$05b1
        lda     #$11
draw_grid:
        jsr     box
        clc
        adc     #$11
        cmp     #$99
        bne     @right
        rep     #$21
        .a16
        txa
        adc     #$df0
        tax
        sep     #$20
        .a8
        lda     #$11
        bra     @next
@right: pha
        rep     #$21
        .a16
        txa
        adc     #$0010
        tax
        sep     #$20
        .a8
        pla
@next:  dey
        bne     draw_grid

        ;; Wait for keypress
:       bit     $c000
        bpl     :-
        bit     $c010

        ;; Leave Super Hi-Res mode
        lda     #$c0
        trb     $c029

        ;; Back to ProDOS
        plb
        sec
        xce
	jsr	$bf00
	.byte	$65
	.word	:+
	brk				; Unreachable
:       .byte	4
	.byte	0, 0, 0, 0, 0, 0

;;; Draw a bordered box with fill pattern .A(8) at screen address
;;; .X(16).
box:    phy
        phx
        phx
        pha
        lda     #$ff
        ldy     #14
:       sta     $2000,x
        sta     $2c80,x
        inx
        dey
        bne     :-
        lda     #19
        pha
@line:  rep     #$21
        .a16
        lda     3,s
        adc     #160
        sta     3,s
        tax
        sep     #$20
        .a8
        lda     #$ff
        sta     $2000,x
        sta     $200d,x
        lda     2,s
        inx
        ldy     #$0c
:       sta     $2000,x
        inx
        dey
        bne     :-
        lda     1,s
        dec     a
        sta     1,s
        bne     @line
        pla
        pla
        plx
        plx
        ply
        rts

palettes:
        ;; Palette 0: For our 640x480 mode, black-red-green-white
        .word   $0000,$0f00,$00f0,$0fff,$0000,$0f00,$00f0,$0fff
        .word   $0000,$0f00,$00f0,$0fff,$0000,$0f00,$00f0,$0fff
        ;; Palettes 1-8: The full EGA palette, in order, in indices
        ;; 1-8 in each palette. Color 0 is always black and 15 is
        ;; always white.
        .word   $0000,$0000,$000a,$00a0,$00aa,$0a00,$0a0a,$0aa0
        .word   $0aaa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0005,$000f,$00a5,$00af,$0a05,$0a0f,$0aa5
        .word   $0aaf,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0050,$005a,$00f0,$00fa,$0a50,$0a5a,$0af0
        .word   $0afa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0055,$005f,$00f5,$00ff,$0a55,$0a5f,$0af5
        .word   $0aff,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0500,$050a,$05a0,$05aa,$0f00,$0f0a,$0fa0
        .word   $0faa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0505,$050f,$05a5,$05af,$0f05,$0f0f,$0fa5
        .word   $0faf,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0550,$055a,$05f0,$05fa,$0f50,$0f5a,$0ff0
        .word   $0ffa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0555,$055f,$05f5,$05ff,$0f55,$0f5f,$0ff5
        .word   $0fff,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
