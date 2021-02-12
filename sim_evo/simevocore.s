.scope
        .data
        .space  numbugs   1
        .space  garden     1
        .space  rndval     4
        .space  _scratch  16
        .space  _scratch2 16
        .space  _scratch3 16
        .org    [^+$ff] & $FF00         ; Align to page
        .space  bug_x    256
        .space  bug_y    256
        .space  bug_age  512
        .space  bug_hp   512            ; 256 * 2
        .space  bug_dir  256
        .space  bug_dna 1536            ; 256 * 6

        .text

init_bacteria:
        lda     #100
        sta     _scratch2
*       lda     #ARENA_HEIGHT
        ldx     #$00
        jsr     intrnd
        lda     intrndval
        sta     _scratch2+2
        lda     #ARENA_WIDTH
        ldx     #$00
        jsr     intrnd
        ldx     intrndval
        ldy     _scratch2+2
        jsr     draw_bacterium
        dec     _scratch2
        bne     -
        lda     #$00
        sta     garden
        rts

.scope
init_bugs:
        lda     #$00
        sta     numbugs
*       lda     #ARENA_HEIGHT-2
        ldx     #$00
        jsr     intrnd
        lda     intrndval
        ldx     numbugs
        sta     bug_y, x
        lda     #40
        sta     bug_hp, x
        lda     #$00
        sta     bug_hp+$100, x
        sta     bug_age, x
        sta     bug_age+$100, x
        lda     #ARENA_WIDTH-2
        ldx     #$00
        jsr     intrnd
        lda     intrndval
        ldx     numbugs
        sta     bug_x, x
        jsr     draw_bug
        lda     #$06
        ldx     #$00
        jsr     intrnd
        lda     intrndval
        ldx     numbugs
        sta     bug_dir, x
        lda     #>bug_dna
        sta     _dnapage
*       lda     #10
        ldx     #0
        jsr     intrnd
        lda     intrndval
        ldx     numbugs
        .alias  _dnapage ^+2
        sta     bug_dna, x
        inc     _dnapage
        lda     _dnapage
        cmp     #[>bug_dna]+6
        bne     -
        jsr     normalize_genes
        inc     numbugs
        cpx     #9
        bne     --
*       rts
.scend

.scope
        .alias  _total  _scratch2
run_step:
        ldx     #$00
_runlp: cpx     numbugs
        bne     +
        jmp     _plankton
*       jsr     erase_bug

        ;; Choose a direction to go in. Shift the bug number to .Y here.
        txa
        tay

        ;; Sum the gene weights.
        lda     #<bug_dna
        sta     $fb
        lda     #>bug_dna               ; Reset bug DNA pointer
        sta     $fc
        lda     #$00
        sta     _total
        sta     _total+1
*       lda     ($fb), y
        tax
        clc
        lda     _wgt_l, x
        adc     _total
        sta     _total
        lda     _wgt_h, x
        adc     _total+1
        sta     _total+1
        inc     $fc
        lda     $fc
        cmp     #[>bug_dna]+6
        bne     -

        ;; Pick a value within the total weight.
        tya
        pha
        lda     _total
        ldx     _total+1
        jsr     intrnd
        pla
        tay

        ;; Translate weighted value to relative direction.
        lda     #>bug_dna               ; Reset bug DNA pointer
        sta     $fc
        lda     #$00
        sta     _total
        sta     _total+1
*       lda     ($fb), y
        tax
        clc
        lda     _wgt_l, x
        adc     _total
        sta     _total
        lda     _wgt_h, x
        adc     _total+1
        sta     _total+1
        sec
        lda     _total
        sbc     intrndval
        lda     _total+1
        sbc     intrndval+1
        bcs     _found
        inc     $fc
        lda     $fc
        cmp     #[>bug_dna]+5
        bne     -
_found: lda     $fc
        sec
        sbc     #>bug_dna

        ;; Apply relative direction to bug_dir.
        clc
        adc     bug_dir, y
        cmp     #$06
        bcc     +
        sec
        sbc     #$06
*       sta     bug_dir, y

        ;; Put the bug index back in .X.
        tya
        tax

        ;; Move in direction and bounds check
        lda     bug_dir, x
        tay
        lda     bug_x, x
        clc
        adc     _xmv, y
        cmp     #$f0
        bcc     +
        lda     #$00
*       cmp     #ARENA_WIDTH-3
        bcc     +
        lda     #ARENA_WIDTH-3
