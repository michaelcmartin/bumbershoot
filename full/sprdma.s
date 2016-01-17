
        ;; KERNAL aliases
        .alias  chrout  $ffd2
        .alias  getin   $ffe4
        .alias  plot    $fff0
        .alias  stop    $ffe1

        ;; PRG header
        .outfile "sprdma.prg"
        .word   $0801
        .org    $0801

        ;; BASIC header
        .word   +, 2016
        .byte   $9e, " 2062", 0
*       .word   0

        ;; Variables representing control state
        .data
        .org    $c100
        .space  ready   1       ; Something to do
        .space  hitkey  1       ; Key that was hit
        .space  quit    1       ; True if quit was hit

        .text

        lda     #<heading
        ldx     #>heading
        jsr     strout

        jsr     get_model
        txa
        asl
        tax
        lda     irqs, x
        sta     [+]+1
        lda     irqs+1, x
        sta     [+]+2
        ;; Load IRQ into $C000
        ldy     #$00
*       lda     new_ntsc_irq_begin, y
        sta     $c000, y
        iny
        bne     -
        ;; Clear out the initial state, now that Y is conveniently zero
        sty     ready
        sty     hitkey
        sty     quit
        ;; Display the rest of the demo screen
        lda     models, x
        pha
        lda     models+1, x
        tax
        pla
        jsr     strout
        lda     #<delay_meter
        ldx     #>delay_meter
        jsr     strout

        ;; Set up the sprites for interference
        ldx     #$0f
*       lda     #150
        sta     $d000,x
        dex
        lda     #$00
        sta     $d000,x
        dex
        bpl     -
        sta     $d015

        ;; Hide the right edge of the glitch
        lda     #$06
        sta     $da05
        sta     $da06
        sta     $da07
        lda     #$a0
        sta     $0605
        sta     $0606
        sta     $0607

        ;; Set up IRQ
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$94
        sta     $d012
        lda     #$00
        sta     $314
        lda     #$c0
        sta     $315
        lda     #$01
        sta     $d01a

        ;; Main loop: wait until there's work to do, then do it
mainlp: jsr     draw_sprval
*       lda     ready
        beq     -
        ;; Are we quitting?
        lda     quit
        bne     finish
        ;; Check + and -
        lda     hitkey
        cmp     #$2b            ; +
        bne     +
        inc     $d015
        jmp     mainup
*       cmp     #$2d            ; -
        bne     +
        dec     $d015
        jmp     mainup
*       sec
        sbc     #'0
        tax
        lda     #$01
*       dex
        beq     found_num
        asl
        bcc     -
        bcs     mainup          ; Not a character 1-8
found_num:
        eor     $d015
        sta     $d015
mainup:
        lda     #$00
        sta     ready
        beq     mainlp

finish: lda     #$00            ; Disable Raster IRQ
        sta     $d01a
        lda     #$1b            ; Fix vscroll
        sta     $d011
        lda     #$00            ; Disable sprites
        sta     $d015
        sta     $c6             ; Empty keyboard buffer
        lda     #$06            ; Fix background color
        sta     $d021
        lda     #$31            ; Restore IRQ target
        sta     $314
        lda     #$ea
        sta     $315
        lda     #$81            ; Re-enable timer IRQ
        sta     $dc0d
        lda     #147            ; Clear screen
        jsr     chrout
        jmp     ($a002)         ; Exit to BASIC


irqs:   .word   pal_irq_begin, old_ntsc_irq_begin, new_ntsc_irq_begin
models: .word   model_pal, model_old_ntsc, model_new_ntsc

heading:
        .byte   147,13,"         SPRITE DMA TIMING TEST",13
        .byte   "          MICHAEL MARTIN, 2016",13,13,0
model_pal:
        .byte   "     PAL: 63 CYCLES/LINE, 312 LINES",0
model_old_ntsc:
        .byte   "  OLD NTSC:  64 CYCLES/LINE, 262 LINES",0
model_new_ntsc:
        .byte   "  NEW NTSC:  65 CYCLES/LINE, 263 LINES",0
