;;; Double IRQ Raster stabilizer test
;;; New NTSC only!

        ;; PRG header
        .outfile "stabilize.prg"
        .word   $0801
        .org    $0801
        
        ;; BASIC header
        .word   +, 2015
        .byte   $9e, " 2062", 0
*       .word   0

        ;; Perfunctory main program; set up IRQ and back to BASIC
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$94
        sta     $d012
        lda     #<irq
        sta     $314
        lda     #>irq
        sta     $315
        lda     #$01
        sta     $d01a
        rts

        ;; IRQ phase one; set up another IRQ where we know we were
        ;; executing a 2-cycle instruction.
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
        ;; The second IRQ has it, and so we are either cycle 38 or 39
        ;; going in.
irq2:   lda     #$01            ; 40-41
        sta     $d019           ; 44-45
        tsx                     ; 46-47
        txa                     ; 48-49
        clc                     ; 50-51
        adc     #$06            ; 52-53
        tax                     ; 54-55
        cmp     $03             ; 57-58 (marking time)
        lda     $d012           ; 61-62
        cmp     $d012           ;  0- 1
        beq     stable          ;  3
stable: txs                     ;  5
        ;; Now for the actual main IRQ routine. Nothing fancy here:
        ;; we'll just wait awhile and change the background color for a
        ;; bit so we get a solid and stable line drawn on the screen.
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda     #$00
        sta     $d021           ; cycle 31 = character 14
        nop
        nop
        nop
        nop
        nop
        lda     #$06
        sta     $d021           ; cycle 47 = character 30
        ;; Now reset for the next frame
        lda     #$94
        sta     $d012
        lda     #<irq
        sta     $0314
        lda     $dc0d
        beq     notime
        jmp     $ea31
notime: jmp     $febc
