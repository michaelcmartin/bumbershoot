        org     0

        di
        im      1
        ld      sp, $2000
        jr      main
counter:
        defw    0
ptr:    defs    3

main:   ld      hl, $4000

        ;; Set up YM2612
        ld      (hl), $22       ; Disable Low-Frequency Oscillator
        xor     a
        ld      ($4001), a
        ld      (hl), $27       ; Disable independent Channel 3
        ld      ($4001), a
        ld      b, 7
ymlp:   ld      (hl), $28       ; Key off all channels
        ld      ($4001), a
        inc     a
        djnz    ymlp
        ld      (hl), $2b       ; Enable DAC
        ld      a, $80
        ld      ($4001), a
        ld      a, $b6          ; Enable speakers for DAC
        ld      ($4002), a
        ld      a, $c0
        ld      ($4003), a

wait:   ld      a, (counter)
        and     a
        jr      nz, go
        ld      a, (counter+1)
        and     a
        jr      z, wait

        ;; A sample has been selected. Bank in the appropriate ROM.
go:     ld      a, (ptr)
        ld      e, a
        ld      a, (ptr+1)
        push    af
        or      $80
        ld      d, a
        pop     af
        rlca
        ld      ($6000), a
        ld      a, (ptr+2)
        ld      b, 8
ldlp:   ld      ($6000), a
        rrca
        djnz    ldlp

        ;; Now play the sample itself
lp:     ld      b, 26
buzz:   djnz    buzz
        nop
        nop
        ld      (hl), $2a
        ld      a, (de)
        ld      ($4001), a
        inc     de
        ld      bc, (counter)
        dec     bc
        ld      (counter), bc
        ld      a, b
        or      c
        jr      nz, lp

        jr      wait
