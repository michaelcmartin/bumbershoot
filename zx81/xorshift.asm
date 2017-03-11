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
rnd:    ;; t = x ^ (x << 5)  [t = DE]
        defb    $11             ; LD DE, **
rnd_x:  defw    $0001
        ld      a, e
        ld      c, d
        ld      b, 5
rnd_0:  sla     a
        rl      d
        djnz    rnd_0
        xor     a, e
        ld      e, a
        ld      a, c
        xor     a, d
        ld      d, a
        ;; t ^= t >> 3  [t = DE]  [A is already D]
        ld      c, e
        ld      b, 3
rnd_1:  srl     a
        rr      e
        djnz    rnd_1
        xor     a, d
        ld      d, a
        ld      a, c
        xor     a, e
        ld      e, a
        ;; x = y        [t = DE, y = HL]
        defb    $21             ; LD HL, **
rnd_y:  defw    $0001
        ld      (rnd_x), hl
        ;; y ^= (y >> 1) ^ t [t = DE, y = HL]
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
        ld      (rnd_y), hl
        ;; return y (still in HL)
        ret
