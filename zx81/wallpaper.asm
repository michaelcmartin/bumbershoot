        ;; WALLPAPER PLUS

        ;; An adaptation of Mark Charlton's 1982 program "NAME
        ;; WALLPAPER", published in "51 Game Programs for the Timex
        ;; Sinclair 1000 and 1500" (ed. Tim Hartnell).

        ;; This file is intended to be assembled by z88dk, but does
        ;; not require linking -- as a hybrid BASIC/machin code program
        ;; this file will assemble to a complete ZX81 memory dump on its
        ;; own. Assemble with the command:
        ;;
        ;;       z80asm -b -r4009 wallpaper.asm
        ;;
        ;; and then rename wallpaper.bin to WALLPAPER.P so that is will
        ;; run in your emulator of choice. At least 2KB of RAM is
        ;; required for proper operation.

        ;; .P files start at $4009
        org     16393

        ;; Some useful routines in the ROM
        defc    KEYBOARD=$02bb
        defc    SCROLL=$0c0e

        ;; System variables
        defb    $00             ; VERSN
        defw    $0001           ; E_PPC
        defw    d_file, df_cc, vars
        defw    $0000           ; DEST
        defw    vars+1          ; E_LINE
        defw    vars+5          ; CH_ADD
        defw    $0000           ; X_PTR
        defw    vars+6,vars+6   ; STKBOT, STKEND
        defb    $00             ; BERG
        defw    membot          ; MEM
        defb    $00             ; spare
        defb    $02             ; DF_SZ
        defw    $0001           ; S_TOP
        defw    $0000           ; LAST_K
        defb    $ff             ; DB_ST
        defb    $37             ; MARGIN (1F=NTSC, 37 = PAL)
        defw    d_file          ; NXTLIN (16509 to autorun, d_file otherwise)
        defw    $0000           ; OLDPPC
        defb    $00             ; FLAGX
        defw    $0000           ; STRLEN
        defw    $0c8d           ; T_ADDR
        defw    $0000           ; SEED
FRAMES: defw    $0000           ; FRAMES
        defw    $0000           ; COORDS
        defb    $21             ; PR_CC
        defw    $1821           ; S_POSN
        defb    $40             ; CDFLAG
        defb    $00,$00,$00,$00,$00,$00,$00,$00
        defb    $00,$00,$00,$00,$00,$00,$00,$00
        defb    $00,$00,$00,$00,$00,$00,$00,$00
        defb    $00,$00,$00,$00,$00,$00,$00,$00,$76
membot: defb    $00,$00,$00,$00,$00,$00,$00,$00
        defb    $00,$00,$00,$00,$00,$00,$00,$00
        defb    $00,$00,$00,$00,$00,$00,$00,$00
        defb    $00,$00,$00,$00,$00,$00,$00,$00 ; 2 bytes spare

        ;; BASIC program begins here.
        ;; 1 REM --WALLPAPER ML--

        ;;    (this line is used as buffer space by the program
        ;;     proper, so we put a label at the start of the actual
        ;;     line)

        defb    $00,$01,$12,$00,$ea
msg:    defb    $16,$16,$3c,$26,$31,$31,$35,$26
        defb    $35,$2a,$37,$00,$32,$31,$16,$16,$76

        ;; 2 REM... Machine language program
        defb    $00,$02
        defw    progend-progstart
progstart:
        defb    $ea

        ;; ----- MACHINE LANGUAGE PROGRAM BEGINS HERE -----
        ;; First, reset the RNG seed
        ld      hl, (FRAMES)
        ld      (rnd_x), hl
        ld      (rnd_y), hl

        ;; Then wait for the keyboard to be left alone
k_wait: call    KEYBOARD
        inc     l
        jr      nz, k_wait
        ld      a, l
        ld      (donev), a

        ;; Flip half the characters in msg at random
flip:   ld      de, msg
        ld      b, 16
flip_0: push    de
        push    bc
        call    rnd
        pop     bc
        pop     de
        bit     7, l
        jr      nz, flip_1
        ld      a, (de)
        xor     a, $80
        ld      (de), a
flip_1: inc     de
        djnz    flip_0

        ;; Now run 16 lines
        ld      b, 16
line:   push    bc
        call    SCROLL
        ld      b, 16
        ld      hl, msg+15
line_0: push    bc
        push    hl
        ld      a, (hl)
        rst     $10
        call    kbck
        pop     hl
        pop     bc
        dec     hl
        djnz    line_0
        ld      b, 16
line_1: inc     hl
        push    hl
        push    bc
        ld      a, (hl)
        rst     $10
        call    kbck
        pop     bc
        pop     hl
        djnz    line_1
        ld      de, msg
        ld      h, d
        ld      l, e
        inc     hl
        ld      bc, 15
        ld      a, (de)
        ldir
        ld      (de), a
        pop     bc
        ld      a, (donev)
        and     a, a
        ret     nz
        djnz    line
        jp      flip

kbck:   call    KEYBOARD
        inc     l
        ld      a, (donev)
        or      a, l
        ld      (donev), a
        ret

donev:  defb    0

INCLUDE "xorshift.asm"

        ;; ----- MACHINE LANGUAGE PROGRAM ENDS HERE -----

        ;; End of BASIC line 2
        defb    $76
progend:

        ;; BASIC program continues...

        ;; 10 SCROLL
        defb    $00,$0a,$02,$00,$e7,$76
        ;; 20 PRINT "ENTER STRING TO WALLPAPERIZE"
        defb    $00,$14,$20,$00,$f5,$0b,$2a,$33,$39,$2a,$37,$00,$38,$39,$37
        defb    $2e,$33,$2c,$00,$39,$34,$00,$3c,$26,$31,$31,$35,$26,$35,$2a
        defb    $37,$2e,$3f,$2a,$0b,$76
        ;; 30 INPUT A$
        defb    $00,$1e,$04,$00,$ee,$26,$0d,$76
        ;; 40 LET A$=A$+" "
        defb    $00,$28,$0b,$00,$f1,$26,$0d,$14,$26,$0d,$15,$0b,$00,$0b,$76
        ;; 50 IF LEN A$<16 THEN GOTO 40
        defb    $00,$32,$18,$00,$fa,$c6,$26,$0d,$13,$1d,$22,$7e,$85,$00,$00
        defb    $00,$00,$de,$ec,$20,$1c,$7e,$86,$20,$00,$00,$00,$76
        ;; 60 FOR I=1 TO 16
        defb    $00,$3c,$14,$00,$eb,$2e,$14,$1d,$7e,$81,$00,$00,$00,$00,$df
        defb    $1d,$22,$7e,$85,$00,$00,$00,$00,$76
        ;; 70 POKE 16513+I,CODE A$(I)
        defb    $00,$46,$16,$00,$f4,$1d,$22,$21,$1d,$1f,$7e,$8f,$01,$02,$00
        defb    $00,$15,$2e,$1a,$c4,$26,$0d,$10,$2e,$11,$76
        ;; 80 NEXT I
        defb    $00,$50,$03,$00,$f3,$2e,$76
        ;; 90 RAND USR 16536
        defb    $00,$5a,$0e,$00,$f9,$d4,$1d,$22,$21,$1f,$22,$7e,$8f,$01,$30
        defb    $00,$00,$76
        ;; End of program
        defb    $76

        ;; Display File and (empty) variable space
d_file: defb    $76
df_cc:  defb    $76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76
        defb    $76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76
vars:   defb    $80