delay_meter:
        .byte   13,13,13,13,"   CYCLES CONSUMED",13
        .byte   13,"          11111111112",13
        .byte   "012345678901234567890",13,13,13
        .byte   "   CURRENT SPRITE REGISTER:",13,13
        .byte   "    KEYS 1-8 TOGGLE SPRITES",13
        .byte   "    KEYS +/- INC/DEC SPRITE REGISTER",13
        .byte   "    PRESS RUN/STOP TO QUIT",13,0
hexits: .byte   "0123456789ABCDEF"

draw_sprval:
        clc
        ldx     #14
        ldy     #28
        jsr     plot
        lda     $d015
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        lda     hexits, x
        jsr     chrout
        pla
        and     #$0F
        tax
        lda     hexits, x
        jmp     chrout

        ;; Scan the keyboard and set the flags appropriately. The
        ;; interrupt routine does this so that our main routine can be
        ;; assured of only doing fast operations when the interrupt
        ;; happens, no matter what shenanigans the KERNAL gets up to.
do_scan:
        lda     ready
        bne     ++
        jsr     getin
        sta     hitkey
        beq     +
        lda     #$01
        sta     ready
*       jsr     stop
        bne     +
        lda     #$01
        sta     ready
        sta     quit
*       rts

strout: sta     [+]+1
        stx     [+]+2
        ldy     #$00
*       lda     $ffff, y
        beq     +
        jsr     chrout
        iny
        bne     -
*       rts

get_model:
        ;; Wait for top of frame
*       bit     $d011
        bmi     -
        ;; Trap at scanline 256
        sei
*       bit     $d011
        bpl     -

        ;; Wait for scanline 261 (last of old NTSC)
        lda     #<261
*       cmp     $d012
        bne     -

        ;; Wait 65 cycles to ensure we're at scanline 262
        ldx     #$13
*       dex
        bne     -

        ;; If we're instead back at 0, we're old NTSC
        bit     $d011
        bmi     +
        ldx     #$01            ; 1 extra cycle/line
        bne     get_model_done

        ;; Wait 65 more cycles, so we're in scanline 263
*       ldx     #$13
*       dex
        bne     -
        ;; If we're instead back at zero *now*, we're new NTSC
        bit     $d011
        bmi     +
        ldx     #$02            ; 2 extra cycles/line
        bne     get_model_done
        ;; Otherwise we are PAL
*       ldx     #$00            ; 0 extra cycles/line

get_model_done:
        cli
        rts

new_ntsc_irq_begin:
.scope
        .org    $c000
        ;; IRQ phase one; set up another IRQ where we know we were
        ;; executing a 2-cycle instruction.
_irq:   lda     #$01            ; 46 (worst case)
        sta     $d019           ; 50
        lda     #<_irq2         ; 52
        sta     $314            ; 56
        inc     $d012           ; 62
        cli                     ; 64
        nop
        nop                     ; Now we mark time until
        nop                     ; that next IRQ hits...
        nop                     ; ... this may be excessive NOPpery
        nop
        nop
        ;; The second IRQ has it, and so we are either cycle 38 or 39
        ;; going in.
_irq2:  lda     #$01            ; 40-41
        sta     $d019           ; 44-45
        tsx                     ; 46-47
        txa                     ; 48-49
        clc                     ; 50-51
        adc     #$06            ; 52-53
        tax                     ; 54-55
        cmp     $03             ; 57-58 (marking time)
        lda     $d012           ; 61-62
        cmp     $d012           ;  0- 1
        beq     _stbl           ;  3
_stbl:  txs                     ;  5
        ldx     #$08            ;  7
*       dex
        bne     -               ; 46
        cmp     $02             ; 49
        lda     #$01            ; 51
        sta     $d021           ; 55
        ldx     #$03            ; 57
