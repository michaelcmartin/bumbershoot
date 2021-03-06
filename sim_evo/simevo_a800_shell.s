        .alias  dlist   bitmap-$0100

        .data
        .org    bssstart
        .text

        jsr     do_title
        jsr     enter_bitmap

        ;; Initialize
        lda     $d20a           ; RANDOM
        jsr     srnd

        jsr     init_bacteria
        jsr     init_bugs

mainlp: jsr     run_step
        ldx     #$00
        stx     $4d             ; Disable screensaver
        lda     numbugs
        cmp     #100
        bcs     hundreds
        stx     pop
        cmp     #10
        bcs     tens
        stx     pop+1
ones:   clc
        adc     #$10
        sta     pop+2
        jmp     mainlp
hundreds:
        ldx     #$10
*       inx
        sec
        sbc     #100
        cmp     #100
        bcs     -
        stx     pop
tens:   ldx     #$10
*       inx
        sec
        sbc     #10
        cmp     #10
        bcs     -
        stx     pop+1
        bcc     ones

;;; We put our text mode display list near the top so that we do not
;;; risk overflowing a 4KB limit. Also, this text looks weird because
;;; it is actually Atari screen codes, which only match up with ASCII
;;; for lowercase letters
header: .byte   0,0,"3imulated",0,"%volution",0,0,0,0,0,0,0,0,0
        .byte   "0op",26,0
pop:    .byte   0,0,0,0,0
footer: .byte   0,0,0,"5se",0,"joystick",0,92,15,93,0,"to",0
        .byte   "scroll",0,"display",0,0,0
        .byte   0,0,"0ress",0,39,0,"to",0,"toggle",0,"the",0
        .byte   "'arden",0,"of",0,"%den",0,0

do_title:
        ldx     #$01
        stx     $02f0           ; Disable cursor
        dex                     ; Channel 0 (E:)
        lda     #$0b
        sta     $0342,x
        lda     #<title_msg
        sta     $0344,x
        lda     #>title_msg
        sta     $0345,x
        lda     #<[title_end-title_msg]
        sta     $0348,x
        lda     #>[title_end-title_msg]
        sta     $0349,x
        jsr     $e456
        lda     #$ff
        sta     $02fc
*       ldx     $02fc           ; Wait for keypress
        inx
        beq     -
        lda     #$ff
        sta     $02fc           ; Consume keypress
        rts
title_msg:
        .byte   125,155,155,155,155
        .byte   "      ",160,160,160,160,160,160,160,160,160,160,160,160
        .byte   160,160,160,160,160,160,160,160,160,160,160,160,155
        .byte   "      ",160,160,211,201,205,213,204,193,212,197,196,160
        .byte   160,197,214,207,204,213,212,201,207,206,160,160,155
        .byte   "      ",160,160,160,160,160,160,160,160,160,160,160,160
        .byte   160,160,160,160,160,160,160,160,160,160,160,160,155
        .byte   155,155,155,"          Atari edition by",155
        .byte   "        Michael Martin, 2021",155,155
        .byte   "          Original program",155
        .byte   "        Michael Palmiter and",155
        .byte   "        Martin Gardner, 1989",155
        .byte   155,155,155
        .byte   "     ",160,160,208,210,197,211,211,160,193,206,217
        .byte   160,203,197,217,160,212,207,160,194,197,199,201,206,160
        .byte   160
title_end:

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
        cpy     #$0a
        bne     -
        lda     #$0d
        ldy     #$00
*       sta     dlist, x
        inx
        iny
        cpy     #82
        bne     -
        ldy     #$00
*       lda     _dlst1, y
        sta     dlist, x
        inx
        iny
        cpy     #$07
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

        ;; Draw 5-pixel arena border
        lda     #<bitmap
        sta     $a0
        lda     #>bitmap
        sta     $a1
        ldx     #100
*       lda     #$c0
        ldy     #$01
        sta     ($a0),y
        dey
        lda     #$ff
        sta     ($a0),y
        ldy     #$27
        sta     ($a0),y
        dey
        lda     #$03
        sta     ($a0),y
        clc
        lda     $a0
        adc     #$28
        sta     $a0
        lda     $a1
        adc     #$00
        sta     $a1
        dex
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

_dlst0: .byte   $70, $70, $70, $42, <header, >header
        .byte   $4d, <bitmap, >bitmap, $8d
_dlst1: .byte   $42, <footer, >footer, $02, $41, <dlist, >dlist

irq:    pha
        lda     $0278
        pha
        and     #$01
        bne     +
        lda     _y_scr          ; Already at top?
        beq     +
        dec     _y_scr
        sec
        lda     dlist+7
        sbc     #$28
        sta     dlist+7
        lda     dlist+8
        sbc     #$00
        sta     dlist+8
*       pla
        and     #$02
        bne     +
        lda     _y_scr
        cmp     #$10
        beq     +
        inc     _y_scr
        clc
        lda     dlist+7
        adc     #$28
        sta     dlist+7
        lda     dlist+8
        adc     #$00
        sta     dlist+8
*       lda     $02fc           ; read keyboard
        and     #$3f            ; Strip SHIFT/CTRL
        cmp     #$3d            ; Was 'G' pressed?
        bne     +
        lda     garden          ; If so, toggle garden
        eor     #$01
        sta     garden
        lda     #$ff            ; Consume keypress
        sta     $02fc
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