*       sta     bug_x, x
        lda     bug_y, x
        clc
        adc     _ymv, y
        cmp     #$f0
        bcc     +
        lda     #$00
*       cmp     #ARENA_HEIGHT-3
        bcc     +
        lda     #ARENA_HEIGHT-3
*       sta     bug_y, x

        ;; Bug aging
        inc     bug_age, x
        bne     +
        inc     bug_age+$100, x
*       lda     bug_age+$100, x         ; Cap bug age at 4,096
        cmp     #$10
        bmi     +
        dec     bug_age+$100, x
*       lda     #$ff
        dec     bug_hp, x
        cmp     bug_hp, x
        bne     +
        dec     bug_hp+$100, x

        ;; Bug starves?
*       lda     bug_hp+$100, x
        bmi     _dies
        bne     _lives
        lda     bug_hp, x
        bne     _lives
_dies:  dec     numbugs
        ldy     numbugs
        jsr     _copy_bug
        dex
        jmp     _next
_lives: lda     numbugs                ; Do not reproduce if pop 255
        cmp     #$ff
        beq     _done
        sec
        lda     bug_age, x              ; Bug must be 800 units old at least
        sbc     #<800
        lda     bug_age+$100, x
        sbc     #>800
        bmi     _done
        sec
        lda     bug_hp, x               ; Bug must have at least 1000 HP
        sbc     #<1000
        lda     bug_hp+$100, x
        sbc     #>1000
        bmi     _done
        ;; Bug reproduces
        lsr     bug_hp+$100, x
        ror     bug_hp, x
        lda     #$00
        sta     bug_age, x
        sta     bug_age+$100, x
        txa
        pha                             ; Stash current bug number
        tay
        ldx     numbugs
        jsr     _copy_bug
        lda     #$06                    ; Mutate younger twin
        ldx     #$00
        jsr     intrnd
        ldx     numbugs
        lda     #>bug_dna
        clc
        adc     intrndval
        sta     ^+5                     ; Modify high byte of next insn
        inc     bug_dna, x
        jsr     normalize_genes
        lda     #$06                    ; Mutate elder twin
        ldx     #$00
        jsr     intrnd
        pla                             ; Restore elder twin index
        tax
        lda     #>bug_dna
        clc
        adc     intrndval
        sta     ^+5
        dec     bug_dna, x
        jsr     normalize_genes
        inc     numbugs
        jsr     draw_bug
        dex                             ; Reprocess first child
        jmp     _next
_done:  jsr     draw_bug
_next:  inx
        jmp     _runlp

        ;; Replenish plankton
_plankton:
        lda     #ARENA_WIDTH
        ldx     #$00
        jsr     intrnd
        lda     intrndval
        pha
        lda     #ARENA_HEIGHT
        ldx     #$00
        jsr     intrnd
        ldy     intrndval
        pla
        tax
        jsr     draw_bacterium
        lda     garden                  ; Replenish garden of Eden if active
        beq     +
        lda     #$14
        ldx     #$00
        jsr     intrnd
        clc
        lda     intrndval
        adc     #$28
        pha
        lda     #$14
        ldx     #$00
        jsr     intrnd
        clc
        lda     intrndval
        adc     #$50
        tay
        pla
        tax
        jsr     draw_bacterium
*       rts

        ;; Copies a bug from .Y to .X. .A is trashed.
_copy_bug:
        lda     #>bug_x
        sta     _cpage1
        sta     _cpage2
        .alias  _cpage1 ^+2
*       lda     bug_x, y
        .alias  _cpage2 ^+2
        sta     bug_x, x
        inc     _cpage1
        inc     _cpage2
        lda     _cpage2
        cmp     #[>bug_dna]+6
        bne     -
        rts

_xmv:   .byte   $00,$02,$02,$00,$fe,$fe
_ymv:   .byte   $02,$01,$ff,$fe,$ff,$01
        ;; Low and high bytes of the gene weights. This is actually
        ;; two 14-byte tables that overlap.
_wgt_h: .byte   $00,$00,$00,$00,$00,$00,$00,$00
_wgt_l: .byte   $01,$02,$04,$08,$10,$20,$40,$80
        .byte   $00,$00,$00,$00,$00,$00
.scend

.scope
        ;; Simplifies the genome of bug X. There will be at least
        ;; one gene with the value 0, and no genes of value less
        ;; than zero or greater than 13. This will ensure that the
        ;; weighted sum when generating behavior will always fit
        ;; within 16 bits.
