        ;; This is the interrupt routine used by both versions of the
        ;; "Color Clock Experiment", featured in several articles
        ;; involving perfect timing or bad line experiments.
        .word   $c000
        .org    $c000

        ;; This is a batch of mostly-no-op instructions, such that
        ;; indexing into it for execution increases the execution time
        ;; by one cycle per byte. See the "Cycle-Accurate Delays on
        ;; the 6502" article for full details.
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9
        .byte   $c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c9,$c5
        nop

        inc     $d021           ; Fastest possible visible change
        lda     #$01            ; Acknowledge interrupt
        sta     $d019
        ldx     $d012           ; Are we mid-screen?
        bmi     done
        lda     #$0f            ; If not, turn screen grey again for top
        sta     $d021
        lda     #$92            ; And change target raster from 1 to $92
done:   sta     $d012           ; Set target raster ($01 or $92)
        lda     $dc0d           ; then forward to timer interrupt
        beq     notime
        jmp     $ea31
notime: jmp     $febc
