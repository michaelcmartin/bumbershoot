        playerY = 50

        ;; Game variables
        +define ~data, ~starcount, 1    ; Countdown to new star
        +define ~data, ~difficulty, 1   ; Divider for starcount
        +define ~data, ~dumpcount, 1    ; Countdown to new fuel dump
        +define ~data, ~fuelcount, 1    ; Countdown to fuel expenditure
        +define ~data, ~startsprites, 1 ; Index of first sprite on screen
        +define ~data, ~endsprites, 1   ; Index of last sprite on screen
        +define ~data, ~playerX, 1      ; X coord
        +define ~data, ~playerDX, 1     ; Direction
        +define ~data, ~fuel, 2         ; tens and ones digit for fuel display
        +define ~data, ~score, 6        ; score value
        +define ~data, ~gameover, 1     ; Flag indicating whether or not the
                                        ; game is over, and why

!zone starmap {
        +define ~data, ~.temp, 3

gen_starmap:
        lda     #$40
        sta     .temp
        lda     #$00
        sta     .temp+1
        sta     .temp+2
        inc     .temp+2
.lp:    dec     .temp+2
        beq     +
        lda     #$00            ; Blank space
        beq     ++
+:      jsr     random_update
        lda     random_val+1
        and     #$3F
        sta     .temp+2
        lda     #$F7            ; Background star
++:     sta     $2007
        inc     .temp
        bne     .lp
        inc     .temp+1
        lda     #$04
        cmp     .temp+1
        bne     .lp
        ldx     #$40
        lda     #$55
-:      sta     $2007
        dex
        bne     -
        rts
}

; ----------------------------------------------------


;----------------------------------------------------

        +define ~data, ~scroll_line, 1
        +define ~data, ~scroll_count, 1
        +define ~data, ~scroll_base, 1

do_bg_scroll:
        dec     scroll_count
        bne     +
        lda     #$08
        sta     scroll_count
        inc     scroll_line
        lda     #240
        cmp     scroll_line
        bne     +
        lda     #$00
        sta     scroll_line
        lda     scroll_base
        eor     #$02
        sta     scroll_base
        ora     #$80
        sta     $2000
+:      rts

prep_game:
        jsr     init_game
        lda     #$00
        sta     scroll_line
        lda     #$02
        sta     scroll_count
        lda     #<step_game
        sta     game_vec
        lda     #>step_game
        sta     game_vec+1
        rti

step_game:
        lda     #>sprites       ; Update screen
        sta     $4014

        lda     #$00
        sta     $2005
        lda     scroll_line
        sta     $2005

        jsr     check_collisions
        jsr     read_input
        jsr     move_stars
        jsr     update_player
        jsr     create_line
        jsr     draw_player
        jsr     do_bg_scroll

        lda     gameover
        beq     +

        lda     #<prep_game_over
        sta     game_vec
        lda     #>prep_game_over
        sta     game_vec+1

+:      rti

init_game:
        lda     #0
        sta     gameover ; I'm not dead yet!  "He says he's not dead yet!"
        sta     difficulty      ; Start out brain-dead easy
        jsr     set_star_counter
        jsr     set_dump_counter
        lda     #$10
        sta     score      ; Zero out the score (with pattern numbers)
        sta     score+1
        sta     score+2
        sta     score+3
        sta     score+4
        lda     #$0F
        sta     score+5        ; Correction for immediate sprite set up
        lda     #$18        ; Sprite 6 is the beginning and the end; no sprites made.
        sta     startsprites
        sta     endsprites
        jsr     init_player
        jsr     init_fuel

        ; make starmap
        jsr     kill_screen
        lda     #$24
        sta     $2006
        lda     #$00
        sta     $2006
        jsr     gen_starmap
        jsr     gen_starmap
        jsr     rest_screen
        rts

