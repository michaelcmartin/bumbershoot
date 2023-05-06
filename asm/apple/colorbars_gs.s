;;; ----------------------------------------------------------------------
;;;  Super High-Res Color Bars for the Apple IIgs
;;;  This is a ProDOS 8 program, to be built with ca65. To build and
;;;  link, run these two commands:
;;;     ca65 colorbars_gs.s
;;;     ld65 -t none -o colors.system#ff2000 colorbars_gs.o
;;; ----------------------------------------------------------------------

        .p816
        .a8
        .i16
        .org    $2000

        ;; Leave emulation mode, 8-bit accumulator/memory, 16-bit indices
        clc
        xce
        rep     #$10
        sep     #$20

        ;; Enter Super Hi-Res mode
        lda     #$c0
        tsb     $c029

        ;; Save original data bank, change it to $E1
        phb
        lda     #$e1
        pha
        plb

        ;; Clear the screen, set 320/palette 0 across the board
        ldx     #$7dc7
:       stz     $2000,x
        dex
        bpl     :-

        ;; Load palettes
        ldx     #$003f
:       lda     f:palettes,x
        sta     $9e00,x
        dex
        bpl     :-

        ;; Draw the color bars
        ldx     #$00c8          ; Line count
        ldy     #$0000          ; Screen pointer
line:   phx
        lda     #$00
bar:    ldx     #$000a
:       sta     $2000, y
        iny
        dex
        bne     :-
        clc
        adc     #$11
        bcc     bar
        plx
        dex
        bne     line

        jsr     key

        ;; Swap to other palette
        ldx     #$00c7
        lda     #$01
:       sta     $9d00,x
        dex
        bpl     :-

        jsr     key

        ;; Split-screen palette
        ldx     #$0063
:       stz     $9d00,x
        dex
        bpl     :-

        jsr     key

        ;; Leave super-high-res, restore data bank and emulation mode
        lda     #$c0
        trb     $c029
        plb
        sec
        xce

	;; Return to ProDOS
	jsr	$bf00
	.byte	$65
	.word	:+
	brk				; Unreachable
:       .byte	4
	.byte	0, 0, 0, 0, 0, 0

        ;; Wait for keypress
key:    bit     $c000
        bpl     key
        bit     $c010
        rts

palettes:
        ;; QuickDraw II palette
        .word   $0000, $0777, $0841, $072c, $000f, $0080, $0f70, $0d00
        .word   $0fa9, $0ff0, $00e0, $04df, $0daf, $078f, $0ccc, $0fff
        ;; CGA palette
        .word   $0000, $000a, $00a0, $00aa, $0a00, $0a0a, $0a50, $0aaa
        .word   $0555, $055f, $05f5, $05ff, $0f55, $0f5f, $0ff5, $0fff
