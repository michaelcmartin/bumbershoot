;;; VRAM BLIT TEST
;;; Bumbershoot Software, 2017
;;;
;;; This is an attempt to see how far a naive RAM-to-VRAM line-blitter
;;; can be pushed during NES VBLANK. It is inspired by the horizontal
;;; parallax scrolling techniques used by Jaleco's "City Connection".

        .outfile "vramblit.nes"

;;; iNES header: NROM mapper 0, 1 ROM each, horizontally mirrored.
        .org    $0000
        .byte $4e,$45,$53,$1a,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;;; RAM layout
        .data
        .org    $0000
        .space  buffer  32
        .space  vector  2
        .space  lines   1
        .space  start   1

;;; PRG-ROM
        .text
        .org    $c000

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

        ;; Disable all graphics.
        lda     #$00
        sta     $2000
        sta     $2001

        ;; Clear out RAM.
        lda     #$00
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

        ;; Create the static parts of the screen.
        ;; Step 1: Clear out the name tables.
        lda     #$24            ; Clear $0800 bytes from $2400
        sta     $2006           ; Which clears both tables
        ldy     #$00            ; Assuming horizontal mirroring.
        sty     $2006
        ldx     #$08
        lda     #0
        ldy     #0
*       sta     $2007
        iny
        bne     -
        dex
        bne     -

        ;; Step 2: Prepare the palette.
        lda     #$3f
        ldx     #$00
        sta     $2006
        stx     $2006
*       lda     palette, x
        sta     $2007
        inx
        cpx     #$20
        bne     -

        ;; Step 3: Load the static text into place.
        lda     #$20
        sta     $2006
        lda     #$40
        sta     $2006
        ldx     #$00
*       lda     msg, x
        sta     $2007
        inx
        cpx     #$40
        bne     -

        ;; Step 4: Initialize control RAM.
        lda     #$01
        sta     lines
        lda     #<l0
        sta     vector
        lda     #>l0
        sta     vector+1

        ;; Step 5: Enable video and hand control over to the test
        ;; code proper.
        bit     $2002
*       bit     $2002
        bpl     -
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2005           ; Clear out VRAM pointers
        sta     $2005
        lda     #$80
        sta     $2000
        lda     #$1e
        sta     $2001
        cli
loop:   jmp     loop

        ;; Setup data
msg:    .byte   "SIMULTANEOUS PER-FRAME VRAM BLIT"
        .byte   "       NOW ATTEMPTING:  1       "

palette:
        .byte   $0e,$16,$00,$30,$0e,$02,$03,$01,$0e,$36,$00,$00,$0e,$25,$00,$00
        .byte   $0e,$10,$00,$06,$0e,$19,$3c,$2a,$0e,$01,$03,$30,$0e,$38,$28,$17


vblank:
        lda     #$07            ; Do a Sprite DMA
        sta     $4014
        jmp     (vector)        ; Then handle the rest of the display

        ;; Line 7
l7:     lda     #$22
        sta     $2006
        lda     #$c0
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 6
l6:     lda     #$22
        sta     $2006
        lda     #$80
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 5
l5:     lda     #$22
        sta     $2006
        lda     #$40
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 4
l4:     lda     #$22
        sta     $2006
        lda     #$00
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 3
l3:     lda     #$21
        sta     $2006
        lda     #$c0
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 2
l2:     lda     #$21
        sta     $2006
        lda     #$80
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 1
l1:     lda     #$21
        sta     $2006
        lda     #$40
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -
        ;; Line 0
l0:     lda     #$21
        sta     $2006
        lda     #$00
        sta     $2006
        ldx     #$1f
*       lda     buffer,x
        sta     $2007
        dex
        bpl     -

        ;; reset graphics for frame display
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2005
        sta     $2005

        ;; Generate RAM to blit next frame.
        ldx     start
        inx
        cpx     #26
        bne     +
        ldx     #$00
