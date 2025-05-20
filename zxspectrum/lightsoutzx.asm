        org     $7000
attrs   equ     $5800
attr_p  equ     $5c8d
attr_t  equ     $5c8f
bordcr  equ     $5c48
df_sz   equ     $5c6b
frames  equ     $5c78
last_k  equ     $5c08
tvflag  equ     $5c3c
udg     equ     $5c7b

board_x equ     7
board_y equ     3

default_attr    equ     $07
end_attr        equ     $38
off_attr_border equ     $00
off_attr_letter equ     $04
on_attr_border  equ     $42
on_attr_letter  equ     $57

        call    draw_board
        ;; Seed RNG
        ld      hl, (frames)
        ld      (rnd_x), hl
m_start:
        call    clear_text
        call    s_print
        defb    $16,0,8
        defm    "Please wait ..."
        defb    $ff
        call    make_puzzle
        call    s_print
        defb    $16,0,5
        defm    "Press letters to move"
        defb    $16,1,1
        defm    "1 for new puzzle     0 to quit"
        defb    $ff

m_loop: call    get_key
        cp      a, '0'
        jr      z, m_quit
        cp      a, '1'
        jr      z, m_start
        and     $DF             ; If it's a letter, make it uppercase
        ld      c, a
        sub     a, 'A'          ; < 'A'?
        jr      c, m_loop
        cp      a, $19          ; >= 'Z'?
        jr      nc, m_loop
        call    make_move
        ;; Check for victory
        ld      b, $19
        ld      c, 'Z'
m_vclp: dec     c
        call    charattr
        ld      a, (hl)
        cp      on_attr_letter
        jr      z, m_loop       ; A light is still on
        djnz    m_vclp

        ;; Victory!
        call    clear_text
        call    s_print
        defb    $16,0,8
        defm    "Congratulations"
        defb    $16,1,7
        defb    "Play again (Y/N)?"
        defb    $ff
m_won:  call    get_key
        or      $20
        cp      a, 'y'
        jp      z, m_start
        cp      a, 'n'
        jr      nz, m_won

        ;; All done. Say goodbye properly.
m_quit: xor     a
        ld      (tvflag),a
        ld      a, end_attr
        ld      (bordcr),a
        call    cls
        ld      a, 7
        out     ($fe),a

        ;; Print farewell message
        call    s_print
        defb    $16,0,6,137,137,143,143
        defm    " LIGHTS OUT "
        defb    143,143,134,134,$16,1,3
        defm    "Bumbershoot Software, 2017"
        defb    13,13
        defm    "Thanks for playing..."
        defb    $17,16
        defm    "--Michael Martin"
        defb    $ff
        ret

cls:    push    af
        ld      hl, $4000
        ld      de, $4001
        ld      bc, $1800
        xor     a
        ld      (hl),a
        ldir
        pop     af
        ld      (attr_p),a
        ld      (attr_t),a
        ld      (hl),a
        ld      bc, $02ff
        ldir
        ret

draw_board:
        ;; Print to top of screen
        xor     a
        ld      (tvflag), a
        out     ($fe),a         ; Border
        ld      (bordcr),a
        ld      a,default_attr
        call    cls

        ;; Load custom charset
        ld      hl, custom_chars
        ld      de, (udg)
        ld      bc, $0070
        ldir
        ;; Draw the board
        call    s_print
        defb    $16,0,10
        defm    "LIG"
        defb    $13,1
        defm    "HTS O"
        defb    $13,0
        defm    "UT!"
        defb    $16,board_y,board_x ; AT board_y, board_x
        defb    $90,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$91,$0d,$ff

        ld      b, 5
pb_loop:
        call    s_print
        defb    $17,board_x,0   ; TAB(board_x)
        defb    $95,$10,$00,$96,$97,$98,$96,$97,$98,$96,$97,$98,$96,$97,$98,$96,$97,$98,$10,$07,$95,$0d
        defb    $17,board_x,0   ; TAB(board_x)
        defb    $95,$10,$00,$99,$20,$9a,$99,$20,$9a,$99,$20,$9a,$99,$20,$9a,$99,$20,$9a,$10,$07,$95,$0d
        defb    $17,board_x,0   ; TAB(board_x)
        defb    $95,$10,$00,$9b,$9c,$9d,$9b,$9c,$9d,$9b,$9c,$9d,$9b,$9c,$9d,$9b,$9c,$9d,$10,$07,$95,$0d,$ff
        djnz    pb_loop

        call    s_print
        defb    $17,board_x,0   ; TAB(board_x)
        defb    $92,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$94,$93,$0d,$ff

        ld      bc,$1941
pb_0:   call    charloc
        ld      a,$16
        rst     $10
        ld      a,h
        rst     $10
        ld      a,l
        rst     $10
        ld      a,c
        rst     $10
        call    charattr
        ld      a,off_attr_letter
        ld      (hl),a
        inc     c
        djnz    pb_0
        ld      a,1             ; Back to bottom of screen for status.
        ld      (tvflag),a
        ret

clear_text:
        ld      a,$16           ; Top left...
        rst     $10
        xor     a
        rst     $10
        xor     a
        rst     $10
        ld      b,63            ; Then print 63 spaces.
ct_0:   ld      a,$20
        push    bc
        rst     $10
        pop     bc
        djnz    ct_0
        ret

        ;; In: C = character code
        ;; Out: H = row, L = col
charloc:
        push    af
        push    bc
        ld      a,c
        sub     a,65
        ld      hl,$0000
