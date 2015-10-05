;;; Linecrunch test program
        
        ;; PRG header
        .outfile "linecrunch.prg"
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
        lda     #$00
        sta     $d012
        lda     #<irq
        sta     $314
        lda     #>irq
        sta     $315
        lda     #$01
        sta     $d01a
        rts

;;; Constraint: "natural" bad line started after finishing a previous character, canceled before cycle 13
;;; Fastest case: Cycle 63 from previous line (PAL) + 1 (target cycle) - 38 (fastest IRQ) = write on cycle 26 or later
;;; Slowest case: Cycle 65 from previous line (new NTSC) + 12 (target cycle) - 44 (slowest IRQ) = write on cycle 33 or earlier
;;; We're doing this twice, so we'll wait 64 cycles between rewrites and target cycle 30 the first time.
irq:    lda     #$01            ;  2 (Acknowledge interrupt)
        sta     $d019           ;  6
        bit     $d012           ; 10 (Top half of screen?)
        bvc     top_irq         ; 12 (if so, prepare for midscreen case)
        lda     #$01            ; 14 (New IRQ raster)
        sta     $d012           ; 18
        nop                     ; 20
        nop                     ; 22
        nop                     ; 24
        inc     $d011           ; 30 (Trigger linecrunch!)
        ldx     #11             ; Burn 58 cycles
*       dex
        bne     -
        nop 
        inc     $d011           ; Do it again, losing one cycle (PAL) or gaining one (new NTSC)        
        ;; Process timer interrupt, if any
        lda     $dc0d
        beq     notime
        jmp     $ea31
top_irq:        
        lda     #$1b            ; Fix scroll
        sta     $d011
        lda     #$62            ; And trigger just before a badline
        sta     $d012
notime: jmp     $febc           ; Never do timer IRQ here
