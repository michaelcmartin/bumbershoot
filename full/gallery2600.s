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
        .alias  COLUBK  $0009
        .alias  CTRLPF  $000A
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
        .space  scratch 1
        .space  score   1
        .space  tens    2
        .space  ones    2
        .space  fire    1
        .space  hit     1

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
        lda     #$02            ; Unreflected playfield in scoring mode
        sta     CTRLPF
        lda     #$00            ; Black (invisible) left side
        sta     COLUP0
        lda     #$0c            ; Grey score on right side
        sta     COLUP1

        ;; Check fire button
        ldx     #$00
        bit     INPT4
        bmi     +
        dex
*       stx     fire

        ;; Move sprites as needed
        sta     HMCLR           ; Clear out any previous nudges
        lda     #$10            ; Targets move 1 left each frame
        sta     HMP1
        ldx     #$00            ; Set SWCHA to input mode for
        stx     SWACNT          ; joystick read
        lda     SWCHA           ; Then read joystick
        asl                     ; Top bit into carry
        bcs     +               ; Holding right?
        dex                     ; If so, nudge 1 right
*       asl
        bcs     +               ; Holding left?
        inx                     ; If so, nudge one left
*       txa                     ; Shift nudge amount into high nybble
        asl
        asl
        asl
        asl
        sta     HMP0            ; Apply to player
        sta     WSYNC
        sta     HMOVE           ; Apply all nudges

        ;; Match the missile's location to the player
        sta     WSYNC           ; Lock in player locations
        sta     HMCLR
        lda     #$02
        sta     RESMP0          ; Match missile to player
        sta     WSYNC
        lda     #$10            ; Match missile location to blaster's cannon
        sta     HMM0
        sta     HMOVE
        sta     RESMP0          ; Unlock missile

        ;; If we landed a hit last frame, update the score
        bit     hit
        bpl     +
        lda     #$00
        sta     hit
        sed
        clc
        lda     score
        adc     #1
        sta     score
        cld
*

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
        lda     #$ff
        sta     tens+1
        sta     ones+1

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

        ;; Prepare players for main display
        lda     #$1c                    ; Yellow missiles
        sta     COLUP0
        lda     #$46                    ; Red targets
        sta     COLUP1

        ;; 2 scanlines of white divider; prepare on final score line
        lda     #$0e
        sta     COLUBK
        sta     WSYNC                   ; Y is already zero, from before
        sta     WSYNC
        sty     COLUBK                  ; Divider done, back to black
        lda     fire                    ; Render missile as a "laser"
        sta     ENAM0

        ;; -- MAIN GAME DISPLAY: 126 scanlines --

        ;; 8 scanlines of space before targets
        ldy     #$08
*       sta     WSYNC
        dey
        bne     -

        ;; Clear collision registers before drawing the
        ;; targets
        sta     CXCLR

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

        ;; Record any collision
        lda     CXM0P
        sta     hit

        ;; Remaining 106 scanlines are all blank
        ldx     #$6a
*       sta     WSYNC
        dex
        bne     -

        ;; 7 doubled rows of blaster, below the "main game display"
        stx     ENAM0                   ; Disable missile
        lda     #$3a                    ; Orange Blaster
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
