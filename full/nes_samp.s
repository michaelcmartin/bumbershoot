;;; NES Digital Sound Demo
;;; Bumbershoot Software, 2022
;;;
;;; This program is designed to be built with the Ophis toolchain. To build:
;;;   ophis nes_samp.s

        .outfile "nes_samp.nes"

;;; iNES header
        .byte   "NES",$1a,$08,$00,$21,$00
        .advance $10

;;; Banks 0-1: "Wow" sound, PCM, 8kHz
        .org    $8000
        .scope
_start:
        .incbin "wow_pcm.bin"
_end:
        .advance $fffe,$ff
        .word   _end-_start
        .scend

;;; Banks 2-3: "Bumbershoot" sound, PCM, 8kHz
        .scope
        .org    $8000
_start:
        .incbin "bumbershoot_pcm.bin"
_end:
        .advance $fffe,$ff
        .word   _end-_start
        .scend

;;; Banks 4-6: blank
        .org    $8000
        .advance $c000,$ff
        .org    $8000
        .advance $c000,$ff
        .org    $8000
        .advance $c000,$ff

;;; Bank 7: non-PCM digital sound, Main program
        .data
        .org    $0000
        .space  ptr       2
        .space  j0current 1
        .space  shadow    1
        .space  bank      1
        .space  length    2
        .space  busy      1
        .space  option    1


        .text
        .org    $c000
wow_dmc:
        .incbin "wow_dmc.bin"
        .alias wow_len [^ - wow_dmc - 1] / 16
        .advance [^ + 63] & $ffc0,$ff
bumbersong_dmc:
        .incbin "bumber_dmc.bin"
        .alias bumbersong_len [^ - bumbersong_dmc - 1] / 16
        .advance [^ + 63] & $ffc0,$ff
wow_rev:
        .incbin "wow_rev.bin"
        .advance [^ + 63] & $ffc0,$ff
bumbersong_rev:
        .incbin "bumber_rev.bin"

        .advance $f800,$ff
        .include "../asm/fonts/sinestra.s"

banks: .byte   $00,$01,$02,$03,$04,$05,$06,$07

reset:  sei
        cld

        ;; Wait two frames.
        bit     $2002
*       bit     $2002
        bpl     -
*       bit     $2002
        bpl     -

        ;; Mask out sound IRQs.
        lda     #$40
        sta     $4017
        lda     #$00
        sta     $4010

        ;; Disable all graphics.
        sta     $2000
        sta     $2001

        ;; It's now OK to turn on IRQs.
        cli

        ;; Clear out RAM.
        tax
*       sta     $000,x
        sta     $100,x
        sta     $200,x
        sta     $300,x
        sta     $400,x
        sta     $500,x
        sta     $600,x
        sta     $700,x
        inx
        bne     -

        ;; Reset the stack pointer.
        dex
        txs

        ;; Clear out SPR-RAM.
        lda     #$02
        sta     $4014

        ;; Clear out VRAM from $0000-$2400.
        lda     #$00
        sta     $2006
        sta     $2006
        ldx     #$28
        tay
*       sta     $2007
        iny
        bne     -
        dex
        bne     -

        ;; Load the display text
        lda     #<msg
        sta     ptr
        lda     #>msg
        sta     ptr+1
textlp: ldy     #$00
        lda     (ptr),y
        beq     textdone
        sta     $2006
        iny
        lda     (ptr),y
        sta     $2006
        iny
linelp: lda     (ptr),y
        beq     endln
        iny
        sta     $2007
        bne     linelp
endln:  iny
        tya
        clc
        adc     ptr
        sta     ptr
        lda     ptr+1
        adc     #$00
        sta     ptr+1
        bne     textlp
textdone:

        ;; Load the palette into place. Everything is black but BGM P0C3, SPR P0C3, and SPR P1C3.
        lda     #$3f
        ldx     #$00
        sta     $2006
        stx     $2006
        lda     #$0f
        ldx     #$20
*       sta     $2007
        dex
        bne     -
        lda     #$3f
        sta     $2006
        lda     #$03
        sta     $2006
        lda     #$30
        sta     $2007
        lda     #$3f
        sta     $2006
        lda     #$13
        sta     $2006
        lda     #$30
        sta     $2007
        lda     #$3f
        sta     $2006
        lda     #$17
        sta     $2006
        lda     #$16
        sta     $2007

        lda     #$00            ; Disable graphics
        sta     shadow
        sta     $2000
        sta     $2001

        ;; Load font into place.
        lda     #$04
        sta     $2006
        lda     #$00
        sta     ptr
        tay
        sta     $2006
        lda     #$f8
        sta     ptr+1
        ldx     #$40
fontlp: lda     (ptr),y
        sta     $2007
        iny
        cpy     #$08
        bne     fontlp
        ldy     #$00
*       lda     (ptr),y
        sta     $2007
        iny
        cpy     #$08
        bne     -
        ldy     #$00
        clc
        lda     $00
        adc     #$08
        sta     $00
        bcc     +
        inc     $01
        lda     #$02
        sta     $2006
        lda     #$00
        sta     $2006
*       dex
        bne     fontlp

        ;; Configure sprite pointer
        lda     #95
        sta     $0204
        lda     #'_
        sta     $0205
        lda     #$40
        sta     $0206
        lda     #24
        sta     $0207

        ;; Enable graphics. Set basic PPU registers. Load everything
        ;; from $0000, and use the $2000 nametable. Don't hide the
        ;; left 8 pixels.  Don't enable sprites.

        ;; This just sets the shadow registers for $2001; VBLANK does
        ;; the actual graphics enable and fixes the scroll so that
        ;; suddenly enabling graphics doesn't make the display
        ;; shudder.
        lda     #$1e
        sta     shadow
        lda     #$80            ; Enable NMI
        sta     $2000
        lda     #$40
        sta     $4011