cl_0:   cp      a,5
        jr      c, cl_1
        sub     a,5
        inc     h
        jr      cl_0
cl_1:   ld      l,a
        ld      b,h
        ld      c,l
        add     hl,hl
        add     hl,bc
        ld      bc,board_y*256+board_x+514
        add     hl,bc
        pop     bc
        pop     af
        ret

        ;; IN:   C: Character code to locate
        ;; OUT: HL: address in attribute table of that
charattr:
        push    bc
        call    charloc
        ld      c,l
        ld      l,0
        ld      b,3
ca_0:   srl     h
        rr      l
        djnz    ca_0
        add     hl,bc
        ld      bc,attrs
        add     hl,bc
        pop     bc
        ret

        ;; IN:   C: Character code of move
make_move:
        push    bc
        push    hl
        call    charattr
        call    flip
        ld      bc,-96
        add     hl,bc
        call    flip
        ld      bc,93
        add     hl,bc
        call    flip
        ld      c,6
        add     hl,bc
        call    flip
        ld      c,93
        add     hl,bc
        call    flip
        pop     hl
        pop     bc
        ret

        ;; IN:  HL: Attr address of potential piece to flip
flip:   push    af
        push    de
        ld      de,off_attr_letter*256+off_attr_border
        ld      a,(hl)
        cp      on_attr_letter
        jr      z,flip_ok
        cp      d
        jr      nz,flip_exit
        ld      de,on_attr_letter*256+on_attr_border
flip_ok:
        push    bc
        push    hl
        ld      bc,31
        ccf
        sbc     hl,bc
        dec     hl
        dec     bc
        ld      (hl),e
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),e
        add     hl,bc
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl
        ld      (hl),e
        add     hl,bc
        ld      (hl),e
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),e
        pop     hl
        pop     bc
flip_exit:
        pop     de
        pop     af
        ret

s_print:
        pop     hl
        ld      a,(hl)
        inc     hl
        push    hl
        cp      $ff
        ret     z
        rst     $10
        jr      s_print

get_key:
        bit     5,(iy+1)
        jr      z, get_key
        ld      a,(last_k)
        res     5,(iy+1)
        ret

make_puzzle:
        ld      bc, 1000
mp_0:   push    bc
mp_1:   call    rnd
        ld      a, h
        and     a, $1f          ; Extract a 0-31 value
        cp      a, $19          ; Reroll if it's 25-31
        jr      nc, mp_1
        add     'A'
        ld      c, a
        call    make_move
        pop     bc
        dec     c               ; Apparently DEC BC doesn't set Z?
        jr      nz, mp_0
        djnz    mp_0
        ret

;;; Neat divide-free RNG
;;; Algorithm found at http://b2d-f9r.blogspot.com/2010/08/16-bit-xorshift-rng-now-with-more.html
rnd_x:  defw    $5a3f
rnd_y:  defw    $8e77
rnd:    ld      hl, (rnd_x)
        ;; t = x ^ (x << 5)  [t = DE and HL]
        ld      d, h
        ld      e, l
        ld      b, 5
rnd_0:  sla     l
        rl      h
        djnz    rnd_0
        ld      a, h
        xor     a, d
        ld      d, a
        ld      h, a
        ld      a, l
        xor     a, e
        ld      e, a
        ld      l, a
        ;; t = t ^ (t >>> 3) [t = DE]
        ld      b, 3
rnd_1:  srl     h
        rr      l
        djnz    rnd_1
        ld      a, h
        xor     a, d
        ld      d, a
        ld      a, l
        xor     a, e
        ld      e, a
        ;; x = y
        ld      hl, (rnd_y)
        ld      (rnd_x), hl
        ;; y = y ^ (y >>> 1) ^ t [t = DE, y = HL]
        ld      b, h
        ld      c, l
        srl     h
        rr      l
        ld      a, b
        xor     a, h
        xor     a, d
        ld      h, a
        ld      a, c
        xor     a, l
        xor     a, e
        ld      l, a
        ld      (rnd_y), hl
        ;; return y (still in HL)
        ret

custom_chars:
        defb    $00,$3f,$7f,$60,$60,$63,$67,$66 ; A: Upper-left border
        defb    $00,$fc,$fe,$06,$06,$c6,$e6,$66 ; B: Upper-right border
        defb    $66,$67,$63,$60,$60,$7f,$3f,$00 ; C: Lower-left border
        defb    $66,$e6,$c6,$06,$06,$fe,$fc,$00 ; D: Lower-right border
        defb    $00,$ff,$ff,$00,$00,$ff,$ff,$00 ; E: Horizontal edge
        defb    $66,$66,$66,$66,$66,$66,$66,$66 ; F: Vertical edge
        defb    $00,$00,$00,$00,$00,$00,$00,$01 ; G: NW Circle
        defb    $00,$00,$00,$00,$00,$00,$7e,$ff ; H: N Circle
        defb    $00,$00,$00,$00,$00,$00,$00,$80 ; I: NE Circle
        defb    $03,$07,$07,$0f,$0f,$07,$07,$03 ; J: W Circle
        defb    $c0,$e0,$e0,$f0,$f0,$e0,$e0,$c0 ; K: E Circle
        defb    $01,$00,$00,$00,$00,$00,$00,$00 ; L: SW Circle
        defb    $ff,$7e,$00,$00,$00,$00,$00,$00 ; M: S Circle
        defb    $80,$00,$00,$00,$00,$00,$00,$00 ; N: SE Circle
