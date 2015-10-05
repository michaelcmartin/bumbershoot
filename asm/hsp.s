;;; Horizontal Screen Positioning demo (HSP)
;;; WARNING: On some systems this will interfere with DRAM refresh and
;;;          corrupt the contents of RAM.

        ;; PRG header
        .outfile "hsp.prg"
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

        ;; Clear the idle graphic
        lda     #$00
        sta     $3fff

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
        ;; Constraint: Start on cycle 14 or later. Be *between* characters.
        ;; Start by replicating the rescan.s case, but don't fix the scroll.
irq:    lda     #$01            ; 2
        sta     $d019           ; 6
        bit     $d012           ; 10
        bvs     _split          ; 13
_top_i: ldx     #$1b
        ldy     #$f4
        lda     #$76
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
        ;; Having executed a partial rescan and stabilized our raster,
        ;; wait for the character to complete and to get into the idle
        ;; dead zone between characters
        ldx     #$2d
*       dex
        bne     -
        ;; Then set the scroll value to the current line, which is
        ;; also where we want it to be to fix the scroll value.
        lda     #$1b
        sta     $d011
        ;; Prepare for the next frame
        lda     #$00
        
_done:  sta     $d012
        lda     $dc0d
        beq     _notim
        jmp     $ea31
_notim: jmp     $febc

.scend
