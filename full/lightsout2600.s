;;; --------------------------------------------------------------------------
;;; *  LIGHTS OUT for the Atari 2600
;;; *
;;; *  Bumbershoot Software, 2018.
;;; --------------------------------------------------------------------------

        .outfile "LightsOut.bin"
;;; --------------------------------------------------------------------------
;;; * SYMBOLIC NAMES FOR REGISTERS
;;; * Taken from the Stella Programmer's Guide
;;; --------------------------------------------------------------------------

        .alias  VSYNC   $0000
        .alias  VBLANK  $0001
        .alias  WSYNC   $0002
        .alias  NUSIZ0  $0004
        .alias  NUSIZ1  $0005
        .alias  COLUP0  $0006
        .alias  COLUP1  $0007
        .alias  COLUPF  $0008
        .alias  COLUBK  $0009
        .alias  CTRLPF  $000A
        .alias  INPT4   $000C
        .alias  PF0     $000D
        .alias  PF1     $000E
        .alias  PF2     $000F
        .alias  RESP0   $0010
        .alias  RESP1   $0011
        .alias  RESBL   $0014
        .alias  GRP0    $001B
        .alias  GRP1    $001C
        .alias  ENAM0   $001D
        .alias  ENAM1   $001E
        .alias  ENABL   $001F
        .alias  HMBL    $0024
        .alias  HMOVE   $002A
        .alias  HMCLR   $002B
        .alias  SWCHA   $0280
        .alias  SWACNT  $0281
        .alias  SWCHB   $0282
        .alias  INTIM   $0284
        .alias  TIM64T  $0296

;;; --------------------------------------------------------------------------
;;; * VARIABLES
;;; --------------------------------------------------------------------------
        .data
        .org    $0080
        .space  crsr_x  1       ; Cursor X location (0-4, 0=left)
        .space  crsr_y  1       ; Cursor Y location (0-4, 0=bottom)
        .space  scrtch1 1       ; Spare byte to make moves simpler
        .space  grid    5       ; Grid data, one per row
        .space  scrtch2 1       ; Spare byte to make moves simpler
        .space  lastjoy 1       ; Previous joystick data
        .space  lastrig 1       ; Previous trigger data
        .space  joytime 1       ; Frames until next move possible

        .text
        .org    $F800           ; 2KB cartridge image
;;; --------------------------------------------------------------------------
;;; * DATA TABLES
;;; --------------------------------------------------------------------------
        ;; We want to ensure that all our table accesses never cross a page
        ;; boundary, and the easiest way to ensure that is to stuff it all
        ;; right at the start.

        ;; Location data for the cursor. Our target pixels are, in order,
        ;; 54,66,78,90,102.
coarse_loc:
        .byte   $06,$06,$07,$08,$09
fine_loc:
        .byte   $40,$80,$B0,$E0,$10

grid_decode:
        .byte   $00,$03,$18,$1B,$C0,$C3,$D8,$DB

move_edge:
        .byte   $10,$08,$04,$02,$01
move_center:
        .byte   $18,$1C,$0E,$07,$03

        ;; Enforce that we haven't crossed our page boundary.
        .checkpc $F900

;;; --------------------------------------------------------------------------
;;; * PROGRAM TEXT
;;; --------------------------------------------------------------------------
        ;; RESET vector.
reset:
        sei
        cld
        ;; Zero out registers.
        ldx     #$00
        txa
        tay
        ;; Cycle through all possible stack pointers and push zeroes
        ;; into it to clear out all of RAM. Does 2x as much work as
        ;; needed, but the loop is smaller this way. This particular
        ;; trick was taken from an old "macro.h" file for DASM that
        ;; had this routine credited to one "Andrew Davie."
*       dex
        txs
        pha
        bne     -
        ;; The "bne" is testing the value of .X. When it's zero again,
        ;; that will mean all our registers are zero again, and
        ;; furthermore, we pushed a 0 into $100 (which is $80) which
        ;; wrapped around the stack pointer to $FF, which is just
        ;; where we want it.

        ;; Initial setup code
        ;; Center cursor
        lda     #$02
        sta     crsr_x
        sta     crsr_y
        ;; Seed RNG with .A=1, .X=0
        lsr
        jsr     srnd

