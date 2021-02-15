        .outfile "simevo.prg"
        .word   $0801
        .org    $0801

        ;; BASIC header
        .word   +, 2020
        .byte   $9e," 2062",$00
*       .word   0

        .data
        .org    $11fe
        .space  count   1
        .space  eaten   1
        .text

        ;; Main program

        lda     #>title_msg
        sta     [+]+2
        ldy     #$00
*       lda     title_msg, y
        beq     +
        jsr     $ffd2
        iny
        bne     -
        inc     [-]+2
        bne     -

        ;; Clear keyboard buffer
*       jsr     $ffe4                   ; GETIN
        bne     -
        ;; Wait for key
*       jsr     $ffe4                   ; GETIN
        beq     -

        ;; Reset console state
        lda     #147
        jsr     $ffd2
        lda     #9
        jsr     $ffd2
        lda     #142
        jsr     $ffd2

        lda     #$20
        jsr     enter_bitmap

        ;; Widen the horiz borders by 5 pixels each
        lda     #$03
        ldx     #$00
*       ldy     #$00
*       jsr     pset
        iny
        cpy     #100
        bne     -
        inx
        cpx     #$05
        bne     --
        ldx     #159
*       ldy     #$00
*       jsr     pset
        iny
        cpy     #100
        bne     -
        dex
        cpx     #154
        bne     --

        ;; Initialize
        jsr     $ffde                   ; RDTIM
        jsr     srnd

        jsr     init_bacteria
        jsr     init_bugs

        ;; Main loop
mainlp: jsr     run_step

        jsr     $ffe4                   ; Did the user hit 'G'?
        cmp     #'G
        bne     +
        lda     garden                  ; If so, toggle the Garden
        eor     #$01
        sta     garden
*       jsr     $ffe1                   ; Did the user hit RUN/STOP?
        bne     mainlp                  ; If not, continue simulation

        jsr     leave_bitmap
        jmp     ($a002)

title_msg:
        .byte   147,8,14,13,13
        .byte   "        ",18,"                        ",146,13
        .byte   "        ",18,"  simulated  evolution  ",146,13
        .byte   "        ",18,"                        ",146,13
        .byte   13,13,13,"  c=64 EDITION BY mICHAEL mARTIN, 2021",13,13
        .byte   "            oRIGINAL PROGRAM",13
        .byte   "          mICHAEL pALMITER AND",13
        .byte   "          mARTIN gARDNER, 1989",13
        .byte   13,13,13,"    pRESS g TO TOGGLE gARDEN OF eDEN",13
        .byte   "         pRESS run/stop TO QUIT",13,13
        .byte   13,13,13,"       ",18,"  press any key to begin  ",146,0


        .include "mcbitmap.s"
        .include "simevocore.s"

;;; ----------------------------------------------------------------------
;;;  Platform-specific callbacks from the core
;;; ----------------------------------------------------------------------

;; Dimensions of the usable screen
.alias ARENA_WIDTH      150
.alias ARENA_HEIGHT     100

;; Draw Bacterium: Draw a bacterium at (X, Y) in the arena. Preserves all
;; registers.
draw_bacterium:
        pha
        tya
        pha
        tay
        txa
        pha                             ; Convert arena to screen coords
        clc
        adc     #$05
        tax
        lda     #$01                    ; Bacterium color
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

;; Draw Bug: Draw bug X in the arena. Preserves all registers.
draw_bug:
        pha
        lda     #$02
        sta     _paint_color
        ;; Fall through to _paint_bug

_paint_bug:
        tya
        pha
        txa
        pha
        lda     bug_y, x
        tay
        lda     bug_x, x
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
        ;; to increate the bug's HP by 40x the number of bacteria it ate
        lda     eaten
        beq     ++
*       jsr     feed_bug
        dec     eaten
        bne     -
*       pla
        rts
.scend

        ;; Ensure no overruns
        .checkpc $10fe

        .data
        .checkpc $2000
