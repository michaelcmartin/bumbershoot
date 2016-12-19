        .word   $0801
        .org    $0801

        ;; KERNAL routines we use
        .alias  chrout  $ffd2
        .alias  getin   $ffe4

        .outfile "hammurabi.prg"

; BASIC program that just calls our machine language code
.scope
        .word   _next, 10       ; Next line and current line number
        .byte   $9e," 2062",0   ; SYS 2062
_next:  .word   0               ; End of program
.scend

start:  `print_str title_str

        ;; Initialize variables
        `f_move starved_total, f_0
        `f_move starved_pct, f_0
        `f_move year, f_0
        `f_move pop, f_95
        `f_move storage, f_2800
        `f_move harvest, f_3000
        `fp_load harvest
        `fp_subtract storage
        `fp_store rats
        `f_move yield, f_3
        `fp_load harvest
        `fp_divide yield
        `fp_store acres
        `f_move imm, f_5
        `f_move health, f_1

        jsr     randomize

new_year_no_starvation:
        `f_move starved, f_0
new_year:
        ;; Start-of-year statistics
        ;; year++
        `fp_load year
        `fp_add f_1
        `fp_store year
        ;; pop += immigrants
        `fp_load pop
        `fp_add imm
        `fp_store pop
        ;; Check for plague
        `fp_load health
        jsr     fac1_sign
        cmp     #$01
        beq     +
        ;; Plague!
        `fp_load pop
        `fp_divide f_2
        jsr     int_fac1
        `fp_store pop

*       jsr report
        ;; End of term?
        lda     #11
        jsr     ld_fac1_a
        `ld_fac2 year
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$00
        bne     buy_sell
        jmp     termed_out

buy_sell:
        jsr     rnd
        `fp_multiply f_10
        `fp_add f_17
        jsr     int_fac1
        `fp_store price
buy_loop:
        `print_str land_buy_str_1
        `fp_print price
        `print_str land_buy_str_2
        jsr     get_num
        jsr     fac1_sign
        cmp     #$00
        beq     maybe_sell
        `fp_store delta
        `fp_multiply price
        `ld_fac2 storage
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$FF
        beq     cant_buy
        `fp_store storage
        `fp_load acres
        `fp_add delta
        `fp_store acres
        jmp     feed_people
cant_buy:
        jsr     not_enough_grain
        jmp     buy_loop

maybe_sell:
        `print_str land_sell_str
        jsr     get_num
        `fp_store delta
        `ld_fac2 acres
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     sell_ok
        jsr     not_enough_land
        jmp     maybe_sell
sell_ok:
        `fp_store acres
        `fp_load delta
        `fp_multiply price
        `fp_add storage
        `fp_store storage

feed_people:
        `print_str nl_str
feed_lp:
        `print_str feed_str
        jsr     get_num
        `fp_store fed
        `ld_fac2 storage
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     +
        jsr     not_enough_grain
        jmp     feed_lp
*       `fp_store storage

        `print_str nl_str
plant_lp:
        `print_str plant_str
        jsr     get_num
        `fp_store planted        ; You can only plant land you have
        `ld_fac2 acres
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     +
        jsr     not_enough_land
        jmp     plant_lp
*       `fp_load pop            ; Any citizen can only farm 10 acres
        `fp_multiply f_10
        `fp_subtract planted
        jsr     fac1_sign
        cmp     #$ff
        bne     +
        jsr     not_enough_farmers
        jmp     plant_lp
*       `fp_load planted        ; 1 bushel of grain will plant 2 acres
        `fp_divide f_2
        jsr     int_fac1
        `ld_fac2 storage
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     +
        jsr     not_enough_grain
        jmp     plant_lp
*       `fp_store storage

        ;; All input for the year validated!
        ;; Compute the year's events
        ;; yield = 1d5. harvest = planted * yield.
        jsr     roll_d5
        `fp_store yield
        `fp_multiply planted
        `fp_store harvest
        ;; If 1d5 is even, rats eat 1/(roll) of pre-harvest stores
        `f_move rats,f_0
        jsr     roll_d5
        `fp_store temp
        jsr     $b1aa           ; FP->.YA signed integer (USR)
        tya
        and     #$01
        bne     +
        ;; Rats!
        `ld_fac2 storage
        jsr     f_divide_op
        jsr     int_fac1
        `fp_store rats
        ;; Compute new stores