normalize_genes:
        pha
        tya
        pha
        txa
        tay                             ; Move bug index to Y
        lda     #<bug_dna
        sta     $fb
        lda     #>bug_dna
        sta     $fc
        ;; Find minimum gene value
        lda     ($fb), y
        ldx     #5
*       inc     $fc
        cmp     ($fb), y
        bmi     +
        lda     ($fb), y
*       dex
        bne     --
        sta     $fd                     ; Minimum gene value
        ;; Restore pointer and normalize
        lda     #>bug_dna
        sta     $fc
        ldx     #6
*       lda     ($fb), y
        sec
        sbc     $fd
        cmp     #13
        bcc     +
        lda     #13
*       sta     ($fb), y
        inc     $fc
        dex
        bne     --
        ;; Restore original register values
        tya
        tax
        pla
        tay
        pla
        rts
.scend

.scope
        ;; Feeds bug X. bug_hp increases by 40, and caps at 1500.
feed_bug:
        pha
        lda     bug_hp, x
        clc
        adc     #40
        sta     bug_hp, x
        bcc     +
        inc     bug_hp+$100, x
*       lda     bug_hp, x
        sec
        sbc     #<1500
        lda     bug_hp+$100,x
        sbc     #>1500
        bmi     _bug_hungry
        lda     #<1500
        sta     bug_hp, x
        lda     #>1500
        sta     bug_hp+$100, x
_bug_hungry:
        pla
        rts
.scend

        ;; 16-bit multiplication function. 2-byte arguments go in
        ;; the mul1 and mul2 arguments. The 4-byte result is in
        ;; mul1 after the call.
.scope
        .alias  mul1    _scratch
        .alias  mul2    _scratch+4
        .alias  _mul1b  _scratch+6
        .alias  _reg    _scratch+8

mult16: lda     mul1                    ; Back up MUL1 since that space
        sta     _mul1b                  ; is reused as our result
        lda     mul1+1
        sta     _mul1b+1
        lda     #$00
        sta     mul1
        sta     mul1+1
        sta     mul1+2
        sta     mul1+3
        sty     _reg
        ldy     #$10
*       asl     mul1
        rol     mul1+1
        rol     mul1+2
        rol     mul1+3
        asl     mul2
        rol     mul2+1
        bcc     +
        clc
        lda     _mul1b
        adc     mul1
        sta     mul1
        lda     _mul1b+1
        adc     mul1+1
        sta     mul1+1
        lda     mul1+2
        adc     #$00
        sta     mul1+2
        lda     mul1+3
        adc     #$00
        sta     mul1+3
*       dey
        bne     --
        ldy     _reg
        rts
.scend

        ;; srnd and rnd: seed and update PRNG. 16-bit result in rndval.
.scope
        .data
        .alias  _x      rndval+2
        .alias  _y      rndval

        .text
        ;; Seed randomizer with .AX in both values. Calling RDTIM
        ;; ($FFDE) is a good way to get values for .AX.
srnd:   ora     #$01
        sta     _x
        sta     _y
        stx     _x+1
        stx     _y+1
        rts

        ;; x ^= x << 5
rnd:    lda     _x
        ldy     _x+1
        ldx     #$05
_lp:    asl
        rol     _x+1
        dex
        bne     _lp
        eor     _x
        sta     _x
        tya
        eor     _x+1
        sta     _x+1
        ;; x ^= x >> 3
        ldy     _x                      ; .A already has _x+1
        ldx     #$03
_lp2:   lsr
        ror     _x
        dex
        bne     _lp2
        eor     _x+1
        sta     _x+1
        tya
        eor     _x
        sta     _x
        ;; push y
        lda     _y
        pha
        lda     _y+1
        pha
        ;; x, y = y, y ^ (y >> 1) ^ x
        lsr
        ror     _y
        eor     _x+1
        sta     _y+1
        pla
        sta     _x+1
        eor     _y+1
        sta     _y+1
        pla
        tax
        eor     _y
        eor     _x
        sta     _y
        stx     _x
        rts
.scend

        ;; intrnd: Returns a value between 0 and (.AX - 1) in intrndval.
        .alias  intrndval mul1+2
intrnd: sta     mul1
        stx     mul1+1
        jsr     rnd
        lda     rndval
        sta     mul2
        lda     rndval+1
        sta     mul2+1
        jmp     mult16

.scend
