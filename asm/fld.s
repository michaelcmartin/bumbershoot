        .outfile "fld.prg"
        .word   $0801
        .org    $0801

        .word   +, 2015
        .byte   $9e, " 2062", 0
*       .word   0

        jmp     main

        ;; Data!
        .alias  quit       $02
        .alias  raster     $fb
        .alias  nextscroll $fc
        .alias  skip       $fd
        .alias  remaining  $fe

.scope
frame_top:
        ;; Reset idle graphic and ack interrupt
        lda     #$01
        sta     $3fff
        lda     #$01
        sta     $d019
        jsr     frame_advance

        ;; Is the total scroll < 8?
        lda     skip
        cmp     #$08            ; If not, we have YSCROLL in A, so
        bcc     _no_fld         ; skip to the end
        ;; Compute remaining lines; we'll eat the first batch of 6
        ;; while we're at it
        sec
        sbc     #$06
        sta     remaining
        lda     #$36            ; Which means our first checkpoint
        sta     $d012           ; is at scanline $36
        sta     raster
        lda     #<fld_irq       ; Redirect the IRQ to our FLD code
        sta     $0314
        lda     #$05            ; Then initialize our FLD counters
        sta     nextscroll
        lda     #$07
        ;; And now fall through to the "no FLD" case, with A holding
        ;; our scroll value (7, the lowest we can make it go)
_no_fld:
        ora     #$18            ; Set the other $d011 bits
        sta     $d011           ; Store them for the frame
_timer_check:
        lda     $dc0d
        beq     +
        jmp     $ea31
*       jmp     $febc

;;; And now, the FLD IRQ. We have various timing priorities here.
;;;
;;; - We need to SHIFT YSCROLL back two lines so we "miss the bus"
;;;   before cycle 19.
;;; - We need to ADJUST THE IDLE GRAPHIC while in the border (19-33
;;;   cycles after the start of our routine).
;;; - If we are configuring the final value of YSCROLL here we must do
;;;   so before cycle 82, so the badline starts on schedule.
;;; - If we aren't, we've got over 350 cycles to work in and we are
;;;   totally fine.
fld_irq:
        lda     #$01            ;  2 - Ack IRQ
        sta     $d019           ;  6
        lda     nextscroll      ;  9
        ora     #$18            ; 11
        sta     $d011           ; 15 - "Miss the bus" to extend FLD, granting us some more lines to work in
        lda     $3fff           ; 19 - update idle graphic
        asl                     ; 21
        bcc     +               ; 23 - non-branch case is slower, count that instead
        ora     #$01            ; 25
*       sta     $3fff           ; 29 - still well in safe zone either way
        lda     remaining       ; 32
        cmp     #$08            ; 34
        bcs     _more_fld       ; 36
        sec                     ; 38
        adc     nextscroll      ; 41 - final value is (remaining + nextscroll + 1) & $07
        and     #$07            ; 43
        ora     #$18            ; 45 - add the $d011 flags
        sta     $d011           ; 49 - loads of time left and we're off the hook from here on out
        lda     #$01
        sta     $d012
        lda     #<frame_top
        sta     $0314
        bne     _timer_check
_more_fld:
        ;; We've got five scanlines now to compute the next value, we're fine
        ;; Also, if we've gotten here, the carry flag is already set
        sbc     #$06
        sta     remaining
        clc
        lda     raster
        adc     #$06
        sta     raster
        sta     $d012
        sec
        sbc     #$01
        and     #$07
        sta     nextscroll
        jmp     $febc

        .checkpc $900
.scend

.scope
frame_advance:
        ;; Rotate the idle graphic for the next frame, in place
        lda     frame_top+1
        asl
        bcc     +
        ora     #$01
*       sta     frame_top+1
        ;; Check joystick to alter skip and check for quit
        lda     $dc00
        pha
        and     #$10
        eor     #$10
        sta     quit
        pla
        lsr                     ; Carry bit clear on "up"
        bcs     _not_up
        ldx     skip
        beq     _not_up
        dex
        stx     skip
_not_up:
        lsr                     ; Carry bit clear on "down"
        bcs     _not_down
        ldx     skip
        cpx     #203
        bcs     _not_down
        inx
        stx     skip
_not_down:
        rts
.scend

main:   lda     #$03
        sta     skip
        lda     #$00
        sta     quit

        sei
        lda     #$7f
        sta     $dc0d
        lda     #$1b
        sta     $d011
        lda     #$32
        sta     $d012
        lda     #<frame_top
        sta     $0314
        lda     #>frame_top
        sta     $0315
        lda     #$01
        sta     $d01a
        cli

        ldy     #$00
*       lda     msg, y
        beq     +
        jsr     $ffd2
        iny
        bne     -

*       lda     quit
        beq     -

        sei
        lda     #$00
        sta     $d01a
        lda     #$1b
        sta     $d011
        lda     #$31
        sta     $0314
        lda     #$ea
        sta     $0315
        lda     #$81
        sta     $dc0d
        cli

        rts

msg:    .byte 13,"FLEXIBLE LINE DISTANCE DEMO",13
        .byte "SCROLL SCREEN WITH JOYSTICK IN PORT 2",13
        .byte "PRESS FIRE BUTTON TO QUIT",13,0
