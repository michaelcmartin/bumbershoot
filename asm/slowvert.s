;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; "Slow Vertical Split". This is the true test of vertical split
;;; screen scrolling. We will scroll the top part of the screen by
;;; one line per frame, thus including one frame out of every 8 where
;;; a line is only one pixel tall. We combine this with a horizontal
;;; scrolling effect on the bottom part.
;;;
;;; This does not include effects you would normally want to do with
;;; this, like actually putting new data to scroll in from the top
;;; or right; this is purely to show the split-screen effect with no
;;; fudge factors.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PRG and BASIC loader
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        .outfile "slowvert.prg"
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
;;; Screen interrupt
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; There is a different interrupt prelude when raster $F2 is a
;;; badline. We instead trigger the raster at $F1, and we wait for
;;; 46 cycles post-IRQ setup to get us from $F1 to a point in $F2
;;; where we may safely re-trigger the badline.

        ;; The usual case, where raster $F2 is not a badline.
irq_f2: jmp     i_main          ;  3

        ;; And the longer case, where it is and we start a line back
irq_f1: ldx     #$05            ;    ( 2)
f1_lp:  dex                     ;    (12) [2*5 = 10]
        bne     f1_lp           ;    (26) [3*5-1 = 14]

i_main: lda     #$01            ;  5 (28)
        sta     $d019           ;  9 (32)
        ldx     #$f4            ; 11 (34)
        ldy     #$1b            ; 13 (36)
        lda     xscroll         ; 16 (39)
        sta     $d016           ; 20 (43) Writes begin here,,,
        sty     $d011           ; 24 (47)
        stx     $d018           ; 28 (51) ... and end here

        ;; Now wait 65*9-40 cycles to make sure we're off the screen.
        ldx     #$6d
zzz:    dex
        bne     zzz

        ;; Which means now it's time for the top-of-screen IRQ.
topirq: ldx     xscroll         ; Scroll left 2
        dex
        dex
        txa
        and     #$07
        sta     xscroll

        inc     yscroll         ; And down 1
        lda     yscroll
        and     #$07
        sta     yscroll
        ora     #$10            ; Set the vertical scroll
        sta     $d011
        cmp     #$12            ; Will $F2 be a bad line?
        beq     do_f1
        lda     #<irq_f2        ; If not, use the $F2 routine
        ldx     #$f2            ; and trigger on $F2
        bne     irqend
do_f1:  lda     #<irq_f1        ; If so, use the equivalents
        ldx     #$f1            ; for $F1
irqend: sta     $314
        stx     $d012
        lda     #$07            ; Set the horiz scroll
        sta     $d016
        lda     #$14            ; and video matrix for the top part
        sta     $d018

        jsr     $ffe4           ; Check for keypresses while we wait
        sta     main_done

        lda     $dc0d           ; Process any timer interrupts that
        beq     notime          ; might have been waiting.
        jmp     $ea31           ; We haven't even hit raster 0 yet,
notime: jmp     $febc           ; so we have plenty of time.

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
        lda     #<irq_f2
        sta     $314
        lda     #>irq_f2
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
