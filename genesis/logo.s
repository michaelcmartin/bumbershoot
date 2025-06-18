;;; Bumbershoot Software intro (logo/sound)
;;; This routine includes a skip to a 32KB boundary so it's probably best
;;; to put it at the very end of any given project
;;; Both lz4dec.s and 8k_dac.s need to be included in any project that
;;; includes hit

BumbershootLogo:
        move.l  a2,-(sp)

        lea     .logodata,a0
        lea     $ff0000,a1
        bsr.s   lz4dec                  ; Puts amount uncompressed in d0

        lea     $C00000,a0
        lea     4(a0),a2
        lea     $ff0000,a1

        ;; Load palette
        move.w  #$8f02,(a2)             ; VDP increment = 2
        move.l  #$c0000000,(a2)         ; Write to CRAM 0
        moveq   #15,d1
.pallp: move.l  (a1)+,(a0)
        dbra    d1,.pallp

        ;; Load patterns
        sub.l   #$3040,d0               ; Total pattern bytes in d0
        lsr.l   #2,d0                   ; Total pattern longwords
        subq    #1,d0                   ; Adjustment for dbra
        move.l  #$40000000,(a2)         ; Write to VRAM $0000
.patlp: move.l  (a1)+,(a0)
        dbra    d0,.patlp

        ;; Load nametables
        move.l  #$40000003,(a2)         ; Write to VRAM $C000
        move.w  #3071,d0
.namlp: move.l  (a1)+,(a0)
        dbra    d0,.namlp

        ;; Enable the display
        move.w  #$8144,(a2)

        ;; Set up the sample player
        bsr     SetupDAC

        ;; Sing a song
        move.w  #.logosong_end-.logosong,-(sp)
        move.l  #.logosong,-(sp)
        bsr     PlaySample
        addq    #6,sp

        ;; Wait 240 frames
        move.w  #240,d1
.v1:    move.w  (a2),d0
        btst    #3,d0          ; Wait for no VBLANK
        bne.s   .v1
.v2:    move.w  (a2),d0
        btst    #3,d0          ; Wait for VBLANK
        beq.s   .v2
        dbra    d1,.v1

        ;; Clear screen
        move.l  #$40940003,(a2)
        subq    #4,a2
        move.w  #3071,d1
        moveq   #$00,d0
.cls:   move.l  d0,(a2)
        dbra    d1,.cls

        move.l  (sp)+,a2
        rts

.logodata:
        incbin  "res/logogfx.bin"

        ;; Put our sound sample on a 32KB boundary so the Z80 can see
        ;; it all at once
        org     (*+$7fff)&$ff8000
.logosong:
        incbin  "res/bumbersong.bin"
.logosong_end:
