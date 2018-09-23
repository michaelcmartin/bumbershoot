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
        .alias  AUDC0   $0015
        .alias  AUDF0   $0017
        .alias  AUDV0   $0019
        .alias  GRP0    $001B
        .alias  GRP1    $001C
        .alias  ENAM0   $001D
        .alias  ENAM1   $001E
        .alias  ENABL   $001F
        .alias  HMP0    $0020
        .alias  HMP1    $0021
        .alias  HMBL    $0024
        .alias  VDELP0  $0025
        .alias  VDELP1  $0026
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
        .space  idle    1       ; Zero if not in the screensaver mode
        .space  idletim 1       ; Idle timer. Pick a new color when zero.
        .space  idlemsk 1       ; Mask value to randomize colors.
        .space  sndtype 1       ; SFX ID
        .space  sndaux  1

;;; --------------------------------------------------------------------------
;;; * MACROS
;;; --------------------------------------------------------------------------
        ;; Trap if some timing-critical section of code crosses a page
        ;; boundary. More precisely, asserts that the PC is either less than
        ;; or just passed the page boundary past its argument. (If it's just
        ;; past, then the _next_ byte is the one that will be out of bounds.)
.macro  page_check
        .checkpc [_1 & $FF00]+$100
.macend
        .text
        .org    $F800           ; 2KB cartridge image
        .advance $FC00,$FF      ; Only using 1KB of it
rom_start:
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

logo_0: .byte   $00,$00,$00,$00,$03,$02,$02,$02,$02,$02,$02,$02
logo_1: .byte   $0e,$0a,$02,$02,$ae,$2a,$2a,$2a,$2e,$00,$20,$00
logo_2: .byte   $00,$00,$00,$00,$ab,$a8,$ab,$aa,$eb,$88,$9c,$88
logo_3: .byte   $00,$00,$00,$00,$83,$82,$82,$02,$82,$02,$02,$03
logo_4: .byte   $00,$00,$00,$00,$ba,$aa,$aa,$aa,$aa,$82,$87,$82
logo_5: .byte   $00,$00,$00,$00,$40,$00,$40,$40,$40,$40,$40,$40

        ;; Enforce that we haven't crossed our page boundary.
        `page_check rom_start

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
        ;; Start in idle mode
        sta     idle
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
        eor     idlemsk
        sta     COLUBK
        lda     #$0E            ; White playfield
        eor     idlemsk
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

        ;; Place the title. Take the cycle X that STA RESPn begins after
        ;; STA WSYNC ends, and the player is at pixel
        ;;   3*X - 54 (minimum 0)
        ;; Our target pixels are 56 and 64, which means cycles 37 and 40 will
        ;; get us as close as we can reasonably get. However, if we drop to
        ;; cycle 34 instead we can save a few bytes and just sneak into the
        ;; HMOVE limits.
        sta     WSYNC
        lda     #$03            ; +2 (2)
        sta     NUSIZ0          ; +3 (5)  Three copies close for P0 and P1
        sta     NUSIZ1          ; +3 (8)
        lda     #$1e            ; +2 (10)
        eor     idlemsk         ; +3 (13)
        sta     COLUP0          ; +3 (16)
        sta     COLUP1          ; +3 (19)
        sta     HMCLR           ; +3 (22)
        lda     #$80            ; +2 (24)
        sta     HMP0            ; +3 (27)
        lda     #$90            ; +2 (29)
        sta     HMP1            ; +3 (32)
        nop                     ; +2 (34)
        sta     RESP0           ; +3 (37)
        sta     RESP1

        ;; Place the ball. Take the cycle X that STA RESBL begins after
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
        `page_check -           ; (keep that loop on one page)
        lda     fine_loc, y
        sta     HMBL
        sta     WSYNC
        sta     HMOVE

        ;; If RESET is pressed, randomize the board
        lda     SWCHB
        lsr
        bcs     +
        jsr     randomize_board
        lda     #$00
        sta     idlemsk
        sta     idle
        jmp     vblank_end

        ;; Otherwise if we're idle count down and pick a new mask if needed.
*       lda     idle
        beq     +
        lda     #$06            ; Hide cursor
        sta     crsr_y
        dec     idletim
        bne     vblank_end
        lda     rndval
        sta     idlemsk
        jmp     vblank_end

        ;; Otherwise execute a gameplay frame.
*       jsr     game_frame

        ;; Wait for VBLANK to finish
vblank_end:
        jsr     sound_update
