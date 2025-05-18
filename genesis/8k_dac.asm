        org     0

        di
        im      1
        ld      sp, 0x2000
        jr      main
counter:
        defw    0
ptr:    defb    0,0,0

main:   ld      hl, 0x4000

        ;; Set up YM2612
        ld      (hl), 0x22       ; Disable Low-Frequency Oscillator
        xor     a
        ld      (0x4001), a
        ld      (hl), 0x27       ; Disable independent Channel 3
        ld      (0x4001), a
        ld      b, 7
ymlp:   ld      (hl), 0x28       ; Key off all channels
        ld      (0x4001), a
        inc     a
        djnz    ymlp
        ld      (hl), 0x2b       ; Enable DAC
        ld      a, 0x80
        ld      (0x4001), a
        ld      a, 0xb6          ; Enable speakers for DAC
        ld      (0x4002), a
        ld      a, 0xc0
        ld      (0x4003), a

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
        or      0x80
        ld      d, a
        pop     af
        rlca
        ld      (0x6000), a
        ld      a, (ptr+2)
        ld      b, 8
ldlp:   ld      (0x6000), a
        rrca
        djnz    ldlp

        ;; Now play the sample itself
lp:     ld      b, 26
buzz:   djnz    buzz
        nop
        nop
        ld      (hl), 0x2a
        ld      a, (de)
        ld      (0x4001), a
        inc     de
        ld      bc, (counter)
        dec     bc
        ld      (counter), bc
        ld      a, b
        or      c
        jr      nz, lp

        jr      wait
