        ;; Simple Z80 FM Music Driver.
        ;; A song in this system is a series of records, where each record
        ;; begins with a byte for the number of frames this record lasts,
        ;; followed by a byte for the number of register writes to the first
        ;; block of FM registers, followed by that many pairs of (register,
        ;; value) bytes.
        ;; When a zero byte is reached for a record length, the playback
        ;; loops back to the "segno" label.
        org     0
psg     equ     0x7f11

rst_0:  di
        im      1
        ld      sp, 0x2000
        ei
rst_lp: jr      rst_lp

        defs    0x20-$,0

ptr:    defw    song
vol:    defb    0x1f, 0x1f, 0x1f
wait:   defb    0x01

        defs    0x38-$,0

rst_38: push    af
        push    bc
        push    ix
        push    hl
        ld      hl, wait
        dec     (hl)
        jr      nz, idone
        ld      ix, 0x4000
        ld      hl, (ptr)
        ld      a, (hl)
        and     a
        jr      nz, nolp
        ld      hl, segno
        ld      a, (hl)
nolp:   ld      (wait), a
        inc     hl
        ld      b, (hl)
        inc     hl
rlp:    ld      a, (hl)
        ld      (ix+0), a
        inc     hl
        ld      a, (hl)
        inc     hl
        ld      (ix+1), a
        djnz    rlp
        ld      (ptr), hl
        ;; The video interrupt is held for 64 microseconds. To make sure we
        ;; don't end up double-dipping, spin for a bit before returning.
idone:  ld      b, 64
ilp:    djnz    ilp
        pop     hl
        pop     ix
        pop     bc
        pop     af
        ei
        reti

song:
segno:  
        incbin  "res/bachsong.bin"
