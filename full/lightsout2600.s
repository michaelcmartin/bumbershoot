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
        .alias  INTIM   $0284
        .alias  TIM64T  $0296

;;; --------------------------------------------------------------------------
;;; * VARIABLES
;;; --------------------------------------------------------------------------
        .data
        .org    $0080
        .space  crsr_x  1       ; Cursor X location (0-4, 0=left)
        .space  crsr_y  1       ; Cursor Y location (0-4, 0=bottom)
        .space  grid    5       ; Grid data, one per row

;;; --------------------------------------------------------------------------
;;; * PROGRAM TEXT
;;; --------------------------------------------------------------------------
        .text
        .org    $F800           ; 2KB cartridge image
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

        lda     #$02
        sta     crsr_x
        sta     crsr_y
        ldx     #$04
*       lda     grid_init,x
        sta     grid,x
        dex
        bpl     -

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

        lda     #$00            ; Black background
        sta     COLUBK
        lda     #$0E            ; White playfield
        sta     COLUPF
        lda     #$25            ; High Priority mirrored playfield, 4px Ball
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

        ;; Wait for VBLANK to finish
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
        ldy     #$08
*       sta     WSYNC
        dey
        bne     -
        sty     ENABL
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

        ;; None yet!

;;; --------------------------------------------------------------------------
;;; * DATA TABLES
;;; --------------------------------------------------------------------------
        ;; We want to ensure that all our table accesses never cross a page
        ;; boundary, and the easiest way to ensure that is to stuff it all
        ;; into the last page.
        .advance $ff00

        ;; Location data for the cursor. Our target pixels are, in order,
        ;; 54,66,78,90,102.
coarse_loc:
        .byte   $06,$06,$07,$08,$09
fine_loc:
        .byte   $50,$90,$C0,$F0,$20

grid_decode:
        .byte   $00,$03,$18,$1B,$C0,$C3,$D8,$DB
grid_init:
        .byte   $1B,$15,$0E,$15,$1B
;;; --------------------------------------------------------------------------
;;; * INTERRUPT VECTORS
;;; --------------------------------------------------------------------------
        .advance $FFFA
        .word   reset, reset, reset