*       `fp_load storage
        `fp_subtract rats
        `fp_add harvest
        `fp_store storage
        ;; Immigration = int(d5*(20*acres+storage)/pop/100 + 1)
        `fp_load acres
        `fp_multiply f_20
        `fp_add storage
        `fp_store temp
        jsr     roll_d5
        `fp_multiply temp
        `fp_divide pop
        `fp_divide f_100
        `fp_add f_1
        jsr     int_fac1
        `fp_store imm
        ;; 15% chance of plague
        jsr     rnd
        `fp_multiply f_2
        `fp_subtract f_0_3
        `fp_multiply f_10
        jsr     int_fac1
        `fp_store health
        ;; People need 20 bushels each to not starve to death
        `fp_load fed
        `fp_divide f_20
        jsr     int_fac1
        `ld_fac2 pop
        jsr     f_subtract_op
        `fp_store starved
        jsr     fac1_sign
        cmp     #$01
        beq     +
        jmp     new_year_no_starvation

*       `fp_load f_0_45
        `fp_multiply pop
        `ld_fac2 starved
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$01
        bne     not_finked_out
        ;; Starved over 45% of the pop in one year! Finked out.
        `print_str starve_too_much_str_1
        `fp_print starved
        `print_str starve_too_much_str_2
        `print_str fink_str
        jmp     game_over

not_finked_out:
        ;; p1=((year-1)*p1+starved*100/pop)/year
        `fp_load year
        `fp_subtract f_1
        `fp_multiply starved_pct
        `fp_store temp
        `fp_load starved
        `fp_divide pop
        `fp_multiply f_100
        `fp_add temp
        `fp_divide year
        `fp_store starved_pct

        `fp_load starved_total
        `fp_add starved
        `fp_store starved_total

        `fp_load pop
        `fp_subtract starved
        `fp_store pop

        jmp     new_year
termed_out:
        `fp_load acres
        `fp_divide pop
        `fp_store temp

        `print_str final_str_1
        `fp_load starved_pct
        jsr     int_fac1
        jsr     fac1out
        `print_str final_str_2
        `fp_print starved_total
        `print_str final_str_3
        `fp_load temp
        jsr     int_fac1
        jsr     fac1out
        `print_str final_str_4

        ;; Worst result: 33% death rate or < 7 acres/person
        lda     #33
        jsr     ld_fac1_a
        `ld_fac2 starved_pct
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     rank_fink
        lda     #7
        jsr     ld_fac1_a
        `ld_fac2 temp
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     +
rank_fink:
       `print_str fink_str
        jmp     game_over

        ;; Second-worst result: 10% death rate or < 9 acres/person
*       lda     #10
        jsr     ld_fac1_a
        `ld_fac2 starved_pct
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     rank_nero
        lda     #9
        jsr     ld_fac1_a
        `ld_fac2 temp
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     +
rank_nero:
        `print_str nero_str
        jmp     game_over

        ;; Second-best result: 3% death rate or < 10 acres/person
*       lda     #3
        jsr     ld_fac1_a
        `ld_fac2 starved_pct
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     rank_ok
        lda     #10
        jsr     ld_fac1_a
        `ld_fac2 temp
        jsr     f_subtract_op
        jsr     fac1_sign
        cmp     #$ff
        bne     +
rank_ok:
        `print_str ok_str_1
        jsr     rnd
        `fp_multiply f_0_8
        jsr     int_fac1
        jsr     fac1out
        `print_str ok_str_2
        jmp     game_over

        ;; Best result!
*       `print_str excellent_str

game_over:
        `print_str again_str
*       jsr     getin
        cmp     #'Y
        bne     +
        jmp     start
*       cmp     #'N
        bne     --
        `print_str bye_str
        rts

roll_d5:
        jsr     rnd
        `fp_multiply f_5
        `fp_add f_1
        jmp     int_fac1

not_enough_grain:
        `print_str not_enough_str
        `print_str not_enough_grain_str_1
        `fp_print   storage
        `print_str not_enough_grain_str_2
        rts

not_enough_land:
        `print_str not_enough_str
        `print_str not_enough_acres_str_1
        `fp_print   acres
        `print_str not_enough_acres_str_2
        rts

not_enough_farmers:
        `print_str not_enough_farmers_str_1
        `fp_print   pop
        `print_str not_enough_farmers_str_2
        rts

report: `print_str report_str_1
        `fp_print   year
        `print_str nl_str
        `fp_print   starved
        `print_str report_str_2
        `fp_print   imm
        `print_str report_str_3
        `fp_load   health
        jsr     fac1_sign
        cmp     #$01
        beq     +
        `print_str plague_str