init_player:
        lda     #120            ; Initial X position
        sta     playerX
        lda     #1              ; Initial DX
        sta      playerDX
        ;; Initialize sprites that comprise the player
        ;; Y coordinates
        lda     #playerY
        sta     sprites+$F0
        sta     sprites+$F4
        lda     #playerY+8
        sta     sprites+$F8
        sta     sprites+$FC
        ;; Patterns
        ldx #$F4                ; Wings
        stx     sprites+$F1
        stx     sprites+$F5
        inx                     ; Nose
        stx     sprites+$F9
        inx                     ; Cockpit
        stx     sprites+$FD
        ;; Palettes
        lda     #0
        sta     sprites+$F2
        sta     sprites+$FE
        lda     #2
        sta     sprites+$FA
        lda     #$40            ; Right wing is horizontally mirrored
        sta     sprites+$F6
        ;; X Coordinates
        jsr     draw_player
        rts

init_fuel:
        lda     #240
        sta     fuelcount
        lda     #5
        sta     fuel
        lda     #0
        sta     fuel+1
        lda     #10
        sta     sprites+4
        sta     sprites+8
        lda     #$15
        sta     sprites+5
        lda     #$10
        sta     sprites+9
        lda     #2
        sta     sprites+6
        sta     sprites+10
        lda     #240
        sta     sprites+7
        lda     #248
        sta     sprites+11
        rts

!zone collisions {
check_collisions:
        ldy     startsprites
.lp:    cpy     endsprites
        bne     +
        rts
+:      jsr     collision_detect
        beq     .no_collision
        cmp     #$F2            ; was it a star?
        bne     +
        lda     #1              ; Game over: Collision
        sta     gameover
        jsr     crash_sound
+:      cmp     #$F3            ; was it a fuel dump?
        bne     +
        jsr     get_fuel
+:      lda     #0
        sta     sprites+1,y     ; Make it disappear on collision
.no_collision:
        tya
        jsr     inc_sprite_count
        tay
        jmp     .lp

;;; The Y register holds an index into the sprite array.  Returns
;;; a value in the accumulator of the pattern of the sprite hit
;;; (or a 0 if no collision).  Zero flag is also appropriately
;;; set.  Note that pattern #0 is "invisible" to sprite collision
;;; detection.
;;; This routine does "unsigned comparisons."  Instead of doing
;;; a CMP followed by checking the N bit (which is bit 7 of the
;;; result, and which contributes to the magnitude of the coordinates)
;;; it instead does an add followed by checking the carry bit.
;;; This routine uses two bounding boxes; one for the wings, and one
;;; for the nose.  It is not pixel-perfect, but it_s pretty close.

collision_detect:
        ;; Check Wing-box.  (x-7 to x+15, y-7 to y+3)
        ;; Check Y coordinate.
        lda     sprites,y
        sec
        sbc     #playerY-7
        clc
        adc     #255-10
        bcs     .no_wing_hit
        ;; check X coordinate
        lda     sprites+3,y
        sec
        sbc     playerX
        clc
        adc     #7
        clc
        adc     #255-22
        bcs     .no_wing_hit
        ;; Wing hit!
        lda     sprites+1,y     ; Get pattern
        rts
.no_wing_hit:
        ;; Check Nose-box.  (x-3 to x+11, y-3 to y+15)
        ;; Check Y coordinate.
        lda     sprites,y
        sec
        sbc     #playerY-3
        clc
        adc     #255-18
        bcs     .no_nose_hit
        ;; check X coordinate
        lda     sprites+3,y
        sec
        sbc     playerX
        clc
        adc     #3
        clc
        adc     #255-14
        bcs     .no_nose_hit
        ;; Nose hit!
        lda     sprites+1,y     ; Get pattern
        rts
.no_nose_hit:
        lda     #0
        rts
}

!zone stars {
move_stars:
        ldy     startsprites
-:      cpy     endsprites
        beq     .done
        lda     sprites,y       ; Get the Y coordinate
        clc
        adc     #$FF            ; Move 1 unit up
        sta     sprites,y
        bcs     +              ; If carry clear, we_re off the screen!
        lda     #0
        sta     sprites+1,y ; Set the tile image to 0, disappearing the sprite.
        tya
        jsr     inc_sprite_count
        sta     startsprites ; Sprite indices increase "linearly", so this is safe.
        tay
        jmp     -
+:      tya
        jsr     inc_sprite_count
        tay
        jmp     -
.done:
        rts
}

inc_sprite_count:
        clc
        adc     #$04
        cmp     #$F0
        bne     +
        lda     #$18
