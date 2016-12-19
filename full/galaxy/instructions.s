!zone instructions {
prep_instructions:
        jsr     graphics_reset
        +mov16  str_ptr, .data
        jsr     draw_text
        jsr     clear_sprite_ram

        ;; Place the sample sprites
        lda     #$70            ; X coordinate for both
        sta     sprites+7
        sta     sprites+11
        lda     #$03            ; Palette data
        sta     sprites+6
        lda     #$01
        sta     sprites+10
        ldx     #$F2            ; Sprite indices (star)
        stx     sprites+5
        inx                     ; (Fuel Dump)
        stx     sprites+9
        lda     #143            ; Y coordinates
        sta     sprites+4
        lda     #167
        sta     sprites+8

        lda     #<wait_for_start
        sta     game_vec
        lda     #>wait_for_start
        sta     game_vec+1

        jsr     rest_screen
        rti

.data:
!8 $20,$63
!text "GALAXY PATROL INSTRUCTIONS",0
!8 $20,$A0
!text " FLY YOUR SHIP THROUGH THE STAR "
!text " FIELD. HITTING A STAR OR       "
!text " RUNNING OUT OF FUEL WILL END   "
!text " THE GAME.  HITTING A FUEL DUMP "
!text " WILL GIVE YOU ", $12,$15, " UNITS OF      "
!text " FUEL.",0
!8 $22,$50
!text "STAR",0
!8 $22,$B0
!text "FUEL DUMP",0
!8 $23,$8A
!text "PRESS  START",0
!8 $00

wait_for_start:
        lda     #>sprites
        sta     $4014
        jsr     input_read
        ldx     #$00
        lda     #input_btn_start
        jsr     input_released
        bne     +
        lda     #<prep_title
        sta     game_vec
        lda     #>prep_title
        sta     game_vec+1
+:      rti

}