*       dex
        bne     -               ;  6
        nop                     ;  8
        nop                     ; 10
        nop                     ; 12
        lda     #$06            ; 14
        sta     $d021           ; 18
        ;; Now reset for the next frame
        lda     #$94
        sta     $d012
        lda     #<_irq
        sta     $0314
        jsr     do_scan
        lda     $dc0d
        beq     _notim
        jmp     $ea31
_notim: jmp     $febc
_irqend:
        .checkpc $c100
        .org    new_ntsc_irq_begin+[_irqend-_irq]
.scend

old_ntsc_irq_begin:
.scope
        .org    $c000
        ;; IRQ phase one; set up another IRQ where we know we were
        ;; executing a 2-cycle instruction.
_irq:   lda     #$01            ; 46 (worst case)
        sta     $d019           ; 50
        lda     #<_irq2         ; 52
        sta     $314            ; 56
        inc     $d012           ; 62
        cli                     ; 64
        nop
        nop                     ; Now we mark time until
        nop                     ; that next IRQ hits...
        nop                     ; ... this may be excessive NOPpery
        nop
        nop
        ;; The second IRQ has it, and so we are either cycle 38 or 39
        ;; going in.
_irq2:  lda     #$01            ; 40-41
        sta     $d019           ; 44-45
        tsx                     ; 46-47
        txa                     ; 48-49
        clc                     ; 50-51
        adc     #$06            ; 52-53
        tax                     ; 54-55
        nop                     ; 56-58
        lda     $d012           ; 60-63
        cmp     $d012           ;  0- 1
        beq     _stbl           ;  3
_stbl:  txs                     ;  5
        ldx     #$08            ;  7
*       dex
        bne     -               ; 46
        cmp     $02             ; 49
        lda     #$01            ; 51
        sta     $d021           ; 55
        ldx     #$03            ; 57
*       dex
        bne     -               ;  7
        cmp     $02             ; 10
        nop                     ; 12
        lda     #$06            ; 14
        sta     $d021           ; 18
        ;; Now reset for the next frame
        lda     #$94
        sta     $d012
        lda     #<_irq
        sta     $0314
        jsr     do_scan
        lda     $dc0d
        beq     _notim
        jmp     $ea31
_notim: jmp     $febc
_irqend:
        .checkpc $c100
        .org    old_ntsc_irq_begin+[_irqend-_irq]
.scend

pal_irq_begin:
.scope
        .org    $c000
        ;; IRQ phase one; set up another IRQ where we know we were
        ;; executing a 2-cycle instruction.
_irq:   lda     #$01            ; 46 (worst case)
        sta     $d019           ; 50
        lda     #<_irq2         ; 52
        sta     $314            ; 56
        inc     $d012           ; 62
        cli                     ; 64
        nop
        nop                     ; Now we mark time until
        nop                     ; that next IRQ hits...
        nop                     ; ... this may be excessive NOPpery
        nop
        ;; The second IRQ has it, and so we are either cycle 38 or 39
        ;; going in.
_irq2:  lda     #$01            ; 40-41
        sta     $d019           ; 44-45
        tsx                     ; 46-47
        txa                     ; 48-49
        clc                     ; 50-51
        adc     #$06            ; 52-53
        cmp     $03             ; 55-56 (marking time)
        ldx     $d012           ; 59-60
        cpx     $d012           ;  0- 1
        beq     _stbl           ;  3
_stbl:  tax                     ;  5
        txs                     ;  7
        ldx     #$08            ;  9
*       dex
        bne     -               ; 48
        lda     #$01            ; 50
        sta     $d021           ; 54
        ldx     #$03            ; 56
*       dex
        bne     -               ;  7
        cmp     $02             ; 10
        nop                     ; 12
        lda     #$06            ; 14
        sta     $d021           ; 18
        ;; Now reset for the next frame
        lda     #$94
        sta     $d012
        lda     #<_irq
        sta     $0314
        jsr     do_scan
        lda     $dc0d
        beq     _notim
        jmp     $ea31
_notim: jmp     $febc
_irqend:
        .checkpc $c100
        .org    pal_irq_begin+[_irqend-_irq]
.scend
