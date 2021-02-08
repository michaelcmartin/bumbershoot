        .alias  dlist   bitmap-$0100

        .data
        .org    bssstart
        .text

        jsr     enter_bitmap

        ;; Initialize
        lda     $d20a           ; RANDOM
        jsr     srnd

        jsr     init_bacteria
        jsr     init_bugs

mainlp: jsr     run_step
        jmp     mainlp

;;; ----------------------------------------------------------------------
;;;   Bitmap support
;;; ----------------------------------------------------------------------
        .scope
        .data
        .space  _y_low  100
        .space  _y_high 100
        .alias  _y_scr  $a6

        .text
enter_bitmap:
        ;; Turn off ANTIC DMA
        lda     $022f
        pha
        lda     #$00
        sta     $022f
        sta     _y_scr

        ;; Build display list
        tax                     ; A is 0
        tay
*       lda     _dlst0, y
        sta     dlist, x
        inx
        iny
        cpy     #$07
        bne     -
        lda     #$0d
        ldy     #$00
*       sta     dlist, x
        inx
        iny
        cpy     #94
        bne     -
        ldy     #$00
*       lda     _dlst1, y
        sta     dlist, x
        inx
        iny
        cpy     #$03
        bne     -

        ;; Clear bitmap
        lda     #>bitmap
        sta     [+]+2
        lda     #$00
        tax
        ldy     #$10
*       sta     bitmap, x
        inx
        bne     -
        inc     [-]+2
        dey
        bne     -

        ;; Set colors
        lda     #$c7
        sta     $02c4
        lda     #$0f
        sta     $02c5
        lda     #$24
        sta     $02c6
        lda     #$93
        sta     $02c8

        ;; Switch to the new display list
        lda     #$00
        sta     $022f
        lda     #<dlist
        sta     $0230
        lda     #>dlist
        sta     $0231

        ;; Enable DLI
        lda     #<irq
        sta     $0200
        lda     #>irq
        sta     $0201
        lda     #$c0
        sta     $d40e

        ;; Re-enable display list
        pla
        sta     $022f

        ;; Create pixel row lookups
        lda     #<bitmap
        sta     _y_low
        lda     #>bitmap
        sta     _y_high
        ldy     #$00
*       clc
        lda     _y_low,y
        adc     #$28
        sta     _y_low+1,y
        lda     _y_high,y
        adc     #$00
        sta     _y_high+1,y
        iny
        cpy     #99
        bne     -
        rts

_dlst0: .byte   $70, $70, $70, $4d, <bitmap, >bitmap, $8d
_dlst1: .byte   $41, <dlist, >dlist

irq:    pha
        lda     $0278
        pha
        and     #$01
        bne     +
        lda     _y_scr          ; Already at top?
        beq     +
        dec     _y_scr
        sec
        lda     dlist+4
        sbc     #$28
        sta     dlist+4
        lda     dlist+5
        sbc     #$00
        sta     dlist+5
*       pla
        and     #$02
        bne     +
        lda     _y_scr
        cmp     #$04
        beq     +
        inc     _y_scr
        clc
        lda     dlist+4
        adc     #$28
        sta     dlist+4
        lda     dlist+5
        adc     #$00
        sta     dlist+5
*       pla
        rti

        ;; .X = X (0-159), .Y = Y (0-99), UNCHECKED
        ;; Puts the target address in ($a0)+y, pixel offset in .X (0 left,
        ;; 3 right). .X also mirrored in $a2.
_find_address:
        lda     _y_low,y
        sta     $a0
        lda     _y_high,y
        sta     $a1
        txa
        lsr
        lsr
        tay
        txa
        and     #$03
        sta     $a2
        tax
        rts

        ;;  .A = color, .X = X (0-159), .Y = Y (0-99)
pset:   cpx     #160            ; Abort immediately if we try
        bcs     _fin            ; to plot off the screen
        cpy     #100
        bcs     _fin
        pha                     ; Stash color
        pha
        sty     $a4
        stx     $a5
        jsr     _find_address
        lda     _mask0,x        ; Erase original color
        and     ($a0),y
        sta     $a3
        pla
        beq     _prset          ; If it's black, we have our value
        asl
        asl                     ; times 4 (carry is now clear)
        adc     $a2             ; Add low 2 bits of X for mask
        tax
        lda     _mask0,x        ; color bits
        ora     $a3
        bne     _psfin          ; always branches

_prset: lda     $a3             ; On reset restore masked value

_psfin: sta     ($a0),y         ; Write updated byte
        ldx     $a5             ; Restore arguments
        ldy     $a4
        pla
_fin:   rts

        ;; .X = X (0-159), .Y = Y (0-99).
        ;; On success, .A holds the color at that location.
        ;; Carry is clear on success.
pread:  cpx     #160            ; Abort immediately if we try
        bcs     _fin            ; to read off the screen
        cpy     #100
        bcs     _fin
        sty     $a4
        stx     $a5
        jsr     _find_address
        lda     ($a0),y
*       cpx     #$03
        beq     +
        lsr
        lsr
        inx
        bne     -
*       and     #$03
        ldy     $a4
        ldx     $a5
        clc
        rts

        ;; Align mask data to 16-byte boundary
        .advance [^+15] & $FFF0
_mask0: .byte   $3f,$cf,$f3,$fc
_mask1: .byte   $40,$10,$04,$01
_mask2: .byte   $80,$20,$08,$02
_mask3: .byte   $c0,$30,$0c,$03
        .scend

        .alias  count   $b0
        .alias  eaten   $b1

;;; ----------------------------------------------------------------------
;;;  Platform-specific callbacks from the core
;;; ----------------------------------------------------------------------

        ;; Dimensions of the usable screen
        .alias  ARENA_WIDTH     150
        .alias  ARENA_HEIGHT    100

draw_bacterium:
        pha
        tya
        pha
        tay
        txa
        pha
        clc
        adc     #$05
        tax
        lda     #$01            ; Bacterium color
        jsr     pset
        pla
        tax
        pla
        tay
        pla
        rts

        .scope
_paint_and_eat:
        pha
        jsr     pread
        cmp     #$01
        bne     +
        inc     eaten
*       pla
        jmp     pset

erase_bug:
        pha
        lda     #$00
        sta     _paint_color
        beq     _paint_bug

draw_bug:
        pha
        lda     #$02
        sta     _paint_color
        ;; fall through to _paint_bug

_paint_bug:
        tya
        pha
        txa
        pha
        ldy     bug_y,x
        lda     bug_x,x
        clc
        adc     #$05
        tax
        lda     #$03
        sta     count
        lda     #$00
        sta     eaten
        .alias  _paint_color ^+1
        lda     #$02
*       jsr     _paint_and_eat
        inx
        jsr     _paint_and_eat
        inx
        jsr     _paint_and_eat
        dex
        dex
        iny
        dec     count
        bne     -
        pla
        tax
        pla
        tay
        ;; At this point, X is the bug number again, so we can use it
        ;; to increase the bug's HP by 40x the number of bacteria it ate
        lda     eaten
        beq     ++
*       jsr     feed_bug
        dec     eaten
        bne     -
*       pla
        rts
        .scend

        .include "simevocore.s"
        .checkpc bssstart
        .data
        .checkpc dlist
        .text