*       lda     INTIM
        bne     -
        ;; We're on the final VBLANK line now. Wait for it to finish,
        ;; then turn it off. (.A is already zero from the branch.)
        sta     WSYNC
        sta     VBLANK

;;; --------------------------------------------------------------------------
;;; * DISPLAY KERNEL
;;; --------------------------------------------------------------------------

        ;; 192 lines of main display
        ldy     #$0d
*       sta     WSYNC
        dey
        bne     -

        lda     #$01
        sta     VDELP0
        sta     VDELP1
        ldy     #$0b
        sty     scrtch1
*       ldy     scrtch1         ; +3 (65)
        lda     logo_0,y        ; +4 (69)
        sta     WSYNC           ; +3 (72->0)
        sta     GRP0            ; +3 (3)
        lda     logo_1,y        ; +4 (7)
        sta     GRP1            ; +3 (10)
        lda     logo_2,y        ; +4 (14)
        sta     GRP0            ; +3 (17)
        lda     logo_3,y        ; +4 (21)
        sta     scrtch2         ; +3 (24)
        lda     logo_4,y        ; +4 (28)
        tax                     ; +2 (30)
        lda     logo_5,y        ; +4 (34)
        ldy     scrtch2         ; +3 (37)
        nop                     ; +2 (39)
        cpx     $80             ; +3 (42)
        sty     GRP1            ; +3 (45)
        stx     GRP0            ; +3 (48)
        sta     GRP1            ; +3 (51)
        sta     GRP0            ; +3 (54)
        dec     scrtch1         ; +5 (59)
        bpl     -               ; +3 (62)

        lda     #$00            ; +2 (63)
        sta     GRP0            ; +3 (66)
        sta     GRP1            ; +3 (69)
        sta     VDELP0          ; +3 (72)
        sta     VDELP1          ; +3 (75)

        ldy     #$0c            ; +2 (77->1) -> one fewer WSYNC required here
*       sta     WSYNC
        dey
        bne     -

        lda     #$ff
        sta     WSYNC
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
        ;; That loop isn't allowed to cross a page boundary.
        `page_check -

        cpx     $80             ; +3 (35)
        sta     RESP0           ; +3 (38)
        nop                     ; +2 (40)
        cpx     $80             ; +3 (43)
        sta     RESP1

        ldy     #$06
*       sta     WSYNC
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

        ldy     #$19
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
        lda     #$06
        sta     crsr_y
        rts
.scend

game_frame:
        lda     crsr_y          ; If cursor is offscreen, center it
        cmp     #$05
        bcc     +
        lda     #$02
        sta     crsr_y
        sta     crsr_x
*       bit     lastrig
        bpl     +
        bit     INPT4
        bmi     +
        jsr     make_move
        jsr     make_ding
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
        ;; Check for victory on the way out
        ldx     #$04
*       lda     grid, x
        bne     +
        dex
        bpl     -
        ;; We won! Back to the idle state.
        lda     #$01
        sta     idle
        sta     idletim
        jsr     make_whoop
*       rts

make_ding:
        ldx     crsr_y
        lda     grid,x
        ldx     crsr_x
        and     move_edge,x
        beq     low_ding
        ;; Otherwise, high ding
        lda     #$0a
        bne     +
low_ding:
        lda     #$14
*       ldx     #$00
        stx     AUDV0
        sta     AUDF0
        lda     #$0c
        sta     AUDC0
        lda     #$01
        sta     sndtype
        lda     #$14
        sta     sndaux
        rts

make_whoop:
        lda     #$00
        sta     AUDV0
        sta     AUDF0
        lda     #$0F
        sta     AUDC0
        lda     #$02
        sta     sndtype
        lda     #$60
        sta     sndaux
        rts

sound_update:
        ldx     sndtype
        beq     no_sound
        dex
        beq     ding_update
        dex
        beq     whoop_update
no_sound:
        rts

ding_update:
        ldx     sndaux
        dex
        stx     sndaux
        bne     +
        stx     sndtype
*       txa
        lsr
        sta     AUDV0
        rts

whoop_update:
        ldx     sndaux
        dex
        dex
        stx     sndaux
        bne     +
        stx     sndtype
        stx     AUDV0
        rts
*       txa
        and     #$1F
        sta     AUDF0
        lda     #$0c
        sta     AUDV0
        lda     #$01
        sta     idletim
        rts

;;; --------------------------------------------------------------------------
;;; * INTERRUPT VECTORS
;;; --------------------------------------------------------------------------
        .advance $FFFA,$ff
        .word   reset, reset, reset
