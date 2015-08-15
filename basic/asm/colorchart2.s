        ;; Correct display of the color chart. This is a raster
        ;; interrupt routine that replaces the timer interrupt and is
        ;; designed to fire 16 times per frame.
        .word   $c000
        .org    $c000

        lda     #$01            ; Acknowledge interrupt
        sta     $d019
        inc     $d021           ; Set next stripe color
        lda     $fb             ; Compute next scanline
        clc
        adc     #$08
        cmp     #$da            ; Off the bottom of the chart?
        bcc     done
        lda     #$00            ; If so, change the color to black
        sta     $d021
        lda     #$5a            ; And reset scanline to start of row 2
done:   sta     $d012           ; Register next scanline for IRQ
        sta     $fb             ; And remember what it should have been
        lda     $dc0d           ; Check if there'd have been a timer IRQ
        beq     notime
        jmp     $ea31           ; If so, jump to it
notime: jmp     $febc           ; If not, clean up
