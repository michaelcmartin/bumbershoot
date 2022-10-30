;;; HELLO WORLD for the NES (UNROM program test)
;;; Bumbershoot Software, 2022
;;;
;;; This program is designed to be built with the Ophis toolchain. To build:
;;;   ophis hello_unrom.s

        .outfile "hello_unrom.nes"

;;; iNES header
        .byte   "NES",$1a,$08,$00,$21,$00
        .advance $10

;;; Banks 0-3
        .org    $8000
        .advance $c000,$ff
        .org    $8000
        .advance $c000,$ff
        .org    $8000
        .advance $c000,$ff
        .org    $8000
        .advance $c000,$ff

;;; Banks 4 and 5: Font data
        .org    $8000
        .include "../asm/fonts/halogen.s"
        .advance $8200,$ff
        .byte   "     CURRENT FONT:  HALOGEN     "

        .advance $c000,$ff

        .org    $8000
        .include "../asm/fonts/sinestra.s"
        .advance $8200,$ff
        .byte   "     CURRENT FONT: SINESTRA     "
        .advance $c000,$ff

;;; Bank 6
        .org    $8000
        .advance $c000,$ff

;;; Bank 7: Main program
        .data
        .org    $0000
        .space  ptr       2
        .space  font_bank 1
        .space  j0current 1
        .space  shadow    1

        .text
        .org    $c000

        ;; set_bank: sets the $8000-$BFFF bank to the value in X.
.scope
_banks: .byte   $00,$01,$02,$03,$04,$05,$06,$07
set_bank:
        ldx     font_bank
        lda     _banks,x
        sta     _banks,x
        rts
.scend

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

        ;; Copy the greeting message into place.
        lda     #$21
        sta     $2006
        lda     #$a0
        sta     $2006
        ldx     #$00
*       lda     msg,x
        sta     $2007
        inx
        cpx     #$a0
        bne     -

        ;; Load the palette into place. Everything is black but BGM P0C3.
        lda     #$3F
        ldx     #$00
        sta     $2006
        stx     $2006
        lda     #$0f
        ldx     #$20
*       sta     $2007
        dex
        bne     -
        lda     #$3F
        sta     $2006
        lda     #$03
        sta     $2006
        lda     #$30
        sta     $2007

        ldx     #$04
        stx     font_bank

main_loop:
        lda     #$00            ; Disable graphics
        sta     shadow
        sta     $2000
        sta     $2001

        jsr     set_bank        ; Choose new font

        ;; Load font into place.
        lda     #$04
        sta     $2006
        lda     #$00
        sta     $00
        tay
        sta     $2006
        lda     #$80
        sta     $01
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

        ;; Copy the font identifier into place.
        lda     #$22
        sta     $2006
        lda     #$00
        sta     $2006
        ldx     #$00
*       lda     $8200,x
        sta     $2007
        inx
        cpx     #32
        bne     -

        ;; Enable graphics. Set basic PPU registers. Load everything
        ;; from $0000, and use the $2000 nametable. Don't hide the
        ;; left 8 pixels.  Don't enable sprites.

        ;; This just sets the shadow registers for $2001; VBLANK does
        ;; the actual graphics enable and fixes the scroll so that
        ;; suddenly enabling graphics doesn't make the display
        ;; shudder.
        lda     #$0e
        sta     shadow
        lda     #$80            ; Turn on video NMI here though
        sta     $2000

        ;; Wait for A button to be released.
*       lda     j0current
        bmi     -

        ;; Wait for A button to be pressed.
*       lda     j0current
        bpl     -

        ;; Toggle the font bank, and loop back.
        lda     font_bank
        eor     #$01
        sta     font_bank
        jmp     main_loop

vblank: pha
        txa
        pha
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
irq:    rti

msg:    .byte   "     HELLO, NES WORLD, FROM     "
        .byte   "      BUMBERSHOOT SOFTWARE      "
        .byte   "                                "
        .byte   "                                "
        .byte   "     PRESS A TO CHANGE FONT     "

        .advance $fffa,$ff
        .word   vblank,reset,irq
