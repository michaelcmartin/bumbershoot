        .outfile "gallery.xex"
        .word   $ffff,start,end-1
        .org    $0700

        ;; OS memory locations and shadow registers
        .alias  RTCLOK  $12
        .alias  VDSLST  $0200
        .alias  SDMCTL  $022f
        .alias  SDLST   $0230
        .alias  GPRIOR  $026f
        .alias  STICK0  $0278
        .alias  STRIG0  $0284
        .alias  PCOLR0  $02c0
        .alias  PCOLR1  $02c1
        .alias  PCOLR2  $02c2
        .alias  PCOLR3  $02c3
        .alias  COLOR0  $02c4
        .alias  COLOR2  $02c6
        .alias  COLOR3  $02c7

        ;; Direct CTIA/GTIA registers
        .alias  HPOSP0  $d000
        .alias  HPOSP1  $d001
        .alias  HPOSP2  $d002
        .alias  HPOSP3  $d003
        .alias  HPOSM0  $d004
        .alias  M0PL    $d008
        .alias  GRACTL  $d01d
        .alias  HITCLR  $d01e

        ;; Direct ANTIC registers
        .alias  PMBASE  $d407
        .alias  NMIEN   $d40e

        .data
        .org    $0b00
        .space  player_x 1
        .space  target_x 3
        .space  target_y 1
        .space  lane     1
        .space  lane_x  20
        .space  lane_hit 1

        .text

start:  lda     #$00                    ; Clear graphics memory. Our custom
        tax                             ; playfield will lie in the unused
clrpm:  sta     $0b00,x                 ; portion in $0c00-$0d7f. Our ordinary
        sta     $0c00,x                 ; data will be in $0b00-$0bff, so also
        sta     $0d00,x                 ; clear that while we're here
        sta     $0e00,x
        sta     $0f00,x
        inx
        bne     clrpm

        ldx     #$00                    ; Load score header text into playfield
*       lda     score_msg,x
        beq     +
        sta     $0c08,x
        inx
        bne     -

*       jsr     reset_score

        ldx     #40                     ; Draw divider line
        lda     #$55
*       sta     $0c13,x
        dex
        bne     -

        ldx     #$00                    ; Copy display list to somewhere where
*       lda     dlist,x                 ; we won't have to worry about it
        sta     dlist_loc,x             ; crossing a page boundary and breaking
        inx
        cpx     #dlist_len
        bne     -

*       lda     #$0c                    ; Initialize P/M graphics pointer
        sta     PMBASE
        lda     #$00                    ; Disable playfield updates
        sta     SDMCTL                  ; Reassign display list
        lda     #<dlist_loc
        sta     SDLST
        lda     #>dlist_loc
        sta     SDLST+1
        lda     #17                     ; Initialize state for display list IRQ
        sta     lane
        lda     #$c0                    ; Enable display list IRQs
        sta     NMIEN
        lda     #<irq                   ; Initialize display list IRQ pointer
        sta     VDSLST
        lda     #>irq
        sta     VDSLST+1
        lda     #$2e                    ; Re-enable playfield and P/M graphics
        sta     SDMCTL

        lda     #$11                    ; 5 players over playfield
        sta     GPRIOR
        lda     #124                    ; X coordinates
        sta     HPOSP0
        sta     player_x
        sta     HPOSP2
        sta     target_x+1
        lda     #92
        sta     HPOSP1
        sta     target_x
        lda     #156
        sta     HPOSP3
        sta     target_x+2
        lda     #$03                    ; Enable players and missiles
        sta     GRACTL
        lda     #$3a                    ; Orange blaster
        sta     PCOLR0
        lda     #$46                    ; Red targets
        sta     PCOLR1
        sta     PCOLR2
        sta     PCOLR3
        lda     #$0c                    ; White text/divider
        sta     COLOR0
        lda     #$d4                    ; Green mode 0 BG
        sta     COLOR2
        lda     #$1c                    ; Yellow missiles
        sta     COLOR3

        ldx     #$06                    ; Draw blaster
*       lda     gfx_blaster,x
        sta     $0e00+93,x
        dex
        bpl     -
        lda     #38
        sta     target_y

loop:   lda     RTCLOK+2                ; Jiffy clock
*       cmp     RTCLOK+2                ; Wait for next jiffy
        beq     -

        lda     lane_hit
        beq     no_hit
        jsr     award_score             ; If hit, award point...
        lda     lane_hit                ; ...then find and erase the missile itself
        asl                             ; Start search at $d8e4-(lane_hit*4)
        asl
        eor     #$ff
        sec
        adc     #$e4
        tax
*       lda     $0d00,x                 ; Find first empty space before collision lane
        beq     +
        dex
        bne     -
*       lda     $0d00,x                 ; Find first nonzero missile pixel
        bne     +
        inx
        bne     -
*       lda     $0d00,x                 ; Zero out missile pixels until they're
        beq     +                       ; already zero
        lda     #$00
        sta     $0d00,x
        inx
        bne     -
*
no_hit: lda     #$00                    ; Clear collisions for next frame
        sta     lane_hit

        lda     STICK0
        ldx     player_x                ; Update player and target coordinates
        ldy     target_y                ; based on joystick directions
        lsr
        bcs     +
        dey
*       lsr
        bcs     +
        iny