main_loop:
        lda     j0current
        beq     main_loop
        pha
        and     #$90            ; Pressed A or START?
        beq     check_down
        ;; SFX selected
        pla
        lda     #$00            ; Disable video NMI
        sta     $2000
        lda     option
        jsr     play_sound
        lda     #$80            ; Re-enable NMI
        sta     $2000
        bne     input_end
check_down:
        pla
        pha
        and     #$24            ; Pressed SELECT or DOWN?
        beq     check_up
        ;; Move arrow down
        pla
        ldx     option
        inx
        cpx     #$06
        bne     +
        ldx     #$00
*       stx     option
        jmp     input_end
check_up:
        pla
        and     #$08            ; Pressed UP?
        beq     input_end
        ldx     option
        dex
        bpl     +
        ldx     #$05
*       stx     option

input_end:
        lda     option          ; Place cursor
        asl
        asl
        asl
        clc
        adc     #95
        sta     $0204
        lda     #$40
        sta     $4011           ; Neutral audio
        sta     $0206           ; Restore cursor palette
        ;; Wait for neutral controller.
*       lda     j0current
        bne     -
        jmp     main_loop

play_sound:
        ldx     #$41
        stx     $0206           ; Activated cursor palette
        ldx     #$02            ; Update sprite RAM
        stx     $4014
        jsr     do_jump_table
        .word   pcm_0,pcm_1,dmc_0,dmc_1,dmc_2,dmc_3

pcm_0:  lda     #$00
        beq     pcm_common
pcm_1:  lda     #$02
pcm_common:
        sta     bank
        jmp     play_pcm

dmc_0:  lda     #[wow_dmc-$c000] / 64
        ldx     #wow_len
        bne     dmc_common
dmc_1:  lda     #[bumbersong_dmc-$c000] / 64
        ldx     #bumbersong_len
        bne     dmc_common
dmc_2:  lda     #[wow_rev-$c000] / 64
        ldx     #wow_len
        bne     dmc_common
dmc_3:  lda     #[bumbersong_rev-$c000] / 64
        ldx     #bumbersong_len
dmc_common:
        sta     $4012
        stx     $4013
        inc     busy
        lda     #$88
        sta     $4010
        lda     #$10
        sta     $4015
*       lda     busy
        bne     -
        rts

do_jump_table:
        asl
        tay
        iny
        pla
        sta     ptr
        pla
        sta     ptr+1
        lda     (ptr),y
        tax
        iny
        lda     (ptr),y
        stx     ptr
        sta     ptr+1
        jmp     (ptr)

vblank: pha
        txa
        pha
        lda     #$02            ; Update sprite RAM
        sta     $4014
        lda     shadow          ; Copy shadow $2001 into place
        sta     $2001
        beq     +               ; If we turned graphics *on*...
        lda     #$00            ; Also reset scroll state
        sta     $2005
        sta     $2005

*       ldx     #$01            ; Read the controller state
        stx     $4016
        dex
        stx     $4016
        stx     j0current
        ldx     #$08
*       lda     $4016
        lsr
        rol     j0current
        dex
        bne     -

        pla
        tax
        pla
        rti

irq:    pha
        lda     #$00
        sta     $4015
        sta     $4010
        sta     busy
        pla
        rti

msg:    .wordbe $2060
        .byte   "     NES DIGITAL SOUND DEMO     "
        .byte   "   BUMBERSHOOT SOFTWARE, 2022   ",0
        .wordbe $2180
        .byte   "     WOW PCM                    "
        .byte   "     BUMBERSONG PCM             "
        .byte   "     WOW DMC                    "
        .byte   "     BUMBERSONG DMC             "
        .byte   "     WOW DMC (REVERSED)         "
        .byte   "     BUMBERSONG DMC (REVERSED)  ",0
        .wordbe $2320
        .byte   "    SELECT EFFECT WITH D-PAD    "
        .byte   "     PRESS A TO PLAY SAMPLE     ",0,0

        .advance $ff80,$ff
play_pcm:
.scope
        ldy     bank
        iny
        lda     banks,y
        sta     banks,y
        lda     $bffe
        sta     length
        lda     $bfff
        sta     length+1
        lda     #$00
        sta     ptr
        lda     #$80
        sta     ptr+1
_lp:    ldy     bank            ; 3
        lda     banks,y         ; 7
        sta     banks,y         ; 12
        ldy     #$00            ; 14
        lda     (ptr),y         ; 19
        sta     $4011           ; 23
        lda     #$01            ; 25
        clc                     ; 27
        adc     ptr             ; 30
        sta     ptr             ; 33
        lda     ptr+1           ; 36
        adc     #$00            ; 38
        sta     ptr+1           ; 41
        cmp     #$c0            ; 43    ; Leak into bank 7?
        bne     _norm_lp        ; 45    ; _norm_lp begins at 46
        lda     #$80            ; 47
        sta     ptr+1           ; 50
        inc     bank            ; 55
        jmp     _next           ; 58
_norm_lp:
        nop                     ; 48
        nop                     ; 50
        nop                     ; 52
        nop                     ; 54
        nop                     ; 56
        nop                     ; 58
_next:  ldy     #27             ; 60
_delay: dey
        bne     _delay          ; 194  (loop time: 27*5-1 = 134)
        nop                     ; 196
        nop                     ; 198
        nop                     ; 200
        sec                     ; 202
        lda     length          ; 205
        sbc     #$01            ; 207
        sta     length          ; 210
        lda     length+1        ; 213
        sbc     #$00            ; 215
        sta     length+1        ; 218
        ora     length          ; 221
        bne     _lp             ; 224
        rts


.scend

        .advance $fffa,$ff
        .word   vblank,reset,irq
