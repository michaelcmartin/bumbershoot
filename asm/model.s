        .outfile "model.prg"
        .word   $0801
        .org    $0801
        .byte   $0b,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00

        jsr     get_model
        lda     cycle_msg_h, x
        tay
        lda     cycle_msg_l, x
        jsr     $ab1e           ; BASIC print-string routine
        lda     #<msgend
        ldy     #>msgend
        jmp     $ab1e

cycle_msg_h:
        .byte   >pal, >o_ntsc, >ntsc
cycle_msg_l:
        .byte   <pal, <o_ntsc, <ntsc

pal:    .byte   "PAL: 312 SCANLINES, 63",0
o_ntsc: .byte   "OLD NTSC: 262 SCANLINES, 64",0
ntsc:   .byte   "NEW NTSC: 263 SCANLINES, 65",0
msgend: .byte   " CYCLES/SCANLINE",0

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
