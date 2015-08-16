;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Color Chart: This is essentially a pure-machine code version of
;;; the colorchart2.bas program. Its main benefit is that it's smaller
;;; and the setup speed is about a thousand times faster.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ;; Some handy KERNAL routines
        .alias  chrout          $ffd2
        .alias  getin           $ffe4

        ;; Our variables
        .alias  screenptr       $fb
        .alias  colorptr        $fd

        ;; PRG header
        .word   $0801
        .org    $0801
        .outfile "colorchart.prg"

        ;; BASIC header
        .byte   $0c,$08,$de,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00

        ;; Step 1 - Fill the screen with color 11 and character 160
        lda     #$00            ; Low byte of screen/colmem ptr
        sta     screenptr
        sta     colorptr
        lda     #$07            ; Final high byte of screen mem
        sta     screenptr+1
        lda     #$db            ; Final high byte of color mem
        sta     colorptr+1
        ldx     #$04            ; Number of pages covered
        ldy     #$e7            ; 'Final' offset in last page (= 999 lowbyte)
*       lda     #$a0            ; screen code 160 (reversed space)
        sta     (screenptr),y
        lda     #$0b            ; Color 11 (dark grey)
        sta     (colorptr),y
        dey
        cpy     #$ff
        bne     -
        dex
        beq     +
        dec     screenptr+1
        dec     colorptr+1
        bne     -               ; Always branches
*

        ;; Step 2 - Draw a 16x16 grid of letters, each column its own color
        lda     #$ac
        sta     screenptr       ; Start at $04ac and #d8ac; inherit our
        sta     colorptr        ; high bytes from the previous loop
        ldx     #$10            ; 16 rows
row_lp: ldy     #$00
col_lp: iny                     ; Y+1 into A
        tya
        dey                     ; Then fix Y again
        sta     (screenptr),y   ; POKE SCREEN+Y,Y+1 (A, B, C...)
        tya
        sta     (colorptr),y    ; POKE COLOR+Y,Y (black,white,red...)
        iny
        cpy     #$10
        bne     col_lp
        clc                     ; Add 40 to both pointers to advance
        lda     #40             ; one row
        adc     screenptr
        sta     screenptr
        lda     #$00
        adc     screenptr+1
        sta     screenptr+1
        ;; We know screenptr+1 wasn't $FF, so the carry bit is now clear
        lda     #40
        adc     colorptr
        sta     colorptr
        lda     #$00
        adc     colorptr+1
        sta     colorptr+1
        dex
        bne     row_lp

        ;; Step 3 - Set up our color-striping interrupt
        sei                     ; Leave interrupts off while we configure
        lda     #$1b            ; Raster bit 9 is 0, all other settings default
        sta     $d011
        lda     #$7f            ; Disable timing interrupts
        sta     $dc0d
        lda     #<intr          ; Load our interrupt into the IRQ vector
        sta     $0314
        lda     #>intr
        sta     $0315
        lda     #$5a            ; First target raster is 90
        sta     $d012
        sta     $fb             ; Interrupt routine will use $FB to remember it
        lda     #$01            ; Enable raster interrupts...
        sta     $d01a
        lda     #$00            ; Start with a black background...
        sta     $d021
        cli                     ; And let interrupts happen again.

        ;; Step 4 - Wait for a key to be pressed. This is a pretty boring
        ;;          main program, but all the real work is happening in the
        ;;          interrupt routines anyway.
keylp:  jsr     getin
        beq     keylp

        ;; Step 5 - Reset interrupts and quit gracefully
        sei
        lda     #$00
        sta     $d01a
        lda     #$31
        sta     $0314
        lda     #$ea
        sta     $0315
        lda     $91
        sta     $dc0d
        cli
        lda     #$06            ; Restore blue background color
        sta     $d021
        lda     #$93            ; Clear screen
        jmp     chrout

        ;; Our interrupt routine
intr:   lda     #$01            ; Acknowledge raster interrupt
        sta     $d019
        inc     $d021           ; Increment background color
        lda     $fb             ; We are using $FB to hold our raster
        clc
        adc     #$08            ; Add 8 for the next character
        cmp     #$da            ; Are we past our last row?
        bcc     done            ; If not, we're set
        lda     #$00            ; If so, BG back to black...
        sta     $d021
        lda     #$5a            ; And target raster is 90 again
done:   sta     $d012           ; Mark target raster
        sta     $fb             ; ... and save it for next time
        lda     $dc0d           ; Check Timer interrupt.
        beq     notm            ; Is there a timer interrupt waiting?
        jmp     $ea31           ; If so, go handle it
notm:   jmp     $febc           ; If not, conclude interrupt processing
