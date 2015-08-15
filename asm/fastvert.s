;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; "Fast Vertical Split". We're scrolling vertically on the top and
;;; horizontally on the bottom. There are no lines for a "fudge
;;; factor" here - our bottom part begins at exactly its first line
;;; with no flicker or other disruption.
;;;
;;; However, we are cheating a little here to make our first cut at
;;; it easier. We're scrolling two lines per frame, and we're synced
;;; with the bottom part so that we never have to worry about having
;;; our last line be just one pixel tall. (The timing of raster lines
;;; is different on those, and we normally wouldn't have time to
;;; react without flickering.) We stop cheating in slowvert.s.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PRG and BASIC loader
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        .outfile "fastvert.prg"
        .byte $01,$08,$0b,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00
        .org $080d
        jmp     main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        .alias  yscroll   $fb
        .alias  xscroll   $fc
        .alias  main_done $fd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Screen interrupt ($0810)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

irq:    lda     #$01            ; 2
        sta     $d019           ; 6
        nop                     ; 8
        ldx     #$f4            ; 10
        ldy     #$1b            ; 12
        lda     xscroll         ; 15
        sta     $d016           ; 19 horiz scroll (earliest safe)
        sty     $d011           ; 23 vert scroll
        stx     $d018           ; 27 video matrix
        ;; Now wait 65*9-40 cycles to make sure we're off the screen.
        ldx     #$6d
zzz:    dex
        bne     zzz
        ;; Which means now it's time for what would otherwise be a
        ;; separate top-of-screen IRQ.
topirq: ldx     xscroll         ; Scroll the horizontal 1 left
        dex
        txa
        and     #$07
        sta     xscroll

        lda     yscroll         ; Scroll the vertical 2 down
        clc
        adc     #$02
        and     #$07
        sta     yscroll
        ora     #$10            ; Add the display-enable bit
        sta     $d011           ; And actually set vertical scroll
        lda     #$07            ; Then set top-screen horiz scroll
        sta     $d016
        lda     #$14            ; And the video matrix
        sta     $d018

        ;; Check for a keypress so we can quit as needed
        ;; This is here instead of in main to tighten IRQ timing
        jsr     $ffe4           ; GETIN
        sta     main_done


        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Main program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        .checkpc $0900

main:   lda     #$03            ; Start at default scroll level
        sta     yscroll
        lda     #$00
        sta     xscroll
        sta     main_done
        ;; Fill screen at $0400 with A and bottom of $3c00 with B.
        ldx     #$00
scinit: lda     #$01
        sta     $0400,x
        sta     $0500,x
        sta     $0600,x
        sta     $06e8,x
        lda     #$02
        sta     $3ee8,x
        inx
        bne     scinit

        ;; Set up interrupts
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$f2
        sta     $d012
        lda     #<irq
        sta     $314
        lda     #>irq
        sta     $315
        lda     #$01
        sta     $d01a

        ;; Wait for a key
wait:   lda     main_done
        beq     wait

        ;; Restore interrupt vectors
        lda     #$00
        sta     $d01a
        lda     #$31
        sta     $314
        lda     #$ea
        sta     $315
        lda     #$81
        sta     $dc0d

        ;; Restore default VIC-II settings
        lda     #$1b
        sta     $d011
        lda     #$08
        sta     $d016
        lda     #$14
        sta     $d018

        ;; Clear screen and return to BASIC
        lda     #$93
        jmp     $ffd2