+:      rts

create_line:
        dec     dumpcount
        bne     +
        lda     #$F3        ; Create a new fuel dump
        jsr     create_new_sprite
        jsr     set_dump_counter
        lda     #$08
        clc
        adc     starcount
        sta     starcount
+:      dec     starcount
        bne     +
        lda     #$F2        ; Create a new star
        jsr     create_new_sprite
        jsr     set_star_counter
        lda     #$03
        clc
        adc     dumpcount
        sta     dumpcount
+:      rts

set_dump_counter:
        jsr     get_random_64
        clc
        adc     #$20
        sta     dumpcount
        rts

set_star_counter:
        jsr     get_random_64
        ldx     difficulty
        beq     ++
-:      lsr
        dex
        bne     -
++:     clc
        adc     #$0A
        sta     starcount
        rts

!zone spritery {
        +define ~data, ~.ptr, 2

create_new_sprite:
        tax
        lda     endsprites
        jsr     inc_sprite_count
        sta     endsprites
        sta     .ptr
        lda     #>sprites
        sta     .ptr+1
        ldy     #0
        lda     #240            ; Y value (.Y*8)
        sta     (.ptr),y
        iny
        txa
        sta     (.ptr),y
        iny
        cpx     #$F3            ; Was it a fuel dump?
        bne     +
        lda     #$01            ; Palette
        !8      $2c             ; Skip next instruction
+:      lda     #$03
        sta     (.ptr),y
        iny
        jsr     get_random_spriteloc
        sta     (.ptr),y        ; X value
        rts

draw_player:
        ;; Update the X coordinates appropriately for the ship.
        lda     playerX
        sta     sprites+$F3
        clc
        adc     #4
        sta     sprites+$FB
        sta     sprites+$FF
        clc
        adc     #4
        sta     sprites+$F7
        rts

update_player:
        lda     playerX
        cmp     #2
        bne     +
        lda     #1
        sta     playerDX
        lda     #3
        jmp     ++
+:      cmp     #238
        bne     +
        lda     #$FF
        sta     playerDX
        lda     #237
        jmp     ++
+:      clc
        adc     playerDX
++:     sta     playerX
        dec     fuelcount
        bne     +
        jsr     spend_fuel
        lda     #8
        sta     fuelcount
+:      rts

spend_fuel:
        ldx     fuel+1
        beq     +
        dex
        stx     fuel+1
        txa
        clc
        adc     #$10
        sta     sprites+9
        jsr     bump_score
        rts
+:      ldx     fuel
        beq     .out_of_fuel
        dex
        stx     fuel
        txa
        clc
        adc     #$10
        sta     sprites+5
        lda     #9
        sta     fuel+1
        lda     #$19
        sta     sprites+9
        jsr     bump_score
        rts
.out_of_fuel:
        lda     #2              ; Game over!  Out of fuel
        sta     gameover
        jsr     empty_sound
        rts
}

get_fuel:
        lda     #5
        clc
        adc     fuel+1
        cmp     #10
        bmi     +
        sec
        sbc     #10
        sec
+:      sta     fuel+1
        lda     #2
        adc     fuel
        cmp     #10
        bmi     +
        ;; Overload!  Set fuel to 99 gallons
        lda     #9
        sta     fuel+1
+:      sta     fuel
        clc
        adc     #$10
        sta     sprites+5
        lda     fuel+1
        adc     #$10
        sta     sprites+9
        jsr     high_c
        rts

bump_score:
        lda     score
        cmp     #$F2            ; Overflow?
        bne     +
        rts
+:      lda     #1
        adc     score+5
        cmp     #$1A
        bmi     +
        sec
        sbc     #10
        sec
+:      sta     score+5
        lda     #0
        adc     score+4
        cmp     #$1A
        bmi     +
        sec
        sbc     #10
        inc     difficulty
        sec
+:      sta     score+4
        lda     #0
        adc     score+3
        cmp     #$1A
        bmi     +
        sec
        sbc     #10
        sec
+:      sta     score+3
        lda     #0
        adc     score+2
        cmp     #$1A
        bmi     +
        sec
        sbc     #10
        sec
