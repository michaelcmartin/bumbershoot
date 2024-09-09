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

        ;; Write/strobe addresses
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
        .alias  RESM0   $0012
        .alias  GRP0    $001B
        .alias  GRP1    $001C
        .alias  ENAM0   $001D
        .alias  ENAM1   $001E
        .alias  HMP0    $0020
        .alias  HMP1    $0021
        .alias  HMM0    $0022
        .alias  RESMP0  $0028
        .alias  HMOVE   $002A
        .alias  HMCLR   $002B
        .alias  CXCLR   $002C

        ;; Read addresses
        .alias  CXM0P   $0000
        .alias  INPT4   $000C

        ;; Peripheral addresses
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
        .space  scratch   1
        .space  score     1
        .space  tens      2
        .space  ones      2
        .space  target_y  1
        .space  blast_x   1
        .space  blast_y   1
        .space  new_fc    1
        .space  hit       2
        .space  blast_fc  1
        .space  p1_cache  1
        .space  m0_cache  1
        .space  lane      1
        .space  lanes_y  16
        .space  lanes_fc 16
        .space  top_fc    1             ; Also lanes_fc[16] sometimes
;;; --------------------------------------------------------------------------
;;; * PROGRAM TEXT
;;; --------------------------------------------------------------------------
        .text
        .org    $f800                   ; 2KB cartridge image
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

        ;; Zero out all graphics, sound registers, and latches
        ldx     #$04
        lda     #$00
*       sta     $00,x
        inx
        cpx     #$2d
        bne     -

        sta     SWACNT                  ; Joystick port is input-only

        jsr     init_game               ; Place sprites in initial positions,
                                        ; and reset game state in RAM

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

        ;; ========== FRAME UPDATE LOGIC ==========

        ;; Start of frame TIA register state
        lda     #$00
        sta     NUSIZ0                  ; Blaster has no mag/repl
        sta     COLUP0                  ; Left side of score is invisible
        sta     COLUBK                  ; Black background
        lda     #$06
        sta     NUSIZ1                  ; Targets are 3 copies, medium spacing
        lda     #$0c                    ; Right side of score is grey
        sta     COLUP1
        lda     #$02                    ; Unreflected playfield in scoring mode
        sta     CTRLPF

        ;; Move sprites as needed
        sta     HMCLR                   ; Clear out any previous nudges
        lda     #$10                    ; Targets move 1 left each frame
        sta     HMP1
        ldx     #$00                    ; Initial delta is zero
        ldy     blast_x                 ; Bounds-check
        lda     SWCHA                   ; Read joystick
        asl                             ; Top bit into carry
        bcs     +                       ; Holding right?
        cpy     #156                    ; Not already on right edge?
        beq     +
        dex                             ; If so, nudge 1 right
        iny
*       asl
        bcs     +                       ; Holding left?
        cpy     #11                     ; Not already on left edge?
        beq     +
        inx                             ; If so, nudge one left
        dey
*       sty     blast_x                 ; Store missile point
        ldy     target_y                ; Now check target height
        asl                             ; Holding down?
        bcs     +
        cpy     #4                      ; Not already at bottom of range?
        beq     +
        dey
*       asl                             ; Holding up?
        bcs     +
        cpy     #55                     ; Not already at top of range?
        beq     +
        iny
*       sty     target_y                ; Store target height
        txa                             ; Shift nudge amount into high nybble
        asl
        asl
        asl
        asl
        sta     HMP0                    ; Apply to player
        sta     WSYNC
        sta     HMOVE                   ; Apply all nudges

        ;; If we landed a hit last frame, update the score
        lda     hit
        ora     hit+1
        beq     score_done
        sed
        clc
        lda     score
        adc     #1
        sta     score
        cld
        ldx     #$00                    ; Find the lane that collided
*       lsr     hit+1
        ror     hit
        bcs     +
        inx
        bne     -
*       dex                             ; Find the first lane with that
        bmi     +                       ; missile in it
        lda     lanes_y,x
        cmp     #$40
        bmi     -
        inx                             ; Delete the missile from Y lanes
*       lda     #$80
        sta     lanes_y,x
        inx
        cpx     #16                     ; Ran off the top?
        beq     +
        lda     lanes_y,x               ; Gap lane?
        cmp     #$40
        bmi     -
*       lda     #$00                    ; Delete the missile from FC lanes
        sta     lanes_fc,x
score_done:

        ;; Compute new_fc from blast_x
        lda     blast_x
        clc
        adc     #$23
        sec
        ldx     #$00
*       inx
        sbc     #$0f
        bcs     -
        stx     new_fc
        eor     #$ff
        adc     #$f9
        asl
        asl
        asl
        asl
        ora     new_fc
        sta     new_fc

        ;; Advance missiles in flight
        ldy     lanes_y+15              ; Check top lane specially
        cpy     #64
        bpl     +
        iny
        sty     lanes_y+15
        cpy     #63                     ; Did we just scroll off the top?
        bmi     +
        ldy     #$80                    ; If so, clear shot
        sty     lanes_y+15
        ldy     #$00
        sty     lanes_fc+16
*       ldx     #14                     ; Count down through lanes
        lda     #60                     ; Checking against lane threshold
        sta     scratch
fly_lp: ldy     lanes_y,x
        cpy     #$40
        bpl     flynxt
        iny
        sty     lanes_y,x
        cpy     scratch                 ; Left the lane?
        bne     +
        lda     #$80
        sta     lanes_y,x
        bne     flynxt
*       tya                             ; Cache value
        iny                             ; Entering next lane?
        iny                             ; (adding 3 because next lane handles
        iny                             ;  our top scanline)
        cpy     scratch
        bne     flynxt
        sta     lanes_y+1,x             ; If so, forward Y...
        lda     lanes_fc+1,x            ; ... and push ahead the X code.
        sta     lanes_fc+2,x
        lda     #$00
        sta     lanes_fc+1,x
flynxt: sec                             ; Move threshold down a lane
        lda     scratch
        sbc     #4
        sta     scratch
        dex                             ; and move one lane down
        bpl     fly_lp

        ;; Create new missile if available and fire button pressed
        lda     lanes_fc+1              ; Have we recently fired a shot?
        ora     lanes_fc+2              ; If so, do nothing
        ora     lanes_fc+3
        bne     shot_done
        bit     INPT4                   ; Is the fire button pressed?
        bmi     shot_done               ; If not, do nothing
        lda     #$fe
        sta     lanes_y
        lda     new_fc
        sta     lanes_fc+1
shot_done:

        ;; Reset everything if reset is pressed
        lda     SWCHB
        lsr
        bcs     no_reset
        jsr     init_game
no_reset:

        ;; Convert the score variable into a pair of digit pointers
        lda     score
        and     #$f0
        lsr                             ; Clears carry
        lsr
        sta     tens
        lsr
        adc     tens                    ; Won't set carry
        adc     #<gfx_digits
        sta     tens
        lda     score
        and     #$0f
        asl
        sta     ones
        asl
        adc     ones                    ; Won't set carry
        adc     #<gfx_digits
        sta     ones
        lda     #>gfx_digits
        sta     tens+1
        sta     ones+1

        ;; Place the missile in the top lane, if any
        sta     HMCLR
        lda     top_fc
        beq     top_empty
        sta     HMM0
        and     #$0f
        sta     WSYNC
        sta     HMOVE
        tay
*       dey
        bne     -
        .checkpc [- & $ff00]+$ff        ; Make sure branch is only 3 cycles
        sta     RESM0
top_empty:
        sta     WSYNC
        sta     HMOVE

        ;; Wait for VBLANK to finish
*       lda     INTIM
        bne     -
        ;; We're on the final VBLANK line now. Wait for it to finish,
        ;; then turn it off. (.A is already zero from the branch.)
        sta     WSYNC
        sta     VBLANK

        ;; Clear out any stray nudge data
        sta     HMCLR

;;; --------------------------------------------------------------------------
;;; * DISPLAY KERNEL
;;; --------------------------------------------------------------------------

        ;; 30 scanlines for the score display: 6 quadrupled rows of
        ;; playfield blocks, bracketed by three blank lines
        sta     WSYNC
        sta     WSYNC
        ldy     #$05
score_loop:
        lda     (tens),y
        and     #$0f
        sta     scratch
        lda     (ones),y
        and     #$f0
        ora     scratch
        sta     WSYNC
        sta     PF2
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        dey
        bpl     score_loop
        sta     WSYNC                   ; Complete final line
        iny
        sty     PF2                     ; Disable playfield
        sta     WSYNC
        sta     WSYNC
        sta     WSYNC
        sta     HMOVE

        ;; 2 scanlines of white divider; prepare for first line of main
        ;; display while we do that
        lda     #$0e                    ; Divider is a white background
        sta     COLUBK
        lda     #$1c                    ; Yellow missiles
        sta     COLUP0
        lda     #$46                    ; Red targets
        sta     COLUP1
        sta     CXCLR                   ; Clear collision registers

        ;; Configure the lane counter
        ldx     #$0f
        stx     lane
        lda     lanes_y,x
        sta     blast_y
        lda     lanes_fc,x
        sta     blast_fc

        ;; Set up row counter for the main loop of 63 rows
        ldx     #$3e

        ;; Compute missile data for line 63
        txa
        sec
        sbc     blast_y
        cmp     #3
        rol
        asl
        eor     #$02
        sta     m0_cache

        ;; Compute sprite data for line 63 (nothing)
        ldy     #$00
        sty     p1_cache

        ;; Count out the two lines of the divider line
        sta     HMCLR
        sta     WSYNC
        sta     HMOVE
        sta     WSYNC
        sta     HMOVE

        ;; Turn the background color black again
        sty     COLUBK
        jmp     first_lane              ; Abbreviated first lane

        ;; -- MAIN GAME DISPLAY: 126 scanlines --

        ;; We're processing lines in groups of eight, so the
        ;; repeated logic is captured in this macro, to run at
        ;; the start of even scanlines.
