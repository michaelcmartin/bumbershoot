        ;; Z80 PSG Sound Driver test.
        ;; Manages a simple decay envelope while playing a C major scale.
        org     0
        defc    psg=$7f11

rst_0:  di
        im      1
        ld      sp, $2000
        ei
rst_lp: jr      rst_lp

        defs    $20-ASMPC

ptr:    defw    notes
vol:    defb    $1f
wait:   defb    $01

        defs    $38-ASMPC

rst_38: push    af
        push    hl
        ld      hl, wait
        dec     (hl)
        jr      nz, decay
        ld      hl, (ptr)
        ld      a, (hl)
        and     a
        jr      nz, nolp
        ld      hl, notes
        ld      a, (hl)
nolp:   or      $80
        ld      (psg), a
        inc     hl
        ld      a, (hl)
        ld      (psg), a
        inc     hl
        ld      (ptr), hl
        ld      a, 6
        ld      (vol), a
        ld      a, 36
        ld      (wait), a
decay:  ld      a, (vol)
        cp      a, $1f
        jr      z, nodec
        inc     a
        ld      (vol), a
nodec:  srl     a
        or      $90
        ld      (psg), a

done:   pop     hl
        pop     af
        ei
        ret

notes:  defb    $0b,$1a, $0c,$17, $03,$15, $80,$14
        defb    $0d,$11, $0e,$0f, $02,$0e, $05,$0d
        defb    $02,$0e, $0e,$0f, $0d,$11, $80,$14
        defb    $03,$15, $0c,$17, $00
