        org     $4090
        include "zx81text.asm"

        ;; Check memory size, and quit with error if it's under 2KB.
        ld      hl, no_mem_err
        ld      a, ($4005)
        cp      a, $48
        jr      c, m_0

        call    draw_board
        ;; Seed RNG
        ld      hl, ($4034)     ; frame count since power on
        ld      (rnd_x), hl
m_start:
        ld      hl, title_wait_msg
        call    draw_text
        call    make_puzzle
        ld      hl, inst_msg
        call    draw_text
m_loop: call    get_key
        cp      a, $1c          ; '0' = quit
        jr      z, m_quit
        cp      a, $1d          ; '1' = restart
        jr      z, m_start
        sub     a, $26          ; < 'A'?
        jr      c, m_loop
        cp      a, $19          ; >= 'Z'?
        jr      nc, m_loop
        call    make_move
        ;; Check for victory
        ld      b, $19
m_vclp: ld      a, b
        dec     a
        call    get_display_addr
        ld      a, (hl)
        and     $80
        jr      z, m_loop       ; A light is still on
        djnz    m_vclp

        ;; Victory!
        ld      hl, win_again_msg
        call    draw_text
m_won:  call    get_key
        cp      a, $3e          ; 'Y'?
        jr      z, m_start
        cp      a, $33          ; 'N'?
        jr      nz, m_won

        ;; All done. Say goodbye properly.
m_quit: call    $0a2a           ; CLS

        ;; Print farewell message
        ld      hl, farewell_msg
m_0:    ld      a, (hl)
        cp      a, $ff
        ret     z
        push    hl
        rst     $10
        pop     hl
        inc     hl
        jr      m_0

draw_board:
        ;; Create an expanded display file
        ;; Copied, more or less, from the ROM
        ld      b, $18
        res     1, (IY+1)
        ld      c, $21
        push    bc
        call    $0918
        pop     bc
        call    $0a3e           ; (Continue with CLS from there)

        ;; Fill the screen with darkness
        ld      hl, ($400c)
        push    hl
        ld      bc, $1880
        call    fill_lines

        ;; Draw out the letters
        ld      b, $19
db_0:   ld      a, b
        dec     a
        call    get_display_addr
        add     a, $a6
        ld      (hl), a
        djnz    db_0
        ;; Draw the grey border around the play area
        pop     hl
        ld      a, $88
        ld      bc, $006c
        add     hl, bc
        push    hl
        ld      de, $0210
        ld      c, 1
        call    db_1
        pop     hl
        ld      de, $0010
        ld      c, $21
        ;; Fall through
db_1:   ld      b, $11
db_2:   ld      (hl), a
        add     hl, de
        ld      (hl), a
        sbc     hl, de
        push    bc
        ld      b, 0
        add     hl, bc
        pop     bc
        djnz    db_2
        ret

        ;; HL: pointer to located text to draw.
        ;;     Texts come in pairs.
draw_text:
        push    hl
        ld      hl, ($400c)
        ld      bc, $02b6
        add     hl, bc
        ld      bc, $0280
        call    fill_lines
        pop     hl
        call    dt_0             ; Run the rest twice
dt_0:   ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        push    hl
        ld      hl, ($400c)
        add     hl, de
        ld      d, h
        ld      e, l
        pop     hl
        ld      a, $ff
dt_1:   cp      a, (hl)
        jr      z, dt_2
        ldi
        jr      dt_1
dt_2:   inc     hl              ; Skip delimiter
        ret

make_move:
        call    get_display_addr
        call    flip_square
        ld      bc, -$63
        add     hl, bc
        call    flip_square
        ld      bc, $60
        add     hl, bc
        call    flip_square
        ld      bc, $06
        add     hl, bc
        call    flip_square
        ld      bc, $60
        add     hl, bc
        ;; Fall through to flip_square