.macro skipdraw
        lda     m0_cache
        sta     ENAM0                   ; Store this row's graphics
        lda     p1_cache
        sta     GRP1
        dex                             ; Compute next row's graphics
        txa
        ldy     #$00
        sec
        sbc     target_y
        cmp     #6                      ; Target_Height
        bcs     _1
        tay
        lda     gfx_target,y
        tay
_1:     sty     p1_cache
        txa
        sec
        sbc     blast_y
        cmp     #3
        rol
        asl
        eor     #$02
        sta     m0_cache
.macend

full_lane:
        `skipdraw
        sta     CXCLR                   ; clear collisions from prev lane
        sta     WSYNC                   ; count out our two rows
        sta     HMOVE
        sta     WSYNC
        sta     HMOVE
first_lane:
        `skipdraw
        sta     WSYNC                   ; count out our two rows
        sta     HMOVE
        sta     WSYNC
        sta     HMOVE
        `skipdraw
        lda     blast_fc
        beq     no_blast_reset
        sta     HMM0
        and     #$0f
        sta     WSYNC
        sta     HMOVE
        tay
*       dey
        bne     -
        .checkpc [- & $ff00]+$ff        ; Make sure branch is only 3 cycles
        sta     RESM0
blast_reset_done:
        sta     WSYNC
        sta     HMOVE
        `skipdraw
        sta     HMCLR
        sta     WSYNC                   ; count out our two rows
        sta     HMOVE
        lda     CXM0P
        asl
        rol     hit
        rol     hit+1
        dec     lane
        bmi     main_done
        stx     scratch
        ldx     lane
        lda     lanes_y,x
        sta     blast_y
        lda     lanes_fc,x
        sta     blast_fc
        ldx     scratch
        sta     WSYNC
        sta     HMOVE
        jmp     full_lane
no_blast_reset:
        sta     WSYNC
        sta     HMOVE
        beq     blast_reset_done
main_done:

blaster_kernel:
        ldx     #$00
        lda     #$3a                    ; Orange Blaster
        sta     WSYNC                   ; count out the final line
        sta     HMOVE
        stx     ENAM0                   ; Disable missile
        sta     COLUP0

        ;; 7 doubled rows of blaster, below the "main game display"
        ldy     #$06
*       lda     gfx_blaster,y
        sta     GRP0
        sta     WSYNC
        sta     HMOVE
        dey
        sta     WSYNC
        sta     HMOVE
        bpl     -

        iny
        sty     GRP0                    ; Disable P0 graphics

        ;; 20 scanlines of ground
        lda     #$d4
        sta     COLUBK
        ldx     #$14
*       sta     WSYNC
        sta     HMOVE
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
;;;
;;; All material past this point needs to guarantee that branches or
;;; indices never cross page boundaries! We accomplish this by forcing
;;; all of it into the final 256 bytes of the image.
;;; --------------------------------------------------------------------------

        .advance $ff00,$ff
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
        stx     score                   ; X is zero here
        stx     hit
        stx     hit+1
        sty     blast_y                 ; Start in no-shot space
        lda     #79                     ; Player was put at pixel 76,
        sta     blast_x                 ; So blast is 3 pixels to right
        lda     #53
        sta     target_y
        ldx     #$0f                    ; Clear missile data
        lda     #$80
        ldy     #$00
*       sta     lanes_y,x
        sty     lanes_fc,x
        dex
        bpl     -
        sty     lanes_fc+16
        rts

;;; --------------------------------------------------------------------------
;;; * Graphics data
;;; --------------------------------------------------------------------------

        ;; Blaster: 7 lines, color 3A
gfx_blaster:
        .byte   $92,$fe,$fe,$ba,$ba,$38,$10

gfx_target:
        ;; Target: 6 lines, color 46
        .byte   $3c,$42,$5a,$5a,$42,$3c

gfx_digits:
        .byte   $22,$55,$55,$55,$55,$22 ; 0
        .byte   $77,$22,$22,$22,$33,$22 ; 1
        .byte   $77,$11,$22,$44,$55,$22 ; 2
        .byte   $77,$44,$44,$66,$44,$77 ; 3
        .byte   $44,$44,$44,$77,$55,$55 ; 4
        .byte   $77,$55,$44,$77,$11,$77 ; 5
        .byte   $77,$55,$55,$77,$11,$77 ; 6
        .byte   $22,$22,$22,$44,$44,$77 ; 7
        .byte   $77,$55,$55,$77,$55,$77 ; 8
        .byte   $77,$55,$44,$77,$55,$77 ; 9

;;; --------------------------------------------------------------------------
;;; * INTERRUPT VECTORS
;;; --------------------------------------------------------------------------
        .advance $fffa,$ff
        .word   reset, reset, reset
