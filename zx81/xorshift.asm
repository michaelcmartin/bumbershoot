        ;; First, reset the RNG seed
        ld      hl, 1
        ld      (rnd_x), hl
        ld      (rnd_y), hl
        ;; Then print out 64 numbers from it
        ld      b, 64
m_0:    push    bc
        call    rnd
        call    hexout_16
        xor     a, a
        rst     $10
        rst     $10
        rst     $10
        rst     $10
        pop     bc
        djnz    m_0
        ret

hexout_16:
        push    hl
        ld      a, h
        call    hexout_8
        pop     hl
        ld      a, l
        ;; Fall through
hexout_8:
        push    af
        rra
        rra
        rra
        rra
        call    hexout_4
        pop     af
        ;; Fall through
hexout_4:
        and     15
        add     28
        rst     $10
        ret

        ;; XORSHIFT RND routine follows
rnd_x:  defw    $0001
rnd_y:  defw    $0001
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
