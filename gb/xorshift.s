;;; rnd_init: Resets the PRNG seed. Trashes the accumulator but nothing else.
;;; rnd:      Returns the next random number in HL. Trashes all registers.
        EXPORT  rnd
        EXPORT  rnd_init

        SECTION "rnd_vars", HRAM
rnd_x   DS      2
rnd_y   DS      2

        SECTION "rnd", ROM0
rnd_init:
        ld      a, $3f
        ldh     [rnd_x], a
        ld      a, $5a
        ldh     [rnd_x+1], a
        ld      a, $77
        ldh     [rnd_y], a
        ld      a, $8e
        ldh     [rnd_y+1], a
        ret

        ;; XORSHIFT RND routine follows
        ;; t = x ^ (x << 5) [t = DE]
rnd:    ldh     a, [rnd_x+1]
        ld      d, a
        ldh     a, [rnd_x]
        ld      e, a
        ld      c, d
        ld      b, 5
rnd_0:  sla     a
        rl      d
        dec     b
        jr      nz, rnd_0
        xor     a, e
        ld      e, a
        ld      a, c
        xor     a, d
        ld      d, a
        ;; t = t ^ (t >>> 3) [t = DE]  [A is already D]
        ld      c, e
        ld      b, 3
rnd_1:  srl     a
        rr      e
        dec     b
        jr      nz, rnd_1
        xor     a, d
        ld      d, a
        ld      a, c
        xor     a, e
        ld      e, a
        ;; x = y [t = DY, y = HL]
        ldh     a, [rnd_y]
        ld      l, a
        ldh     [rnd_x], a
        ldh     a, [rnd_y+1]
        ld      h, a
        ldh     [rnd_x+1], a
        ;; y = y ^ (y >>> 1) ^ t [t = DE, y = HL]
        ld      a, h
        ld      c, l
        srl     a
        rr      l
        xor     a, h
        xor     a, d
        ld      h, a
        ld      a, l
        xor     a, c
        xor     a, e
        ld      l, a
        ;; Store out y
        ldh     [rnd_y], a
        ld      a, h
        ldh     [rnd_y+1], a
        ;; return y (still in HL)
        ret
