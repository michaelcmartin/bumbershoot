        .segment "HEADER"
        .byte   "NES",$1a,$01,$01,$01,$00

        .import __OAM_START__

        .code
reset:  sei
        cld

        ;; Wait two frames.
        bit     $2002
:       bit     $2002
        bpl     :-
:       bit     $2002
        bpl     :-

        ;; Mask out sound IRQs.
        lda     #$40
        sta     $4017

        ;; Disable all graphics.
        lda     #$00
        sta     $2000
        sta     $2001

        ;; Clear out RAM.
        lda     #$00
        tax
:       sta     $000,x
        sta     $100,x
        sta     $200,x
        sta     $300,x
        sta     $400,x
        sta     $500,x
        sta     $600,x
        sta     $700,x
        inx
        bne     :-

        ;; Reset the stack pointer.
        dex
        txs

        ;; Clear out SPR-RAM.
        lda     #>__OAM_START__
        sta     $4014

        ;; Clear out the name tables at $2000-$2400.
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
        ldx     #$08
        lda     #0
        ldy     #0
:       sta     $2007
        iny
        bne     :-
        dex
        bne     :-

        ;; Copy the greeting message into place.
        lda     #$21
        sta     $2006
        lda     #$c0
        sta     $2006
        ldx     #$00
:       lda     msg,x
        sta     $2007
        inx
        cpx     #64
        bne     :-

        ;; Load the palette into place. Everything is black but BGM P0C3.
        lda     #$3F
        ldx     #$00
        sta     $2006
        stx     $2006
        lda     #$0f
        ldx     #$20
:       sta     $2007
        dex
        bne     :-
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

        .segment "VECTORS"
        .word   vblank,reset,irq

        .segment "RODATA"
msg:    .byte   0,0,0,0,0,7,5,8,8,11,1,0,10,5,13,0
        .byte   16,11,12,8,4,1,0,6,12,11,9,0,0,0,0,0
        .byte   0,0,0,0,0,0,3,15,9,3,5,12,13,7,11,11
        .byte   14,0,13,11,6,14,16,2,12,5,0,0,0,0,0,0

        .segment "CHR0"
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
