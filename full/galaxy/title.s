!zone do_title {
        +define ~data, ~.loc, 1
        +define ~data, ~.color, 1
        +define ~data, ~.line_start, 2
        +define ~data, ~.value, 1

do_title:
        ;; Palette swap the title graphic.
        ldx     .color
        lda     .colors,x
        jsr     set_color

        ;; locate the arrow appropriately, and update SPR-RAM
        ldx     .loc
        bne     +
        lda     #102
        !8      $2c             ; skip next instruction
+:      lda     #126
        sta     sprites+4
        sta     sprites+8
        lda     #>sprites
        sta     $4014

        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2005
        sta     $2005

        ;; We're now finished with VRAM.  Time to do the processor stuff while the PPU does
        ;; its thing.

        ;; update the palette color index.
        ldx     .color
        inx
        cpx     #$08
        bne     +
        ldx     #$00
+:      stx     .color

        jsr     input_read
        ldx     #$00
        lda     #input_btn_select
        jsr     input_pressed
        bne     +
        tax                     ; shift value to X
        lda     .loc            ; Reverse the value of the location
        eor     #1
        sta     .loc
        txa                     ; And restore the accumulator
+:      ldx     #$00
        lda     #input_btn_start
        jsr     input_released
        beq     .done
        jsr     random_update
irq:    rti

        ;; .loc has 0 for "play game" and 1 for "instructions"
.done:  lda     .loc
        beq     +
        lda     #<prep_instructions
        sta     game_vec
        lda     #>prep_instructions
        sta     game_vec+1
        rti
+:      lda     #<prep_game
        sta     game_vec
        lda     #>prep_game
        sta     game_vec+1
        rti

.colors: !8 21,22,23,24,40,39,38,37

;;; This routine will noticably glitch out the graphics if we let it
;;; run unmolested. We add a few extra vblank waits as we draw this
;;; out so that the display will remain properly blanked.
prep_title:
        jsr     graphics_reset
        lda     #$00
        sta     $2006
        sta     $2006
-:      bit     $2002
        bpl     -
        ;; Load palette
        lda     #$3F
        ldx     #$00
        sta     $2006
        stx     $2006
-:      lda     .palette,x
        sta     $2007
        inx
        cpx     #$20
        bne     -
        lda     #$00
        sta     $2006
        sta     $2006
-:      bit     $2002
        bpl     -

;;; Prepare title graphic.  Accumulator holds current value, X and Y hold coordinates.

        +mov16  .line_start, $20C4
        lda     #$80
        sta     .value

        ;; Now to draw the actual title.
        ldy     #3
--:     ldx     #24
        lda     .line_start+1
        sta     $2006
        lda     .line_start
        sta     $2006
-:      lda     .value
        sta     $2007
        inc     .value
        dex
        bne     -
        +inc16  .line_start, $20
        lda     #$00
        sta     $2006
        sta     $2006
-:      bit     $2002
        bpl     -
        dey
        bne     --

        +mov16  str_ptr, .data
        lda     #<.data
        sta     str_ptr
        lda     #>.data
        sta     str_ptr+1
        jsr     draw_text

        lda     #<do_title
        sta     game_vec
        lda     #>do_title
        sta     game_vec+1

        lda     #$00
        sta     .loc
        sta     .color

        ;; Prepare the two sprites for the arrow.
        jsr     clear_sprite_ram
        lda     #$f0
        sta     sprites+5
        lda     #$f1
        sta     sprites+9
        lda     #75
        sta     sprites+7
        lda     #83
        sta     sprites+11
        lda     #2
        sta     sprites+6
        sta     sprites+10

        jsr     rest_screen
        rti

.data:
        !text $20, $62, "BUMBERSHOOT SOFTWARE PRESENTS",0
        !text $21,$ac, "GAME START",0
        !text $22,$0c, "INSTRUCTIONS",0
        !text $23,$96, "V",$12,".",$11,", ",$12,$10,$11,$16,0,0

; palette data
.palette:
!8 $0E,$16,$00,$30,$0E,$02,$03,$01,$0E,$36,$00,$00,$0E,$25,$00,$00
!8 $0E,$10,$00,$06,$0E,$19,$3c,$2a,$0E,$01,$03,$30,$0E,$38,$28,$17

}
