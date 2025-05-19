;;; Bumbershoot Software intro (logo/sound)
;;; This routine includes a skip to a 32KB boundary so it's probably best
;;; to put it at the very end of any given project

        include "8k_dac.s"

BumbershootLogo:
        movem.l d2/a2-a4, -(sp)

        movea.l #$C00000, a3
        movea.l a3, a4
        addq    #4, a4

        ;; Load logo into VRAM
        move.w  #$8f02, (a4)
        move.l  #$40200000, (a4)
        movea.l #.logo, a2
        move.w  #((.logoend-.logo) / 4)-1,d0
.lp:    move.l  (a2)+, (a3)
        dbra    d0, .lp

        ;; Load some colors into VRAM
        move.l  #$c0000000, (a4)
        movea.l #.pal, a2
        moveq   #7, d0
.lp2:   move.l  (a2)+, (a3)
        dbra    d0, .lp2

        ;; Lay out the logo, starting at (10, 1)
        move.l  #$40940003, (a4)
        moveq   #$1, d2         ; Tile counter
        moveq   #$18, d0        ; 25 rows
.row:   moveq   #$13, d1        ; 20 columns
.rlogo: move.w  d2, (a3)
        addq    #1, d2
        dbra    d1, .rlogo
        moveq   #$2b, d1        ; 44 blanks to start of next row
.rblnk: move.w  #$0000, (a3)
        dbra    d1, .rblnk
        dbra    d0, .row

        ;; Enable the display
        move.w  #$8144, (a4)

        ;; Set up the sample player
        bsr     SetupDAC

        ;; Sing a song
        move.w  #.logosong_end-.logosong, -(sp)
        move.l  #.logosong, -(sp)
        bsr     PlaySample
        addq    #6, sp

        ;; Wait 240 frames
        move.w  #240, d1
.v1:    move.w  (a4), d0
        btst    #3, d0          ; Wait for no VBLANK
        bne.s   .v1
.v2:    move.w  (a4), d0
        btst    #3, d0          ; Wait for VBLANK
        beq.s   .v2
        dbra    d1, .v1

        ;; Clear screen
        move.l  #$40940003, (a4)
        move.w  #$400, d1
        moveq   #$00, d0
.cls:   move.l  d0, (a3)
        dbra    d1, .cls

        movem.l (sp)+, d2/a2-a4
        rts

.pal:   dc.w    $0000,$0422,$0442,$0642,$0666,$0884,$0864,$0A86
        dc.w    $0AAA,$0CCA,$0ECC,$0EEE,$0EEC,$0000,$0000,$0000

.logo:
        incbin  "res/logogfx.bin"
.logoend:

        ;; Put our sound sample on a 32KB boundary so the Z80 can see
        ;; it all at once
        org     (*+$7fff)&$ff8000
.logosong:
        incbin  "res/bumbersong.bin"
.logosong_end:
