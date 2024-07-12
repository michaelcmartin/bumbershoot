;;; --------------------------------------------------------------------------
;;; *  SHOOTING GALLERY for the Atari 2600
;;; *
;;; *  Bumbershoot Software, 2024. Available under the MIT license.
;;; --------------------------------------------------------------------------

        .outfile "gallery.bin"
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
        .alias  COLUBK  $0009
        .alias  PF0     $000D
        .alias  PF1     $000E
        .alias  PF2     $000F
        .alias  RESP0   $0010
        .alias  RESP1   $0011
        .alias  GRP0    $001B
        .alias  GRP1    $001C
        .alias  ENAM0   $001D
        .alias  ENAM1   $001E
        .alias  ENABL   $001F
        .alias  HMP0    $0020
        .alias  HMP1    $0021
        .alias  HMM0    $0022
        .alias  HMOVE   $002A
        .alias  HMCLR   $002B
        .alias  INTIM   $0284
        .alias  TIM64T  $0296

;;; --------------------------------------------------------------------------
;;; * VARIABLES
;;; --------------------------------------------------------------------------
        .data
        .org    $0080
        ;; No variables yet!

;;; --------------------------------------------------------------------------
;;; * PROGRAM TEXT
;;; --------------------------------------------------------------------------
        .text
        .org    $f800           ; 2KB cartridge image
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

        jsr     init_game

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

        lda     #$00
        sta     GRP0            ; Invisible Players
        sta     GRP1
        sta     ENAM0           ; Disable Missiles and Ball
        sta     ENAM1
        sta     ENABL
        sta     PF0             ; Empty Playfield
        sta     PF1
        sta     PF2
        sta     COLUBK          ; Black background
        sta     NUSIZ0          ; Blaster is a single normal-sized player
        lda     #$06
        sta     NUSIZ1          ; Targets are 3 copies, medium spacing
        lda     #$3a            ; Orange Blaster
        sta     COLUP0
        lda     #$46            ; Red targets
        sta     COLUP1

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

        ;; 30 scanlines for our eventual score display
        ldx     #$1e
*       sta     WSYNC
        dex
        bne     -
        ;; 2 scanlines of white divider; prepare on final score line
        lda     #$0e
        sta     COLUBK
        stx     WSYNC                   ; X is already zero, from before
        stx     WSYNC
        stx     COLUBK                  ; Divider done, back to black

        ;; -- MAIN GAME DISPLAY: 126 scanlines --

        ;; 8 scanlines of space before targets
        ldy     #$08
*       sta     WSYNC
        dey
        bne     -

        ;; 6 doubled rows of target graphics
        ldy     #$05
*       lda     gfx_target,y
        sta     GRP1
        sta     WSYNC
        dey
        sta     WSYNC
        bpl     -

        iny                             ; Disable P1 graphics
        sty     GRP1

        ;; Remaining 106 scanlines are all blank
        ldx     #$6a
*       sta     WSYNC
        dex
        bne     -

        ;; 7 doubled rows of blaster, below the "main game display"
        sta     COLUP0
        ldy     #$06
*       lda     gfx_blaster,y
        sta     GRP0
        sta     WSYNC
        dey
        sta     WSYNC
        bpl     -

        iny
        sty     GRP0                    ; Disable P0 graphics

        ;; 20 scanlines of ground
        lda     #$d4
        sta     COLUBK
        ldx     #$14
*       sta     WSYNC
        dex
        bne     -

        ;; Turn on VBLANK, do 30 lines of overscan
        lda     #$02
        sta     VBLANK
        ldx     #$1e
*       sta     WSYNC
        dex
        bne     -
        ;; Now back to the frame loop
        jmp frame

;;; --------------------------------------------------------------------------
;;; * SUPPORT ROUTINES
;;; --------------------------------------------------------------------------

        ;; init_game: place sprites in initial positions.
init_game:
        sta     WSYNC                   ;  0
        sta     HMCLR                   ;  3
        ldx     #$06                    ;  5
*       dex
        bne     -                       ; 34
        sta     RESP1                   ; 37
        lda     #$90                    ; 39
        ldy     #$40                    ; 41
        sta     RESP0
        sta     HMP0
        sty     HMP1
        sta     WSYNC
        sta     HMOVE
        rts

;;; --------------------------------------------------------------------------
;;; * Graphics data
;;; --------------------------------------------------------------------------

        .advance $ff00,$ff              ; Ensure page alignment
        ;; Blaster: 7 lines, color 3A
gfx_blaster:
        .byte   $92,$fe,$fe,$ba,$ba,$38,$10

gfx_target:
        ;; Target: 6 lines, color 46
        .byte   $3c,$42,$5a,$5a,$42,$3c

;;; --------------------------------------------------------------------------
;;; * INTERRUPT VECTORS
;;; --------------------------------------------------------------------------
        .advance $fffa,$ff
        .word   reset, reset, reset
