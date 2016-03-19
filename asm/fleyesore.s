;;; Flexible Line Interpretation: Full-screen Test Program

        ;; PRG header
        .outfile "fleyesore.prg"
        .word   $0801
        .org    $0801

        ;; BASIC header
.scope
        .word   _next, 2016
        .byte   $9e, " 2062",0
_next:  .word   0
.scend
        ;; Put the main program at the end, so that we have plenty of
        ;; room for our IRQ to live in the $0810-$08FF range
        jmp     main

;;; IRQ routine, starting with a raster stabilizer...
irq:    lda     #$01            ; 46 (worst case)
        sta     $d019           ; 50
        lda     #<irq2          ; 52
        sta     $314            ; 56
        inc     $d012           ; 62
        cli                     ; 64
        nop
        nop                     ; Now we mark time until
        nop                     ; that next IRQ hits...
        nop                     ; ... this may be excessive NOPpery
        nop
        nop
irq2:   lda     #$01            ; 40-41
        sta     $d019           ; 44-45
        tsx                     ; 46-47
        txa                     ; 48-49
        clc                     ; 50-51
        adc     #$06            ; 52-53
        tax                     ; 54-55
        cmp     $03             ; 57-58 (marking time)
        lda     $d012           ; 61-62
        cmp     $d012           ;  0- 1 (line $32)
        beq     +               ;  3
*       txs                     ;  5
        ldx     #12
*       dex
        bne     -               ;  1 (line $33)
        nop                     ;  3
        nop                     ;  5
        nop                     ;  7
        nop                     ;  9
        ldx     #25             ; 54
        bne     inner-2         ; 57
outer:  nop                     ; 65
        nop                     ;  2
        lda     #$08            ;  4
        sta     $d018           ;  8
        lda     #$3b            ; 10
        sta     $d011           ; 14->54
        cmp     $03             ; 57
        ldy     #$06            ; 59
inner:  nop                     ; 61
        nop                     ; 63
        lda     d018vals, y     ;  2
        sta     $d018           ;  6
        lda     d011vals, y     ; 10
        sta     $d011           ; 14->54
        dey                     ; 56
        bpl     inner           ; 59 (on branchback), 58 (forward)
        dex                     ; 60
        bne     outer           ; 63

        ;; End of interrupt
        lda     #$3b
        sta     $d011
        lda     #$08
        sta     $d018
        lda     #$30
        sta     $d012
        lda     #<irq
        sta     $0314
        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc

d018vals: .byte $78,$68,$58,$48,$38,$28,$18
d011vals: .byte $3a,$39,$38,$3f,$3e,$3d,$3c

;;; Main program
main:
.scope
        ;; Initialize the bitmap screen.
        ;; 1. Draw checkerboard pixels throughout $6000-$7FFF
        lda     #$60
        sta     $fc
        lda     #$55
        ldy     #$00
        sty     $fb
        ldx     #$20
_lp:    asl
        sta     ($fb), y
        lsr
        iny
        sta     ($fb), y
        iny
        bne     _lp
        inc     $fc
        dex
        bne     _lp
        ;; 2. Fill in the color data. Note that .Y and $fb are already
        ;;    zero going in.
        lda     #$40
        sta     $fc
        lda     #$08            ; Page count loop
        sta     $fd
_lp2o:  sec
        lda     #$08            ; Initial color value this screen
        sbc     $fd
        ldx     #$04            ; Four pages per screen
_lp2i:  sta     ($fb), y
        clc
        adc     #$08
        iny
        bne     _lp2i
        inc     $fc
        dex
        bne     _lp2i
        dec     $fd
        bne     _lp2o
.scend

;;; Initialize the VIC-II display; Hi-Res Bitmap at $6000, color
;;; matrix at $4000
        ;; Set Bank 1
        lda     $dd02
        ora     #$03
        sta     $dd02
        lda     $dd00
        and     #$fc
        ora     #$02
        sta     $dd00
        ;; Set video pointers
        lda     #$08
        sta     $d018
        ;; Set Bitmap mode
        lda     #$3b
        sta     $d011

;;; Initialize FLI interrupt
        lda     #$7f
        sta     $dc0d
        lda     #$30
        sta     $d012
        lda     #<irq
        sta     $314
        lda     #>irq
        sta     $315
        lda     #$01
        sta     $d01a

;;; Wait for keys, and update video pointers with each hit
mainloop:
        jsr     $ffe4           ; GETIN
        beq     mainloop

;;; Restore normal interrupt behavior
        lda     #$00
        sta     $d01a
        lda     #$31
        sta     $314
        lda     #$ea
        sta     $315
        lda     #$81
        sta     $dc0d

;;; Restore normal operation.
        lda     #$1b
        sta     $d011
        lda     #$14
        sta     $d018
        lda     $dd02
        ora     #$03
        sta     $dd02
        lda     $dd00
        ora     #$03
        sta     $dd00
        rts