flip_square:
        ld      a, (hl)
        ;; Range check
        and     a, $7f          ; remove reverse video status
        cp      a, $26          ; <  "A"?
        ret     c
        cp      a, $3f          ; >= "Z"?
        ret     nc
        push    hl
        ld      a, (hl)
        ld      bc, -$22
        add     hl, bc
        ld      d, h
        ld      e, l
        ld      hl, on_border
        add     a, $80
        jr      c, fs_0
        ld      hl, off_border
fs_0:   ldi
        ldi
        ldi
        call    fs_1            ; Next line
        ldi
        ld      (de), a
        inc     de
        ldi
        call    fs_1
        ldi
        ldi
        ldi
        pop     hl
        ret
fs_1:   push    hl
        ld      h, d
        ld      l, e
        ld      bc, $1e
        add     hl, bc
        ld      d, h
        ld      e, l
        pop     hl
        ret

        ;; HL: Destination address
        ;;  B: Number of lines to fill
        ;;  C: Character with which to fill
fill_lines:
        inc     hl
        ld      a, (hl)
        cp      a, $76
        jr      z, fl_0
        ld      (hl), c

        jr      fill_lines
fl_0:   djnz    fill_lines
        ret

get_display_addr:
        push    af
        push    bc

        ld      hl, ($400c)
        ld      bc, $00b0
        add     hl, bc
        ld      bc, $0063
gda_lp: cp      a, $05
        jr      c, gda_dn
        add     hl, bc
        sub     a, $05
        jr      gda_lp
gda_dn: ld      c, a            ; a = a * 3
        add     a, a
        add     a, c
        ld      b, 0
        ld      c, a
        add     hl, bc          ; a is less than 16, so carry is clear

        pop     bc
        pop     af
        ret

get_key:
        ;; Wait for no key, then wait for key
        call    $02bb           ; KSCAN
        inc     l
        jr      nz, get_key
gk_0:   call    rnd             ; step the RNG while waiting for a key
        call    $02bb
        inc     l
        jr      z, gk_0
        dec     l
        ld      b, h
        ld      c, l
        call    $07bd           ; FINDCHR
        ld      a, (hl)
        ret

make_puzzle:
        ld      bc, 1000
mp_0:   push    bc
mp_1:   call    rnd
        ld      a, h
        and     a, $1f          ; Extract a 0-31 value
        cp      a, $19          ; Reroll if it's 25-31
        jr      nc, mp_1
        call    make_move
        pop     bc
        dec     c               ; Apparently DEC BC doesn't set Z?
        jr      nz, mp_0
        djnz    mp_0
        ret

        include "xorshift.asm"

;;; Positioned messages, for poking into place. $FF-terminated, and the
;;; first two bytes indicate the offset into the display file to show
;;; them.
        zx81inverse
title_wait_msg:
        defw    $002D
        asc     "LIGHTS  OUT",$FF
        defw    $02BF
        asc     "PLEASE  WAIT...",$FF

inst_msg:
        defw    $02BC
        asc     "PRESS LETTERS TO MOVE",$FF
        defw    $02D8
        asc     "1 FOR NEW PUZZLE     0 TO QUIT",$FF

win_again_msg:
        defw    $02BF
        asc     "CONGRATULATIONS",$FF
        defw    $02DF
        asc     "PLAY AGAIN (Y/N)?",$FF

;;; Unpositioned; these are for printing with RST 10 after play.
        zx81text
no_mem_err:
        asc     "2KB+ RAM REQUIRED, SORRY",$FF

farewell_msg:
        defb    $00,$00,$00,$00,$00,$00,$88,$88,$80,$80
        asc     " LIGHTS OUT "
        defb    $80,$80,$88,$88
        asc     "\n   BUMBERSHOOT SOFTWARE, 2017\n\n\n"
        asc     "THANKS FOR PLAYING...\n"
        asc     "                --MICHAEL MARTIN\n",$FF

on_border:
        defb    $07,$03,$84,$05,$85,$82,$83,$81

off_border:
        defb    $80,$80,$80,$80,$80,$80,$80,$80
