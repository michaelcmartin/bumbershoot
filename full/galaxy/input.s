;;;--------------------------------------------
;;; An input module for the NES.  The following routines are supported:
;;;
;;; input_read:     Updates controller status.
;;; input_pressed:  Returns zero if its argument has just been
;;;                 pressed.
;;; input_released: Returns zero if its argument has just been
;;;                 released.
;;; input_down:     Returns zero if its argument is currently
;;;                 being held down.
;;; input_up:       Returns zero if its argument is currently NOT
;;;                 being held down.
;;;
;;; For all the routines but input_read, the arguments are as follows:
;;;       The ACCUMULATOR holds an ORing of various direction flags
;;;             (see below).  All these flags must meet the criterion
;;;             for the routine to return nonzero.
;;;       The X REGISTER holds 0 if controller 1 is to be checked, or 1
;;;             if controller 2 is to be checked.  It is an error to
;;;             call the routine with any other value in X.
;;;       The ACCUMULATOR and X REGISTER are destroyed.
;;;       The return value is in the STATUS FLAGS (Zero bit).
;;;
;;;
;;; input_read requires no special arguments.  All registers are
;;;       destroyed.
;;;
;;; The following constants are defined, and an OR of these masks are
;;; passed as arguments to the routines above.
;;;
;;; input_btn_a
;;; input_btn_b
;;; input_btn_select
;;; input_btn_start
;;; input_dir_up
;;; input_dir_down
;;; input_dir_left
;;; input_dir_right

;;; Note: input_down and input_up can accept X register arguments of 2
;;;       or three.  These check the value of the previous input_read
;;;       call. This is how pressed and released are implemented.

        input_btn_a      = $80
        input_btn_b      = $40
        input_btn_select = $20
        input_btn_start  = $10
        input_dir_up     = $08
        input_dir_down   = $04
        input_dir_left   = $02
        input_dir_right  = $01

!zone input {

        +define ~data, ~.current, 2
        +define ~data, ~.last, 2
        +define ~data, ~.temp, 1

input_read:
        ldx     #$01
        stx     $4016
        dex
        stx     $4016
        jsr     .read_controller
        inx
        ;; Fall through to "call" .read_controller again
        ;; with .X as 1, then return
.read_controller:
        lda     .current, x
        sta     .last, x
        lda     #$00
        sta     .current, x
        ldy     #$08
-:      lda     $4016, x
        lsr
        rol     .current, x
        dey
        bne     -
        rts

input_up:
        sta     .temp
        and     .current, x
        cmp     .temp
        bne     +
        lda     #$01
        rts
+:      lda #$00
        rts

input_down:
        sta     .temp
        and     .current, x
        cmp     .temp
        rts

input_pressed:
        jsr     input_down
        bne     +
        lda     .temp
        inx
        inx
        jsr     input_up
+:      rts


input_released:
        jsr     input_up
        bne     +
        lda     .temp
        inx
        inx
        jsr     input_down
+:      rts

}
