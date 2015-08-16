;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BADLINE EXPERIMENT
;;;
;;; This is a fuller version of the "Color Clock Experiment" programs
;;; presented in the blog. It lets you modify horizontal timing, as
;;; well as the line the colorshift happens on, and it also allows you
;;; to modify the vertical scroll, thus changing which lines are bad
;;; lines.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        ;; PRG header
        .word   $0801
        .org    $0801
        .outfile "badline.prg"

        ;; BASIC prologue
.scope
        .word   _next, 2014     ; Next line and current line number
        .byte   $9e," 2062",0   ; SYS 2062
_next:  .word   0               ; End of program
.scend
        ;; We want our IRQ routine to be in page 8, so we do it first,
        ;; which means we have to jump past it
        jmp     main

        ;; Useful KERNAL routines
        .alias  chrout  $ffd2
        .alias  getin   $ffe4
        .alias  stop    $ffe1

        ;; Useful BASIC ROM routines
        .alias  load_16         $b391   ; .YA to FAC1
        .alias  fac1_to_string  $bddd   ; FAC1 to string at $0100

        ;; Handy character codes that aren't in ASCII
        .alias  white             5
        .alias  lower_case       14
        .alias  home             19
        .alias  f1              133
        .alias  f3              134
        .alias  f5              135
        .alias  f7              136
        .alias  upper_case      142
        .alias  black           144
        .alias  cls             147
        .alias  light_blue      154
        .alias  t               175 ; "top"    - CMD-P
        .alias  b               183 ; "bottom" - CMD-Y

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RASTER INTERRUPT ROUTINE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.scope
        ;; This batch of instructions lets us tune our IRQ delay by
        ;; altering the start of the routing by one byte per cycle.
irq:    cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c9
        cmp     #$c5
        nop
        .checkpc $0900          ; All those need to be on the same page
        inc     $d021           ; Change background color
        lda     #$01            ; Acknowledge interrupt
        sta     $d019
        ldx     $d012           ; Are we mid-screen?
        bmi     _done           ; If so, that's it (target raster is 1)
        lda     #$0f            ; Otherwise, reset background color for top
        sta     $d021
        lda     #$18            ; And set YSCROLL while keeping display
        ora     yscroll         ; enabled and 25 lines displayed
        sta     $d011
        .alias  targetraster     ^+1
        lda     #$92            ; "targetraster" points to this argument!
_done:  sta     $d012           ; Set target raster for next IRQ
        lda     $dc0d           ; Timer IRQ waiting?
        beq     +               ; If not, done
        jmp     $ea31           ; If so, process it
*       jmp     $febc
.scend

.macro  print_string
        lda     #<_1
        ldx     #>_1
        jsr     strout
.macend

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN PROGRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main:   lda     #36             ; Initialize variables
        sta     delay
        lda     #146
        sta     targetraster
        lda     #3
        sta     yscroll
        lda     #0              ; Clear the VIC-II 'idle graphics'
        sta     $3fff
        ;; Introduce ourselves
        `print_string explanation
        `print_string explanation_1
        `print_string explanation_2
        ;; Wait for a key
*       jsr     getin
        beq     -
        ;; Draw the main screen
        `print_string title
        lda     #$04            ; Four copies of the filer
        sta     $fd
*       `print_string filler
        dec     $fd
        bne     -
        `print_string instructions
        ;; Set up IRQs
        sei
        lda     #$7f            ; Disable CIA timer
        sta     $dc0d
        lda     #<[irq+36]      ; Set IRQ to initial location
        sta     $0314           ; All IRQ targets are on page 8 so we
        lda     #>irq           ; can reassign atomically later
        sta     $0315
        lda     #$00            ; Default to a black background
        sta     $d021
        lda     #$1b            ; Set up raster and Y scroll
        sta     $d011
        lda     #$01
        sta     $d012
        sta     $d01a           ; Enable raster IRQ
        cli

mainloop:
        ;; Set the IRQ delay
        clc
        lda     #<irq
        adc     delay
        sta     $0314
        ;; The target raster gets reset just by changing
        ;; its value, so we have nothing to load up there
        ;; The yscroll is changed in the interrupt during VBLANK.

        ;; Tell the user about the current status
        `print_string stat_0
        lda     delay           ; If we're 49 cycles displaced...
        cmp     #49
        bne     +
        lda     #$06            ; The delay is 6 cycles.
        bne     ++
*       sec
        lda     #56             ; Otherwise it's (56-displace) cycles.
        sbc     delay
*       jsr     numout
        `print_string stat_1    ; State target raster
        lda     targetraster
        jsr     numout
        `print_string stat_2    ; State which badline it interferes with
        lda     targetraster
        and     #$07
        jsr     numout
        `print_string stat_3
        lda     yscroll         ; State scroll status
        jsr     numout
        `print_string stat_4

keyloop:
        jsr     getin
        cmp     #$2d            ; -
        bne     _notminus
        ;; User hit the - key: Increment IRQ offset if able (<49)
        lda     delay
        cmp     #49
        beq     +
        inc     delay
*       jmp     mainloop
_notminus:
        cmp     #$2b            ; +
        bne     _notplus
        ;; User hit the + key: Decrement IRQ offset if able (>0)
        lda     delay
        beq     +
        dec     delay
*       jmp     mainloop
_notplus:
        cmp     #f1
        bne     _notf1
        ;; User hit F1: Decrement targetraster if able (>136)
        lda     targetraster
        cmp     #136
        beq     +
        dec     targetraster
*       jmp     mainloop
_notf1: cmp     #f3
        bne     _notf3
        ;; User hit F3: Increment targetraster if able (<164)
        lda     targetraster
        cmp     #164
        beq     +
        inc     targetraster
*       jmp     mainloop
_notf3: cmp     #f5
        bne     _notf5
        ;; User hit F5: decrement yscroll if able (>0)
        lda     yscroll
        beq     +
        dec     yscroll
*       jmp     mainloop
_notf5: cmp     #f7
        bne     _notf7
        ;; User hit F7: Increment yscroll if able (<7)
        lda     yscroll
        cmp     #7
        beq     +
        inc     yscroll
*       jmp     mainloop
_notf7: jsr     stop            ; Did user hit RUN/STOP?
        bne     keyloop         ; If not, they hit nothing fun

        ;; Restore status quo
        `print_string cleanup_str
        sei
        lda     #$00            ; Disable raster IRQ
        sta     $d01a
        sta     $c6             ; Empty keyboard buffer
        lda     #$31            ; Restore default IRQ routine
        sta     $0314
        lda     #$ea
        sta     $0315
        lda     #$81
        sta     $dc0d           ; Restore timer IRQ
        lda     #$1b            ; Restore vertical scroll
        sta     $d011
        cli
        lda     #$06
        sta     $d021
        jmp     ($a002)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TEXT STRINGS USED IN THE PROGRAM
;;;
;;; We have a lot of them.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
title:
        .byte   cls,upper_case,black,13,"       VIC-II BAD LINE EXPERIMENT",13
        .byte   13,13,13,13,13,13,13,white
        .byte   t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t
        .byte   t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t
filler: .byte   "       SAMPLE TEXT FOR COMPARISON",13,0

instructions:
        .byte   b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b
        .byte   b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b,b
        .byte   13,13,13,13,"     PRESS +/- KEYS TO CHANGE DELAY",13
        .byte   "      PRESS F1/F3 TO CHANGE RASTER",13
        .byte   "      PRESS F5/F7 TO SCROLL SCREEN",13
        .byte   "         PRESS RUN/STOP TO QUIT",0

stat_0: .byte   home,black,13,13,13,13,"        CURRENT DELAY: ",0
stat_1: .byte   " CYCLES ",13,"        CURRENT RASTER: ",0
stat_2: .byte   " (",0
stat_3: .byte   ") ",13,"             BAD LINES AT: ",0
stat_4: .byte   " ",0

cleanup_str:
        .byte   light_blue,cls,upper_case,0

explanation:
        .byte cls,lower_case,13,"       vic-ii bad line experiment",13
        .byte "             mCmARTIN, 2014",13,13
        .byte " tHIS PROGRAM LETS YOU EXPERIMENT WITH",13
        .byte " VARIOUS COMBINATIONS OF SCREEN SCROLL",13
        .byte " VALUES, RASTER INTERRUPT POINTS, AND",13
        .byte " CYCLE DELAYS AFTER NORMAL kernal IRQS.",13,13,0
explanation_1:
        .byte " iT DEMONSTRATES THE EFFECT OF THE SO-",13
        .byte " CALLED ",34,"BAD LINE",34," EFFECT WHICH",13
        .byte " TRIGGERS ON EACH NEW LINE OF TEXT.",13,13
        .byte " oN THE NEXT SCREEN, USE THE FUNCTION",13
        .byte " KEYS TO CHANGE WHICH LINE HAS THE",13
        .byte " RASTER INTERRUPT AND WHICH LINE HAS",13,0
explanation_2:
        .byte " ROWS OF TEXT START. nOTICE HOW THE",13
        .byte " RASTER IS MISPLACED BY A LINE AND A",13
        .byte " HALF OR SO WHEN THEY MATCH.",13,13
        .byte " yOU CAN ALSO ALTER HOW MANY CYCLES",13
        .byte " THE irq WAITS PRE-inc $d021.",13,13
        .byte "         pRESS ANY KEY TO BEGIN",0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SUPPORT ROUTINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; NUMOUT: Print out the value in the accumulator as an unsigned
;;;         integer. This makes heavy use of BASIC's own output
;;;         routines.
numout:
        tay
        lda     #$00
        jsr     load_16
        ldx     #$00            ; Clean out overflow in FAC1
        stx     $68
        stx     $70
        jsr     fac1_to_string
        ldx     #$01            ; High byte of result address
        ;; Skip the first character if it's not -
        lda     $100
        sec
        sbc     #$2d
        beq     strout
        lda     #$01
        ;; Fall through to strout

;;; STROUT: Output the null-terminated string at .AX. BASIC has a
;;; routine like this (at $ab1e), but it treats double-quotes as
;;; terminators and we really aren't OK with that.
strout: sta     $fb
        stx     $fc
        ldy     #$00
*       lda     ($fb),y
        beq     +
        jsr     chrout
        iny
        bne     -
*       rts

;;; Our variables. We keep them out of the way of BASIC itself.
        .alias  delay   $c000
        .alias  yscroll $c001

