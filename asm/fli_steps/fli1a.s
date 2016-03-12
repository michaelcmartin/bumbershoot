;;; Flexible Line Interpretation: One-Charline Test Program
;;;
;;; The goal of this test program is to cram all sixteen colors into a
;;; single bitmapped character.
;;;
;;; This code uses a macro loop to generate the display interrupt,
;;; and must be assembled with the ACME assembler.

        ;; PRG header
        !to "fli1a.prg", cbm
        * = $0801

        ;; BASIC header
        !16     +, 2016
        !raw    $9e, " 2062",0
+:      !16     0

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
        cmp     $d012           ;  0- 1 (line $93)
        beq     +               ;  3
+:      txs                     ;  5
        nop                     ;  7
        nop                     ;  9
        nop                     ; 11
!for .i, 1, 7 {
        nop                     ; 56
        nop                     ; 58
        nop                     ; 60
        nop                     ; 62
        nop                     ; 64
        cmp     $03             ;  2
        lda     #.i*$10+$08     ;  4
        sta     $d018           ;  8
        lda     #$38|((.i+3)&7) ; 10
        sta     $d011           ; 14->54
}
        ;; End of interrupt
        lda     #$3b
        sta     $d011
        lda     #$08
        sta     $d018
        lda     #$91
        sta     $d012
        lda     #<irq
        sta     $0314
        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc

!if * > $0900 {
        !error "IRQ has extended past ", $0900," to ", *, "; tighten it up."
}

!zone main {
;;; Main program
main:
        ;; Initialize the bitmap screen.
        ;; 1. Wipe out the entirety of VIC bank 1
        lda     #$40
        sta     .lp+2
        lda     #$00            ; Change to $FF to hide FLI-bug
        ldy     #$00
        ldx     #$40
.lp:    sta     $4000, y
        iny
        bne     .lp
        inc     .lp+2
        dex
        bne     .lp
        ;; 2. Draw the bit pattern 0F in each line of the mid-screen
        ;;    character (20, 12)
        lda     #$0f
        ldx     #$08
.lp2:   sta     $5fff+12*320+20*8, x
        dex
        bne     .lp2
        ;; 3. Draw appropriate colors ($10, $32, ... $FE) into the
        ;;    eight video matrices from $4000-$5FFF
        lda     #$41
        sta     .lp3+2
        lda     #$10
        ldx     #$08
.lp3:   sta     $41f4
        clc
        adc     #$22            ; Never carries when used
        pha
        lda     .lp3+2
        adc     #$04
        sta     .lp3+2
        pla
        dex
        bne     .lp3
}

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
        lda     #$91
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
