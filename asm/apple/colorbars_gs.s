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

        ;; Enter Super Hi-Res mode
        lda     #$c0
        tsb     $c029

        ;; Clear the screen, set 320/palette 0 across the board
        lda     #$00
        ldx     #$2000
        ldy     #$7dc8
        jsr     slab

        ;; Load palettes
        .a16
        phb                     ; MVN trashes DBR
        rep     #$20
        lda     #$003f
        ldx     #palettes
        ldy     #$9e00
        mvn     #$00,#$e1
        sep     #$20
        plb                     ; Restore DBR
        .a8

        ;; Draw the color bars
        ldy     #$00c8          ; Line count
        ldx     #$2000          ; Screen pointer
line:   phy
        lda     #$00
bar:    ldy     #$000a
        jsr     slab
        clc
        adc     #$11
        bcc     bar
        ply
        dey
        bne     line

        jsr     key

        ;; Swap to other palette
        lda     #$01
        ldx     #$9d00
        ldy     #$00c8
        jsr     slab
        jsr     key

        ;; Split-screen palette
        lda     #$00
        ldx     #$9d00
        ldy     #$0064
        jsr     slab
        jsr     key

        ;; Leave super-high-res, restore emulation mode
        lda     #$c0
        trb     $c029
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

        ;; Blit Y (16) copies of A (8) to X (16) in bank E1.
        ;; A and Y are unchanged; X points just past the last byte written.
slab:   sta     $e10000,x
        phb                     ; MVN trashes DBR
        pha
        phy
        rep     #$20
        tya
        dec     a
        dec     a
        txy
        iny
        mvn     #$e1,#$e1
        tyx
        sep     #$20
        ply
        pla
        plb
        rts

palettes:
        ;; QuickDraw II palette
        .word   $0000, $0777, $0841, $072c, $000f, $0080, $0f70, $0d00
        .word   $0fa9, $0ff0, $00e0, $04df, $0daf, $078f, $0ccc, $0fff
        ;; CGA palette
        .word   $0000, $000a, $00a0, $00aa, $0a00, $0a0a, $0a50, $0aaa
        .word   $0555, $055f, $05f5, $05ff, $0f55, $0f5f, $0ff5, $0fff
