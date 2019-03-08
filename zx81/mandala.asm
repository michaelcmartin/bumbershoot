        org     $4090

        jr      init
;;; tiles and board are not allowed to cross page boundaries, so we put them
;;; first, at $4092, so that they do not trouble us.
mandala_tiles:
        defb    0,0,2,1,130,129,136,136
        defb    0,0,135,4,7,132,136,136
chopper_tiles:
        defb    0,0,132,7,134,6,136,136
        defb    0,0,129,130,6,134,136,136

board:
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

init:   call    $0a2a                   ; CLS
        ld      hl, title_msg
        call    print_at
        ld      hl, modes_msg
        call    print_at
modelp: call    get_key
        cp      a, 29                   ; Selected (1)?
        jr      z, gotmode_0
        cp      a, 30                   ; Selected (2)?
        jr      nz, modelp
        ;; Selected (2)
        ld      de, chopper_init
        ld      hl, chopper_tiles
        jr      mode_done
gotmode_0: ;; Selected (1)
        ld      de, mandala_init
        ld      hl, mandala_tiles
mode_done:
        ld      (mode_0+1), de
        ld      (mode_1+1), hl
        call    $0a2a                   ; CLS
        ld      hl, board
mode_0: ld      de, mandala_init
        xor     a
        ld      (human_score),a
        ld      (computer_score),a
        ld      c, 16
init_0: ld      b, 4
        ld      a,(de)
init_1: push    af
        and     a, 3
        add     a, a
        ld      (hl),a
        pop     af
        inc     hl
        srl     a
        srl     a
        djnz    init_1
        inc     de
        dec     c
        jr      nz, init_0
        ;; Fall through to draw

draw:   ld      hl,human_score_msg
        call    print_at
        ld      a,(human_score)
        add     a,28
        rst     $10
        ld      hl,computer_score_msg
        call    print_at
        ld      a,(computer_score)
        add     a,28
        rst     $10
        ld      bc,$1821
        call    $0918                   ; Home cursor
        call    draw_num_bar
        call    draw_bar
        ld      hl, board
        ld      c, 8
draw_0: ld      a,156                   ; CODE "[0]"
        add     c
        rst     $10
        push    af
        ld      a, 128
        rst     $10
draw_1: ld      b, 8
draw_2: ld      a, (tile_offset)
        add     a, (hl)
        inc     hl
mode_1: ld      de, mandala_tiles
        add     a,e
        ld      e,a
        ld      a, (de)
        rst     $10
        inc     de
        ld      a, (de)
        rst     $10
        djnz    draw_2
        ld      a, (tile_offset)
        xor     a, 8
        ld      (tile_offset), a
        jr      nz, draw_3
        ;; Prepare for second run
        ld      a,128
        rst     $10
        pop     af
        rst     $10
        ld      a,$76
        rst     $10
        ld      a,128
        rst     $10
        rst     $10
        ld      a,l
        sub     a,8
        ld      l,a
        jr      draw_1
draw_3: ld      a,128
        rst     $10
        rst     $10
        ld      a,$76
        rst     $10
        dec     c
        jr      nz, draw_0
        call    draw_bar
        ;; Fall through to draw_num_bar

draw_num_bar:
        ld      a,128
        rst     $10
        rst     $10
        ld      b,8
draw_num_bar_0:
        rst     $10
        ld      a,174                    ; CODE "[I]"
        sub     b
        rst     $10
        ld      a,128
        djnz    draw_num_bar_0
        rst     $10
        rst     $10
        ld      a,$76
        rst     $10
        ret

draw_bar:
        ld      b, 20
        ld      a, 128
draw_bar_0: rst $10
        djnz    draw_bar_0
        ld      a, $76
        rst     $10
        ret

print_at:
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        push    hl
        call    $0918                   ; Set cursor location
        pop     hl
print_at_0:
        ld      a,(hl)
        cp      a,$ff
        ret     z
        rst     $10
        inc     hl
        jr      print_at_0

get_key:
        ;; Wait for no key, then wait for key
        call    $02bb           ; KSCAN
        inc     l
        jr      nz, get_key
gk_0:   call    $02bb           ; KSCAN
        inc     l
        jr      z, gk_0
        dec     l
        ld      b, h
        ld      c, l
        call    $07bd           ; FINDCHR
        ld      a, (hl)
        ret

tile_offset:
        defb    8
mandala_init:
        defb    $ee,$ce,$bb,$33,$ee,$cc,$3b,$73
        defb    $ce,$dc,$33,$77,$cc,$dd,$73,$77
chopper_init:
        defb    $ee,$ee,$bb,$bb,$ee,$ee,$33,$33
        defb    $cc,$cc,$77,$77,$dd,$dd,$77,$77
title_msg:
        defb    $19,$14,$38,$2a,$31,$2a,$28,$39,$00,$2c,$26,$32,$2a,$00,$32
        defb    $34,$29,$2a,$ff
modes_msg:
        defb    $1b,$0c,$10,$1d,$11,$00,$32,$26,$33,$29,$26,$31,$26,$00,$28
        defb    $2d,$2a,$28,$30,$2a,$37,$38,$76,$76,$00,$00,$00,$00,$00,$00
        defb    $10,$1e,$11,$00,$28,$2d,$34,$35,$35,$2a,$37,$00,$28,$2d,$2a
        defb    $28,$30,$2a,$37,$38,$ff
human_score_msg:
        defb    $0c,$18,$2d,$3a,$32,$26,$33,$0e,$00,$00,$00,$00,$ff
computer_score_msg:
        defb    $0c,$16,$28,$34,$32,$35,$3a,$39,$2a,$37,$0e,$00,$ff

human_score:
        defb    $00
computer_score:
        defb    $00