*       `print_str report_str_4
        `fp_print  pop
        `print_str report_str_5
        `fp_print  acres
        `print_str report_str_6
        `fp_print  yield
        `print_str report_str_7
        `fp_print  rats
        `print_str report_str_8
        `fp_print  storage
        `print_str report_str_9
        rts

get_num:
.scope
        lda     #$00            ; Turn on blinky cursor
        sta     $cc
        sta     numindx
_lp:    jsr     getin
        cmp     #$14            ; DEL?
        bne     +
        ldx     numindx
        beq     _lp
        dex
        stx     numindx
        jsr     chrout
        jmp     _lp
*       cmp     #$0D            ; RETURN?
        bne     +
        ldx     numindx
        beq     _lp
        bne     _got
*       cmp     #'0             ; digit?
        bcc     _lp
        cmp     #'9+1
        bcs     _lp
        ldx     numindx         ; Room for character?
        cpx     #$0f
        beq     _lp
        sta     numbuf,x
        inx
        stx     numindx
        jsr     chrout
        jmp     _lp
_got:   ldx     numindx
        lda     #$00
        sta     numbuf,x
        lda     #$01            ; Disable blinky cursor again
        sta     $cc
        lda     #$20
        jsr     chrout
        lda     #$0d
        jsr     chrout
         ;; Turn our numbers into a floating point result!
        `fp_load f_0
        ldx     #$00
        stx     $68             ; Clean out any leftover overflow
        stx     $70
*       txa
        pha
        lda     numbuf,x
        beq     _done
        sec
        sbc     #'0
        pha
        jsr     $bae2           ; FAC1 *= 10
        jsr     fac1_to_57
        pla
        jsr     ld_fac1_a
        `fp_add $57
        pla
        tax
        inx
        jmp     -
_done:  pla
        rts
.scend

;;; Strings
title_str:
        .byte 147,14,13,"               hammurabi",13,13
        .byte "  oRIGINAL BY cREATIVE cOMPUTING, 1978",13
        .byte "    c64 PORT BY mICHAEL mARTIN, 2016",13,13
        .byte "   tRY YOUR HAND AT GOVERNING ANCIENT",13
        .byte " sUMERIA FOR A TEN-YEAR TERM OF OFFICE.",13
        ;; Fall through to nl_str

nl_str: .byte 13,0

report_str_1:
        .byte 13,13,"hAMMURABI, i BEG TO REPORT TO YOU:",13,"iN YEAR ",0
report_str_2:
        .byte " PEOPLE STARVED",13,0
report_str_3:
        .byte " CAME TO THE CITY",13,0
report_str_4:
        .byte "pOPULATION IS NOW ",0
report_str_5:
        .byte 13,"tHE CITY NOW OWNS ",0
report_str_6:
        .byte " ACRES.",13,"yOU HARVESTED ",0
report_str_7:
        .byte " BUSHELS PER ACRE.",13,"rATS ATE ",0
report_str_8:
        .byte " BUSHELS.",13,"yOU NOW HAVE ",0
report_str_9:
        .byte " BUSHELS IN STORE.",13,0

plague_str:
        .byte "a HORRIBLE PLAGUE STRUCK!",13,"hALF THE PEOPLE DIED.",13,0

land_buy_str_1:
        .byte "lAND IS TRADING AT ",0
land_buy_str_2:
        .byte " BUSHELS",13,"PER ACRE. hOW MANY ACRES DO YOU WISH",13,"TO BUY? ",0
land_sell_str:
        .byte "hOW MANY ACRES DO YOU WISH TO",13,"SELL? ",0
feed_str:
        .byte "hOW MANY BUSHELS DO YOU WISH TO FEED",13,"YOUR PEOPLE? ",0
plant_str:
        .byte "hOW MANY ACRES DO YOU WISH TO PLANT",13,"WITH SEED? ",0

not_enough_farmers_str_1:
        .byte "bUT YOU ONLY HAVE ",0
not_enough_farmers_str_2:
        .byte " PEOPLE TO TEND",13,"THE FIELDS! nOW THEN,",13,0

not_enough_str:
        .byte "hAMMURABI: THINK AGAIN. yOU ONLY",13,0
not_enough_grain_str_1:
        .byte "HAVE ",0
not_enough_grain_str_2:
        .byte " BUSHELS OF GRAIN. nOW THEN,",13,0
not_enough_acres_str_1:
        .byte "OWN ",0
not_enough_acres_str_2:
        .byte " ACRES. nOW THEN,",13,0

starve_too_much_str_1:
        .byte "yOU STARVED ",0
starve_too_much_str_2:
        .byte " PEOPLE IN ONE YEAR!!!",13,0

final_str_1:
        .byte "iN YOUR 10-YEAR TERM OF OFFICE, ",0
final_str_2:
        .byte 13,"PERCENT OF THE POPULATION STARVED PER",13
        .byte "YEAR ON THE THE AVERAGE. i.e. A TOTAL",13,"OF ",0
final_str_3:
        .byte " PEOPLE DIED!!",13
        .byte "yOU STARTED WITH 10 ACRES PER PERSON",13
        .byte "AND ENDED WITH ",0
final_str_4:
        .byte " ACRES PER PERSON.",13,0

fink_str:
        .byte "dUE TO THIS EXTREME MISMANAGEMENT YOU",13
        .byte "HAVE NOT ONLY BEEN IMPEACHED AND",13
        .byte "THROWN OUT OF OFFICE BUT YOU HAVE ALSO",13
        .byte "BEEN DECLARED NATIONAL FINK!!!!",13,0

nero_str:
        .byte "yOUR HEAVY-HANDED PERFORMANCE SMACKS",13
        .byte "OF nERO AND iVAN iv. tHE PEOPLE",13
        .byte "(REMAINING) FIND YOU AN UNPLEASANT",13
        .byte "RULER AND, FRANKLY, HATE YOUR GUTS!!",13,0

ok_str_1:
        .byte "yOUR PERFORMANCE COULD HAVE BEEN",13
        .byte "SOMEWHAT BETTER, BUT REALLY WASN'T TOO",13
        .byte "BAD AT ALL. ",0

ok_str_2:
        .byte " PEOPLE WOULD HAVE",13
        .byte "DEARLY LIKED TO HAVE SEEN YOU",13
        .byte "ASSASSINATED, BUT WE ALL HAVE OUR",13
        .byte "TRIVIAL PROBLEMS.",13,0

excellent_str:
        .byte "a FANTASTIC PERFORMANCE!!!",13
        .byte "cHARLEMAGNE, dISRAELI, AND jEFFERSON",13
        .byte "COMBINED COULD NOT HAVE DONE BETTER!",13,0

again_str:
        .byte 13,"tRY ANOTHER TERM? (y/n)",0

bye_str:
        .byte 147,142,13,"SO LONG FOR NOW.",13,0

;;; INTERFACE TO BASIC

        .alias  int_fac1        $bccc
        .alias  rnd_fac1        $e097
        .alias  ld_fac1_a       $bc3c
        .alias  fac1_to_57      $bbca
        .alias  fac1_to_5c      $bbc7
        .alias  fac1_to_string  $bddd
        .alias  ld_fac1_mem     $bba2
        .alias  ld_fac2_mem     $ba8c
        .alias  fac1_sign       $bc2b
        .alias  f_subtract_op   $b853
        .alias  f_divide_op     $bb12
        .alias  f_add_mem       $b867
        .alias  f_subtract_mem  $b850
        .alias  f_multiply_mem  $ba28
        .alias  f_divide_mem    $bb0f
        .alias  f_0_5           $bf11           ;  0.5
        .alias  f_1             $b9bc           ;  1.0
        .alias  f_pi            $aea8           ;  3.1415926
        .alias  f_10            $baf9           ; 10.0

;; Copy 5-byte values around in memory without touching the FACs.
.macro  f_move
        ldx     #$00
_fmvlp: lda     _2,x
        sta     _1,x
        inx
        cpx     #$05
        bne     _fmvlp
.macend

;;; These next few macros really exist just to save us the trouble of loading
;;; addresses into registers
.macro  print_str
        lda     #<_1
        ldy     #>_1
        jsr     strout
.macend

.macro  ld_fac2
        lda     #<_1
        ldy     #>_1
        jsr     ld_fac2_mem
.macend

.macro  fp_load
        lda     #<_1
        ldy     #>_1
        jsr     ld_fac1_mem
.macend

.macro  fp_store
        lda     #<_1
        ldy     #>_1
        jsr     fac1_to_mem
.macend

.macro  fp_print
        `fp_load _1
        jsr     fac1out
.macend

.macro  fp_add
        lda     #<_1
        ldy     #>_1
        jsr     f_add_mem
.macend

;;; Transferring FAC1 directly to FAC2 seems to corrupt the state of
;;; the FACs somehow. We bounce through $57 to stabilize it.
.macro  fp_subtract
        jsr     fac1_to_57
        `fp_load _1
        lda     #$57
        ldy     #$00
        jsr     f_subtract_mem
.macend

.macro  fp_multiply
        lda     #<_1
        ldy     #>_1
        jsr     f_multiply_mem
.macend

;;; Division has the same issue subtraction does.
.macro  fp_divide
        jsr     fac1_to_57
        `fp_load _1
        lda     #$57
        ldy     #$00
        jsr     f_divide_mem
.macend

;;; Utility routine for converting the system clock to a floating point
;;; value.
ld_fac1_ti:
        jsr     $ffde           ; RDTIM
        sty     $63
        stx     $64
        sta     $65
        ;; Once the requirements on .Y and $68 are better
        ;; understood, this might be exportable as
        ;; ld_fac1_s32, but there are still some dragons
        ;; lurking
        ldy     #$00            ; Clear out intermediary values
        sta     $62
        sta     $68
        jmp     $bcd5

;;; FAC1 can only be stored out to two locations. We'd prefer to be able
;;; to store anywhere. This routine is a support routine that allows that.
;;; It will normally only be called by the fp_store macro.
fac1_to_mem:
        sta     $fd
        sty     $fe
        jsr     fac1_to_5c
        ldy     #$00
*       lda     $5c,y
        sta     ($fd),y
        iny
        cpy     #$05
        bne     -
        rts

ld_fac1_string:
        ldx     $7a
        sta     $7a
        txa
        pha
        lda     $7b
        pha
        sty     $7b
        jsr     $79
        jsr     $bcf3
        pla
        sta     $7b
        pla
        sta     $7a
        rts

;;; Print out the contents of FAC1.
fac1out:
        ldy     #$00            ; Clean out overflow
        sty     $68
        sty     $70
        jsr     fac1_to_string
        ldy     #$01
        ;; Skip the first character if it's not "-"
        lda     $100
        sec
        sbc     #$2d
        beq     strout
        lda     #$01
        ;; Fall through to strout

;;; The BASIC ROM already has a STROUT routine - $ab1e - but
;;; it makes use of BASIC's own temporary string handling. We
;;; don't want it to ever touch its notion of temporary strings
;;; here, so we provide our own short routine to do this.
strout: sta     $fd
        sty     $fe
        ldy     #$00
*       lda     ($fd),y
        beq     +
        jsr     chrout
        iny
        bne     -
*       rts

;;; Execute RND(-TI), seeding the random number generator the traditional way.
randomize:
        jsr     ld_fac1_ti
        lda     #$ff
        sta     $66             ; Force sign negative
        jmp     rnd_fac1        ; RND(-TI)


;;; Return RND(1), a fresh random number between 0 and 1.
rnd:    lda     #$01
        jsr     ld_fac1_a
        jmp     rnd_fac1

;;; END OF BASIC INTERFACE

;;; Floating point constants
f_0:    .byte $00,$00,$00,$00,$00
f_0_3:  .byte $7f,$19,$99,$99,$99
f_0_45: .byte $7f,$66,$66,$66,$66
f_0_8:  .byte $80,$4c,$cc,$cc,$cc
f_2:    .byte $82,$00,$00,$00,$00
f_3:    .byte $82,$40,$00,$00,$00
f_5:    .byte $83,$20,$00,$00,$00
f_17:   .byte $85,$08,$00,$00,$00
f_20:   .byte $85,$20,$00,$00,$00
f_95:   .byte $87,$3e,$00,$00,$00
f_100:  .byte $87,$48,$00,$00,$00
f_2800: .byte $8c,$2f,$00,$00,$00
f_3000: .byte $8c,$3b,$80,$00,$00

;;; Floating point variables
        .space  starved_total 5 ; "d1"
        .space  starved_pct   5 ; "p1"
        .space  year    5       ; "z"
        .space  pop     5       ; "p"
        .space  storage 5       ; "s"
        .space  harvest 5       ; "h"
        .space  rats    5       ; "e"
        .space  yield   5       ; "y"
        .space  acres   5       ; "a"
        .space  imm     5       ; "i" - immigrants
        .space  health  5       ; "q"
        .space  starved 5       ; "d"
        .space  price   5       ; "y" repurposed
        .space  delta   5       ; "q" repurposed
        .space  fed     5       ; "q" repurposed
        .space  planted 5       ; "d" repurposed
        .space  temp    5       ; "c"

        ;; For get_num
        .space  numbuf  16
        .space  numindx 1