*       lsr
        bcs     +
        dex
*       lsr
        bcs     +
        inx
*       cpx     #47                     ; Bounds-check new coordinates
        bne     +
        ldx     #48
*       cpx     #202
        bne     +
        ldx     #201
*       cpy     #25
        bne     +
        ldy     #26
*       cpy     #86
        bne     +
        ldy     #85
*       stx     player_x                ; Save new coordinates
        sty     target_y
        stx     HPOSP0
        ldx     #$02                    ; Move targets 1 pixel left
*       lda     target_x,x
        jsr     move_target
        sta     target_x,x
        sta     HPOSP1,x
        dex
        bpl     -
        ldx     #$00                    ; Redraw targets
        ldy     target_y
*       lda     gfx_target,x
        sta     $0e80,y
        sta     $0f00,y
        sta     $0f80,y
        iny
        inx
        cpx     #$08
        bne     -

        ;; Update missiles
        jsr     step_missiles
        lda     lane_x+3                ; Any shots in bottom few lanes?
        ora     lane_x+4
        ora     lane_x+5
        bne     shot_done               ; If so, don't check input
        lda     STRIG0
        bne     shot_done               ; If no button pressed, we're done
        lda     player_x                ; place missile at blaster port
        clc
        adc     #$03
        sta     lane_x+3                ; Record its location in the lane array
        lda     #$02                    ; And draw missile in place
        sta     $0d80+92
        sta     $0d80+93
        sta     $0d80+94
shot_done:
        ;; If no missile is present in rows 80-96, clear out any stray X coordinates in lanes 3-5.
        ldx     #16
        lda     #$00
*       ora     $0d80+80,x
        dex
        bpl     -
        cmp     #$00
        bne     +
        sta     lane_x+3
        sta     lane_x+4
        sta     lane_x+5
*       jmp     loop

reset_score:
        lda     #$10
        ldx     #$03
*       sta     $0c0f,x
        dex
        bpl     -
        sta     HITCLR
        rts

award_score:
        ldx     #$03
*       lda     $0c0f,x                 ; Load digit
        clc                             ; and increment it
        adc     #$01
        cmp     #$1a                    ; Need to carry?
        bne     +                       ; If not, store value and done
        lda     #$10                    ; Otherwise, write a zero...
        sta     $0c0f,x
        dex                             ; move one digit back...
        bpl     -                       ; ... and increment that if it's there
        rts                             ; just quit if we wrapped 9999 though
*       sta     $0c0f,x
        rts

move_target:
        sec
        sbc     #$01
        cmp     #39
        bne     +
        lda     #207
*       rts

.scope
step_missiles:
        ldy     #26
        ldx     #18
        bne     _first_lane
_full_lane:
        lda     $0d81,y
        sta     $0d80,y
        iny
_first_lane:
        lda     $0d81,y
        sta     $0d80,y
        iny
        lda     $0d81,y
        sta     $0d80,y
        iny
        ;; Last line: advance X coordinate if a new missile arrives
        lda     $0d80,y
        bne     _simple_lane
        lda     $0d81,y
        beq     _simple_lane
        lda     lane_x,x
        sta     lane_x+1,x
        lda     #$00
        sta     lane_x,x
_simple_lane:
        lda     $0d81,y
        sta     $0d80,y
_finish_lane:
        iny
        dex
        bpl     _full_lane
        rts
.scend

.scope
irq:    pha
        txa
        pha
        ldx     lane
        lda     M0PL                    ; Check missile/player collisions
        and     #$0e                    ; Mask to only target hits
        beq     +
        txa
        clc
        adc     #$03
        sta     lane_hit
*       dex
        bmi     _lanes_end
        lda     lane_x+3,x
        beq     _end
        sta     HPOSM0
_end:   sta     HITCLR
        stx     lane
        pla
        tax
        pla
        rti
_lanes_end:
        ldx     #17
        bne     _end
.scend

score_msg:
        .byte   $33,$23,$2f,$32,$25,$1a,$00

gfx_blaster:
        .byte   $10,$38,$ba,$ba,$fe,$fe,$92
gfx_target:
        .byte   $00,$3c,$42,$5a,$5a,$42,$3c,$00

dlist:  .byte   $70,$70,$70             ; 24 blank lines
        .byte   $47,$00,$0c             ; One line GR 2 at $0c00
        .byte   $90,$0d                 ; 2 blank and 1 big pixel for divider
        .byte   $d0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
        .byte   $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0 ; Main playfield
        .byte   $60,$60                 ; Space for blaster
        .byte   $02,$02,$02             ; Ground
        .byte   $41                     ; End of list
        .word   dlist_loc               ; Display list backpointer

        ;; Place the display list just before the playfield graphics at
        ;; $0C00. This will put it at a point where it ends at $0BFF, giving
        ;; us as much space for our data segment as we can while not increasing
        ;; total contiguous memory footprint or imposing alignment requirements
        ;; on the in-program display list.
        .alias  dlist_len ^-dlist
        .alias  dlist_loc $0c00-dlist_len

        ;; Make sure our program text doesn't overrun our data segment
        .checkpc $0b00

        ;; Make sure our data segment doesn't overrun where we put the
        ;; display list
        .data
        .checkpc dlist_loc

        .text

end:    .word   $02e0,$02e1,start