;;; --------------------------------------------------------------------------
;;; * MAIN FRAME LOOP
;;; --------------------------------------------------------------------------
frame:
        ;; 3 lines of VSYNC
        lda     #$02
        sta     WSYNC
        sta     VSYNC
        sta     WSYNC
        sta     WSYNC
        lsr
        sta     WSYNC
        sta     VSYNC

        ;; Set timer for the remaining VBLANK period (37 lines).
        ;; 37 lines * 76 cycles/line = 2,812 cycles
        ;; $2B ticks * $40 cycles/tick = 2,752 cycles
        lda     #$2b
        sta     TIM64T

        ;; Our actual frame-update logic
        ;; Start by generating 32 bits of randomness
        jsr     rnd
        lda     rndval
        sta     rndval+2
        lda     rndval+1
        sta     rndval+3
        jsr     rnd

        lda     #$00            ; Black background
        sta     COLUBK
        lda     #$0E            ; White playfield
        sta     COLUPF
        lda     #$15            ; High Priority mirrored playfield, 2px Ball
        sta     CTRLPF
        lda     #$00
        sta     GRP0            ; Players start blank
        sta     GRP1
        sta     ENAM0           ; Disable Missiles
        sta     ENAM1           ; (TODO: GRP0-ENABL are contiguous)
        sta     ENABL

        sta     PF0             ; Invisible Playfield
        sta     PF1
        sta     PF2

        ;; Place the players. Take the cycle X that STA RESPn begins
        ;; after STA WSYNC ends, and the player is at pixel
        ;;    3*X - 53  (minimum 1)
        ;; Our target pixels are 52 and 76, so, we can place them perfectly
        ;; if we strobe the reset-player registers on cycles 35 and 43.
        sta     WSYNC
        ;; Quad-size players
        lda     #$07            ; +2 (2)
        sta     NUSIZ0          ; +3 (5)
        sta     NUSIZ1          ; +3 (8)
        ;; That are a warm red
        lda     #$42            ; +2 (10)
        sta     COLUP0          ; +3 (13)
        sta     COLUP1          ; +3 (16)

        ldx     #$03            ; +2     (18)
*       dex                     ; +2*3   (24)
        bne     -               ; +3*2+2 (32)

        cpx     $80             ; +3 (35)
        sta     RESP0           ; +3 (38)
        nop                     ; +2 (40)
        cpx     $80             ; +3 (43)
        sta     RESP1

        ;; Now place the ball. Take the cycle X that STA RESBL begins after
        ;; STA WSYNC ends, and the ball is at pixel
        ;;   3*X - 55 (minimum 0)
        ;; Our target pixels are defined by the values in the coarse and
        ;; fine placement tables.
        sta     WSYNC
        ldy     crsr_x          ; +3 (3)
        lda     coarse_loc, y   ; +4 (7)
        tax                     ; +2 (9)
*       dex                     ; +5N-1
        bne     -               ; So X=5N+8 for coarse placement
        sta     RESBL           ; for a pixel location of 15N-31
        lda     fine_loc, y
        sta     HMCLR
        sta     HMBL
        sta     WSYNC
        sta     HMOVE
        ;; In order for the timing on the player and ball placement to be
        ;; correct, we need the backbranches to not have crossed any
        ;; page boundaries. We need to make sure we're still in $F8xx land.
        .checkpc $F900

        ;; If RESET is pressed, randomize the board
        lda     SWCHB
        lsr
        bcs     +
        jsr     randomize_board
        jmp     vblank_end

        ;; Otherwise execute a gameplay frame.
*       jsr     game_frame

        ;; Wait for VBLANK to finish
vblank_end:
        lda     INTIM
        bne     vblank_end
        ;; We're on the final VBLANK line now. Wait for it to finish,
        ;; then turn it off. (.A is already zero from the branch.)
        sta     WSYNC
        sta     VBLANK

;;; --------------------------------------------------------------------------
;;; * DISPLAY KERNEL
;;; --------------------------------------------------------------------------

        ;; 192 lines of main display
        ldy     #$20
*       sta     WSYNC
        dey
        bne     -

        ldy     #$08
        lda     #$ff
*       sta     WSYNC
        sta     PF2
        dey
        bne     -

        ldx     #$04
grid_loop:
        ;; Decode and store player graphics
        lda     grid,x
        lsr
        lsr
        tay
        lda     grid_decode,y
        sta     GRP0
        lda     grid,x
        and     #$03
        tay
        lda     grid_decode,y
        sta     GRP1
        lda     #$49
        sta     WSYNC
        sta     PF2

        cpx     crsr_y
        beq     draw_cursor
        ;; No cursor in this row
        ldy     #$0F
*       sta     WSYNC
        dey
        bne     -
        beq     next_solid

