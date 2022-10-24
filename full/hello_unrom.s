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

;;; Bank 4: Font data
        .org    $8000
font:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$18,$30,$00,$00,$00,$00,$00,$00,$18,$30
        .byte   $00,$3c,$62,$7e,$62,$62,$62,$00,$00,$3c,$62,$7e,$62,$62,$62,$00
        .byte   $00,$7c,$62,$7c,$62,$62,$7c,$00,$00,$7c,$62,$7c,$62,$62,$7c,$00
        .byte   $00,$7c,$62,$62,$62,$62,$7c,$00,$00,$7c,$62,$62,$62,$62,$7c,$00
        .byte   $00,$7e,$60,$7c,$60,$60,$7e,$00,$00,$7e,$60,$7c,$60,$60,$7e,$00
        .byte   $00,$7e,$60,$7c,$60,$60,$60,$00,$00,$7e,$60,$7c,$60,$60,$60,$00
        .byte   $00,$62,$62,$7e,$62,$62,$62,$00,$00,$62,$62,$7e,$62,$62,$62,$00
        .byte   $00,$60,$60,$60,$60,$60,$7e,$00,$00,$60,$60,$60,$60,$60,$7e,$00
        .byte   $00,$62,$76,$6a,$62,$62,$62,$00,$00,$62,$76,$6a,$62,$62,$62,$00
        .byte   $00,$62,$72,$6a,$66,$62,$62,$00,$00,$62,$72,$6a,$66,$62,$62,$00
        .byte   $00,$3c,$62,$62,$62,$62,$3c,$00,$00,$3c,$62,$62,$62,$62,$3c,$00
        .byte   $00,$7c,$66,$7c,$68,$64,$62,$00,$00,$7c,$66,$7c,$68,$64,$62,$00
        .byte   $00,$3c,$60,$3c,$02,$62,$3c,$00,$00,$3c,$60,$3c,$02,$62,$3c,$00
        .byte   $00,$7e,$18,$18,$18,$18,$18,$00,$00,$7e,$18,$18,$18,$18,$18,$00
        .byte   $00,$62,$62,$62,$62,$62,$3c,$00,$00,$62,$62,$62,$62,$62,$3c,$00
        .byte   $00,$62,$62,$62,$6a,$76,$62,$00,$00,$62,$62,$62,$6a,$76,$62,$00
        .advance $c000,$ff

;;; Banks 5 and 6
        .org    $8000
        .advance $c000,$ff
        .org    $8000
        .advance $c000,$ff

;;; Bank 7: Main program
        .org    $c000

        ;; set_bank: sets the $8000-$BFFF bank to the value in X.
.scope
_banks: .byte   $00,$01,$02,$03,$04,$05,$06,$07
set_bank:
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

        ldx     #$04
        ;; Load font into place.
        jsr     set_bank
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $00
        tay
        lda     #$80
        sta     $01
        ldx     #$02
*       lda     ($00),y
        sta     $2007
        iny
        bne     -
        inc     $01
        dex
        bne     -

        ;; Copy the greeting message into place.
        lda     #$21
        sta     $2006
        lda     #$c0
        sta     $2006
        ldx     #$00
*       lda     msg,x
        sta     $2007
        inx
        cpx     #64
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

        ;; Reset scroll to 0.
        lda     #$00
        sta     $2005
        sta     $2005

        ;; Set basic PPU registers. Load everything from $0000,
        ;; and use the $2000 nametable. Don't hide the left 8 pixels.
        ;; Don't enable sprites.
        lda     #$80
        sta     $2000
        lda     #$0e
        sta     $2001
        cli

loop:   jmp     loop

irq:
vblank: rti

msg:    .byte   0,0,0,0,0,7,5,8,8,11,1,0,10,5,13,0
        .byte   16,11,12,8,4,1,0,6,12,11,9,0,0,0,0,0
        .byte   0,0,0,0,0,0,3,15,9,3,5,12,13,7,11,11
        .byte   14,0,13,11,6,14,16,2,12,5,0,0,0,0,0,0

        .advance $fffa,$ff
        .word   vblank,reset,irq
