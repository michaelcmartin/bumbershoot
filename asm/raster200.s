        ;; PRG header and metadata
        .outfile "raster200.prg"
        .word   $0801
        .org    $0801

        ;; The variables we use
        .alias  model   $fb     ; for "raster grip"

        ;; KERNAL routines
        .alias  getin   $ffe4

        ;; BASIC header
        .word   +, 2015
        .byte   $9e, " 2062",$00
*       .word   0
        jmp     main

irq:    lda     #$01            ;  2
        sta     $d019           ;  6
        lda     #$1f            ;  8
        sta     $d011           ; 12
        ldx     #201            ; 14
        nop                     ; 16
        nop                     ; 18
        lda     #$00            ; 20
        sta     $d021           ; 24
        ;; Here's where the line starts. We pretend it's PAL and that
        ;; we must bounce back here after 63 cycles.
        ;; We'll slip 5 cycles going into the loop, so the earliest
        ;; safe cycle up there was 24, not 19.
raster: lda     $d011           ;  4
        and     #$07            ;  6
        clc                     ;  8
        adc     #$01            ; 10
        ora     #$18            ; 12
        sta     $d011           ; 16
        bit     model           ; 19
        bvs     +               ; 21 (PAL)
*       bmi     +               ; 23 (PAL)

*       ldy     #$05
*       dey
        bne     -               ; 49
        cmp     model           ; 52 (no-op)
        inc     $d021           ; 58
        dex                     ; 60
        bne     raster          ; 63

        lda     $dc0d
        beq     notim
        jmp     $ea31
notim:  jmp     $febc

        .checkpc $0900
main:
        ;; Clear idle graphic since we're FLD-ing away the whole screen
        lda     #$00
        sta     $3fff

        ;; Detect which model we're running on
        
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
        ldx     #$80            ; 1 extra cycle/line
        bne     get_model_done

        ;; Wait 65 more cycles, so we're in scanline 263
*       ldx     #$13
*       dex
        bne     -

        ;; If we're instead back at zero *now*, we're new NTSC
        bit     $d011
        bmi     +
        ldx     #$C0            ; 2 extra cycles/line
        bne     get_model_done
        ;; Otherwise we are PAL
*       ldx     #$00            ; 0 extra cycles/line

get_model_done:
        stx     model
        cli
        ;; At this point we will almost certainly be hit by a timer
        ;; IRQ, so get that out of the way before we mess with IRQ
        ;; targets

        ;; Set up IRQ
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$32
        sta     $d012
        lda     #<irq
        sta     $314
        lda     #>irq
        sta     $315
        lda     #$01
        sta     $d01a

        ;; Wait for a key
*       jsr     getin
        beq     -

        ;; Restore IRQ
        lda     #$00            ; Disable raster IRQ
        sta     $d01a
        sta     $c6             ; Empty keyboard buffer
        lda     #$31            ; Restore default IRQ routine
        sta     $0314
        lda     #$ea
        sta     $0315
        lda     #$81
        sta     $dc0d           ; Restore timer IRQ

        ;; Clean exit
        lda     #$06
        sta     $d021
        lda     #$93
        jsr     $ffd2
        lda     #$1b
        sta     $d011
        jmp     ($a002)
        
