        ;; Z80 PSG Sound Driver test.
        org     0
        defc    psg=$7f11

rst_0:  di
        im      1
        ld      sp, $2000
        ei
rst_lp: jr      rst_lp

        defs    $20-ASMPC

ptr:    defw    song
vol:    defb    $1f, $1f, $1f
wait:   defb    $01

        defs    $38-ASMPC

rst_38: push    af
        push    de
        push    hl
        ld      de, psg
        ld      hl, wait
        dec     (hl)
        jr      nz, decay
        ld      hl, (ptr)
        ld      a, (hl)
        and     a
        jr      nz, nolp
        ld      hl, song
        ld      a, (hl)
nolp:   ld      (wait), a
        inc     hl
        ld      a, (hl)
        inc     hl
        and     a
        jr      z, v2
        ;; Voice 1
        ld      (de), a
        ld      a, (hl)
        inc     hl
        ld      (de), a
        ld      a, 7
        ld      (vol),a
        ;; Voice 2
v2:     ld      a, (hl)
        inc     hl
        and     a
        jr      z, v3
        ld      (de), a
        ld      a, (hl)
        inc     hl
        ld      (de), a
        ld      a, 7
        ld      (vol+1), a
        ;; Voice 3
v3:     ld      a, (hl)
        inc     hl
        and     a
        jr      z, vdone
        ld      (de), a
        ld      a, (hl)
        inc     hl
        ld      (de), a
        ld      a, 7
        ld      (vol+2), a
vdone:  ld      (ptr), hl
decay:  ld      a, (vol)
        cp      a, $1f
        jr      z, nodec1
        inc     a
        ld      (vol), a
nodec1: srl     a
        or      $90
        ld      (de), a
        ld      a, (vol+1)
        cp      a, $1f
        jr      z, nodec2
        inc     a
        ld      (vol+1), a
nodec2: srl     a
        or      $b0
        ld      (de), a
        ld      a, (vol+2)
        cp      a, $1f
        jr      z, nodec3
        inc     a
        ld      (vol+2), a
nodec3: srl     a
        or      $d0
        ld      (de), a

        pop     hl
        pop     de
        pop     af
        ei
        ret

song:   defb    18,$8b,$1a,$00,$00
        defb    18,$00,$a3,$15,$00
        defb    18,$00,$00,$cd,$11
        defb    18,$85,$0d,$00,$00
        defb    72,$8b,$1a,$a3,$15,$cd,$11
        defb    0