draw_cursor:
        lda     #$02
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        sta     ENABL
        sta     WSYNC
        sta     HMCLR
        lda     #$10
        sta     HMBL
        sta     WSYNC
        sta     HMOVE
        lda     #$25            ; High Priority mirrored playfield, 2px Ball
        sta     CTRLPF
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        sta     HMCLR
        lda     #$F0
        sta     HMBL
        sta     WSYNC
        sta     HMOVE
        lda     #$15            ; High Priority mirrored playfield, 4px Ball
        sta     CTRLPF
        sta     WSYNC
        sta     WSYNC
        lda     #$00
        sta     ENABL
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC

next_solid:
        ldy     #$08
        lda     #$ff
*       sta     WSYNC
        sta     PF2
        dey
        bne     -

        dex
        bpl     grid_loop

        lda     #$00
        sta     WSYNC
        sta     GRP0
        sta     GRP1
        sta     PF2

        ldy     #$1F
*       sta     WSYNC
        dey
        bne     -

        ;; Turn on VBLANK, do 30 lines of overscan
        lda     #$02
        sta     VBLANK
        ldy     #$1e
*       sta     WSYNC
        dey
        bne     -
        ;; Now back to the frame loop
        jmp frame

;;; --------------------------------------------------------------------------
;;; * SUPPORT ROUTINES
;;; --------------------------------------------------------------------------

        ;; Makes a move at (crsr_x, crsr_y).
make_move:
        ldx     crsr_y
        ldy     crsr_x
        lda     move_edge,y
        eor     grid-1,x
        sta     grid-1,x
        lda     move_edge,y
        eor     grid+1,x
        sta     grid+1,x
        lda     move_center,y
        eor     grid,x
        sta     grid,x
        rts

        .include "../asm/xorshift.s"
        ;; We need four bytes for rndval here. We are relying on the fact
        ;; that rndval is the last thing xorshift defines in its data
        ;; segment, so rnd2 will be allocated right next to it.
        .data
        .space  rnd2    2
        .text

.scope
        .data
        .space  _index  1
        .space  _count  1
        .space  _curr   1
        .text

randomize_board:
        ldx     #$01
        stx     _count
        dex
        stx     _index
        lda     #$04
        sta     crsr_y
_row:   lda     #$04
        sta     crsr_x
_cell:  dec     _count
        bne     +
        ;; Out of bits, reset counter, load next rndval
        ldx     _index
        lda     rndval,x
        sta     _curr
        lda     #$08
        sta     _count
        inc     _index
*       lsr     _curr
        bcc     +
        jsr     make_move
*       dec     crsr_x
        bpl     _cell
        dec     crsr_y
        bpl     _row
        ;; Reset cursor on the way out
        lda     #$02
        sta     crsr_x
        sta     crsr_y
        rts
.scend

game_frame:
        bit     lastrig
        bpl     +
        bit     INPT4
        bmi     +
        jsr     make_move
*       lda     INPT4
        sta     lastrig
        lda     #$00            ; Force SWCHA to all input
        sta     SWACNT
        tax                     ; null out .X and .Y so we can use
        tay                     ; them to represent dx/dy
        lda     SWCHA
        and     #$F0            ; Only care about P0
        cmp     lastjoy
        sta     lastjoy
        beq     +
        stx     joytime         ; If joystick moved, react immediately
*       lda     joytime
        beq     +
        dec     joytime
        jmp     game_frame_end
*       lda     lastjoy
        asl                     ; right bit in carry
        bcs     +
        inx
*       asl                     ; left bit in carry
        bcs     +
        dex
*       asl                     ; down bit in carry
        bcs     +
        dey
*       asl                     ; up bit in carry
        bcs     +
        iny
*       txa                     ; crsr_x += dx
        clc
        adc     crsr_x
        ;; Bounds-check and wrap around if needed
        bpl     +
        lda     #$04
*       cmp     #$05
        bcc     +
        lda     #$00
*       sta     crsr_x
        tya                     ; crsr_y += dy
        clc
        adc     crsr_y
        ;; Bounds-check and wrap around if needed
        bpl     +
        lda     #$04
*       cmp     #$05
        bcc     +
        lda     #$00
*       sta     crsr_y
        ;; Finally, set a delay for autorepeat
        lda     #$10
        sta     joytime
game_frame_end:
        rts

;;; --------------------------------------------------------------------------
;;; * INTERRUPT VECTORS
;;; --------------------------------------------------------------------------
        .advance $FFFA,$ff
        .word   reset, reset, reset