*       stx     start
        txa
        clc
        adc     #$41
        tay
        ldx     #$1f
*       sty     buffer,x
        iny
        cpy     #$5b
        bne     +
        ldy     #$41
*       dex
        bpl     --

irq:    rti

        .advance $fffa
        .word   vblank, reset, irq

;;; CHR-ROM
        .org    $0000
        ;; The HALOGEN font, conveniently filed where ASCII would file
        ;; its characters.

        ;; Punctuation: 3 tiles.  $2C-$2E.  Duplicated planes.
        .advance $02c0
        .byte   $00,$00,$00,$00,$00,$18,$18,$30 ; ,
        .byte   $00,$00,$00,$00,$00,$18,$18,$30 ; ,
        .byte   $00,$00,$00,$7E,$00,$00,$00,$00 ; -
        .byte   $00,$00,$00,$7E,$00,$00,$00,$00 ; -
        .byte   $00,$00,$00,$00,$00,$18,$18,$00 ; .
        .byte   $00,$00,$00,$00,$00,$18,$18,$00 ; .

        ;; Numbers. 10 tiles.  $30-$39.  Duplicated planes.
        .advance $0300
        .byte   $3C,$66,$6E,$76,$66,$66,$3C,$00 ; 0
        .byte   $3C,$66,$6E,$76,$66,$66,$3C,$00 ; 0
        .byte   $18,$18,$38,$18,$18,$18,$18,$00 ; 1
        .byte   $18,$18,$38,$18,$18,$18,$18,$00 ; 1
        .byte   $7C,$06,$06,$0C,$18,$00,$7E,$00 ; 2
        .byte   $7C,$06,$06,$0C,$18,$00,$7E,$00 ; 2
        .byte   $7E,$0C,$00,$1C,$06,$06,$7C,$00 ; 3
        .byte   $7E,$0C,$00,$1C,$06,$06,$7C,$00 ; 3
        .byte   $06,$0E,$1E,$66,$7F,$00,$06,$00 ; 4
        .byte   $06,$0E,$1E,$66,$7F,$00,$06,$00 ; 4
        .byte   $7E,$00,$7C,$06,$06,$06,$7C,$00 ; 5
        .byte   $7E,$00,$7C,$06,$06,$06,$7C,$00 ; 5
        .byte   $3C,$00,$60,$7C,$66,$66,$3C,$00 ; 6
        .byte   $3C,$00,$60,$7C,$66,$66,$3C,$00 ; 6
        .byte   $7E,$00,$06,$0C,$0C,$18,$18,$00 ; 7
        .byte   $7E,$00,$06,$0C,$0C,$18,$18,$00 ; 7
        .byte   $3C,$66,$66,$3C,$66,$66,$3C,$00 ; 8
        .byte   $3C,$66,$66,$3C,$66,$66,$3C,$00 ; 8
        .byte   $3C,$66,$66,$26,$0C,$0C,$18,$00 ; 9
        .byte   $3C,$66,$66,$26,$0C,$0C,$18,$00 ; 9

        ;; Letters: 26 tiles.  $41-$5a.  Duplicated planes.
        .advance $0410
        .byte   $18,$18,$0C,$2C,$66,$66,$7E,$00 ; A
        .byte   $18,$18,$0C,$2C,$66,$66,$7E,$00 ; A
        .byte   $7C,$06,$06,$7C,$66,$66,$7C,$00 ; B
        .byte   $7C,$06,$06,$7C,$66,$66,$7C,$00 ; B
        .byte   $3E,$60,$60,$60,$60,$60,$3E,$00 ; C
        .byte   $3E,$60,$60,$60,$60,$60,$3E,$00 ; C
        .byte   $78,$0C,$06,$66,$66,$6C,$78,$00 ; D
        .byte   $78,$0C,$06,$66,$66,$6C,$78,$00 ; D
        .byte   $7E,$00,$00,$7E,$60,$60,$7E,$00 ; E
        .byte   $7E,$00,$00,$7E,$60,$60,$7E,$00 ; E
        .byte   $7E,$00,$00,$7E,$60,$60,$60,$00 ; F
        .byte   $7E,$00,$00,$7E,$60,$60,$60,$00 ; F
        .byte   $3E,$7E,$60,$66,$60,$7E,$3E,$00 ; G
        .byte   $3E,$7E,$60,$66,$60,$7E,$3E,$00 ; G
        .byte   $66,$06,$06,$7E,$66,$66,$66,$00 ; H
        .byte   $66,$06,$06,$7E,$66,$66,$66,$00 ; H
        .byte   $18,$18,$18,$18,$18,$18,$18,$00 ; I
        .byte   $18,$18,$18,$18,$18,$18,$18,$00 ; I
        .byte   $0C,$0C,$0C,$0C,$0C,$7C,$78,$00 ; J
        .byte   $0C,$0C,$0C,$0C,$0C,$7C,$78,$00 ; J
        .byte   $66,$4C,$18,$30,$78,$6C,$66,$00 ; K
        .byte   $66,$4C,$18,$30,$78,$6C,$66,$00 ; K
        .byte   $60,$60,$60,$60,$60,$60,$7E,$00 ; L
        .byte   $60,$60,$60,$60,$60,$60,$7E,$00 ; L
        .byte   $7E,$63,$63,$6B,$6B,$6B,$6B,$00 ; M
        .byte   $7E,$63,$63,$6B,$6B,$6B,$6B,$00 ; M
        .byte   $7C,$66,$66,$66,$66,$66,$66,$00 ; N
        .byte   $7C,$66,$66,$66,$66,$66,$66,$00 ; N
        .byte   $3C,$66,$66,$66,$66,$66,$3C,$00 ; O
        .byte   $3C,$66,$66,$66,$66,$66,$3C,$00 ; O
        .byte   $7C,$06,$06,$7C,$60,$60,$60,$00 ; P
        .byte   $7C,$06,$06,$7C,$60,$60,$60,$00 ; P
        .byte   $3C,$66,$66,$66,$6C,$30,$18,$00 ; Q
        .byte   $3C,$66,$66,$66,$6C,$30,$18,$00 ; Q
        .byte   $7C,$06,$06,$7C,$18,$0C,$06,$00 ; R
        .byte   $7C,$06,$06,$7C,$18,$0C,$06,$00 ; R
        .byte   $30,$60,$60,$3C,$06,$06,$7C,$00 ; S
        .byte   $30,$60,$60,$3C,$06,$06,$7C,$00 ; S
        .byte   $7E,$00,$00,$30,$30,$30,$1C,$00 ; T
        .byte   $7E,$00,$00,$30,$30,$30,$1C,$00 ; T
        .byte   $66,$66,$66,$66,$66,$66,$3E,$00 ; U
        .byte   $66,$66,$66,$66,$66,$66,$3E,$00 ; U
        .byte   $66,$66,$66,$66,$66,$3C,$18,$00 ; V
        .byte   $66,$66,$66,$66,$66,$3C,$18,$00 ; V
        .byte   $63,$63,$63,$4B,$1F,$37,$63,$00 ; W
        .byte   $63,$63,$63,$4B,$1F,$37,$63,$00 ; W
        .byte   $66,$66,$3C,$18,$3C,$66,$66,$00 ; X
        .byte   $66,$66,$3C,$18,$3C,$66,$66,$00 ; X
        .byte   $66,$66,$66,$3C,$00,$00,$18,$00 ; Y
        .byte   $66,$66,$66,$3C,$00,$00,$18,$00 ; Y
        .byte   $7E,$00,$00,$18,$30,$60,$7E,$00 ; Z
        .byte   $7E,$00,$00,$18,$30,$60,$7E,$00 ; Z

        ;; The rest of the pattern space is blank.
        .advance $2000
