;;; Partial-rescan test program

        ;; PRG header
        .outfile "rescan.prg"
        .word   $0801
        .org    $0801

        ;; BASIC header
        .word   start, 2015
        .byte   $9e, " 2062",0
start:  .word   0

        ;; Create a secondary screen full of Bs at $3c00 for comparison
        lda     #$02
        ldx     #$00
*       sta     $3c00,x
        sta     $3d00,x
        sta     $3e00,x
        sta     $3f00,x
        dex
        bne     -

        ;; Then set up the IRQ and return to BASIC
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$00
        sta     $d012
        lda     #<irq
        sta     $314
        lda     #>irq
        sta     $315
        lda     #$01
        sta     $d01a
        rts

.scope
        ;; Constraint: Start on cycle 14 or later. Be mid-character.
        ;; Start after cycle 65-38+14 = 41
irq:    lda     #$01            ; 2  (Acknowledge Interrupt)
        sta     $d019           ; 6
        bit     $d012           ; 10 (Check for midscreen)
        bvs     _split          ; 13
_top_i: lda     #$06            ; Top of screen: fix background color
        sta     $d021
        ldx     #$1b            ; Fix scroll
        ldy     #$f4            ; Set the video matrix to the all-B case
        lda     #$76            ; And set the mid-screen interrupt
        stx     $d011
        sty     $d018
        bne     _done

_split: lda     #$14            ; 15
        sta     $d018           ; 19
        lda     #$1f            ; 21
        ldx     #$03
*       dex
        bne     -               ; 36
        sta     $d011           ; 41
        ;; Finish this scanline
        nop
        nop
        nop
        ;; Fix scroll
        lda     #$1b
        sta     $d011
        ;; Wait a bit, then change the background so we can see the stabilized raster
        ldx     #$04
*       dex
        bne     -
        inc     $d021

        ;; Wrapup: trigger IRQ at top of screen again, process timer IRQ if needed
        lda     #$00        
_done:  sta     $d012
        lda     $dc0d
        beq     _notim
        jmp     $ea31
_notim: jmp     $febc

.scend
