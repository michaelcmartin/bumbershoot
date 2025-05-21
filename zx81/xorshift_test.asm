        org     $4090
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

        include "xorshift.asm"
