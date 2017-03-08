        ld      bc, msg
lp:     ld      a, (bc)
        cp      a, $ff
        ret     z
        push    bc
        sub     27
        rst     $10
        pop     bc
        inc     bc
        jr      lp

msg:    defb    "HELLO",27,"FROM",27,"THE",27,"ZX?8",27,"WORLD6",145,255