+:      sta     score+2
        lda     #0
        adc     score+1
        cmp     #$1A
        bmi     +
        sec
        sbc     #10
        sec
+:      sta     score+1
        lda     #0
        adc     score
        sta     score
        cmp     #$1A
        bpl     +
        rts
+:      lda     #$F2
        ldy     #0
-:      sta     score,y
        iny
        cpy     #6
        bne     -
        rts

read_input:
        jsr     input_read

        ldx     #$00
        stx     playerDX
        lda     #input_dir_left
        jsr     input_down
        bne     +
        lda     #$FF
        sta     playerDX

+:      ldx     #$00
        lda     #input_dir_right
        jsr     input_down
        bne     +

        lda     #$01
        sta     playerDX

+:      rts

;----------------------------------------------------

prep_game_over:
        jsr     graphics_reset
        lda     #<game_over_data
        sta     str_ptr
        lda     #>game_over_data
        sta     str_ptr+1
        jsr     kill_screen
        jsr     draw_text
        ldx     gameover
        dex
        bne     +
        lda     #<game_over_collision
        sta     str_ptr
        lda     #>game_over_collision
        sta     str_ptr+1
        jmp     ++
+:      lda     #<game_over_fuel
        sta     str_ptr
        lda     #>game_over_fuel
        sta     str_ptr+1
++:     jsr     draw_text
        ;; position the score sprites
        ;; Y coordinate
        lda     #127
        ldy     #0
        jsr     set_score_attr
        ;; Palettes
        lda     #1
        ldy     #2
        jsr     set_score_attr
        ;; Patterns
        lda     score
        sta     sprites+1
        lda     score+1
        sta     sprites+5
        lda     score+2
        sta     sprites+9
        lda     score+3
        sta     sprites+13
        lda     score+4
        sta     sprites+17
        lda     score+5
        sta     sprites+21
        ;; X coordinates
        lda     #$80
        sta     sprites+3
        lda     #$88
        sta     sprites+7
        lda     #$90
        sta     sprites+11
        lda     #$98
        sta     sprites+15
        lda     #$a0
        sta     sprites+19
        lda     #$a8
        sta     sprites+23

        lda     #>sprites
        sta     $4014

        jsr     rest_screen

        lda     #<wait_for_start
        sta     game_vec
        lda     #>wait_for_start
        sta     game_vec+1
        rti

set_score_attr:
        ldx     #6
-:      sta     sprites,y
        iny
        iny
        iny
        iny
        dex
        bne     -
        rts

game_over_data:
!8 $21,$0B
!text "GAME OVER",0
!8 $22,$09
!text "SCORE- ",0
!8 $23,$8A
!text "PRESS START",0
!8 $00

game_over_collision:
!8 $21,$8B
!text "COLLISION",0
!8 $00

game_over_fuel:
!8 $21,$8A
!text "OUT OF FUEL",0
!8 $00

; library routines

get_random_spriteloc:
        jsr     random_update
        sec
        lda     random_val+1
        sbc     #$F0
        bcs     get_random_spriteloc
        lda     random_val+1
        rts

get_random_64:
        jsr     random_update
        lda     random_val+2
        and     #$3F
        rts

get_random_8:
        jsr     random_update
        lda     random_val+2
        and     #$07
        rts

;--------------------------------------
; Utility functions

high_c:
        pha
        lda     #$01
        sta     $4015
        lda     #$00
        sta     $4001
        lda     #$86
        sta     $4000
        lda     #$69
        sta     $4002
        lda     #$08
        sta     $4003
        pla
        rts

crash_sound:
        pha
        lda     #$09
        sta     $4015
        lda     #$87
        sta     $4000
        sta     $400C
        lda     #$AA
        sta     $4002
        lda     #$A2
        sta     $4001
        lda     #$0E
        sta     $400E
        lda     #$09
        sta     $4003
        lda     #$08
        sta     $400F
        pla
        rts

empty_sound:
        pha
        lda     #$03
        sta     $4015
        lda     #$87
        sta     $4000
        lda     #$AA
        sta     $4002
        lda     #$F3
        sta     $4001
        lda     #$09
        sta     $4003
        pla
        rts
