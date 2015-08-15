        ;; A "friendlier" version of colorchart0.s that does roughly
        ;; the same thing but doesn't monopolize the system
        ;; permanently
        .word   $c000
        .org    $c000

        ;; Start of loop: wait for VBLANK by waiting until the raster
        ;; is > 256 and then for raster < 256. We should basically
        ;; trap around raster line 0 (or at worst 10 or 11 or so if
        ;; the timer interrupt hit us).
main:   bit     $d011
        bpl     main
vblank: bit     $d011
        bmi     vblank
        ;; Now we're at the top of the screen.
        lda     #$00            ; Turn the background black
        sta     $d021
        ldx     #$0e            ; Looping 15 times
        sei                     ; Block the timer during display
        lda     #$5a            ; First trap is raster 5a (second line)
lp:     cmp     $d012           ; Wait until raster matches accumulator
        bne     lp
        inc     $d021           ; Bump background color
        clc                     ; Next target raster is 8 lines later
        adc     #$08
        dex                     ; Do the loop (BPL means it's 15 loops
        bpl     lp              ; with an initial #$0e)
        cli                     ; Re-enable timer interrupts
        jsr     $ffe4           ; GETIN
        beq     $c000           ; Loop back to VBLANK-wait if no key hit
        rts                     ; Quit back to BASIC if key hit
