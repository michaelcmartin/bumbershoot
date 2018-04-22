        ;; Simple Z80 FM Music Driver.
        ;; A song in this system is a series of records, where each record
        ;; begins with a byte for the number of frames this record lasts,
        ;; followed by a byte for the number of register writes to the first
        ;; block of FM registers, followed by that many pairs of (register,
        ;; value) bytes.
        ;; When a zero byte is reached for a record length, the playback
        ;; loops back to the "segno" label.
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
        push    bc
        push    ix
        push    hl
        ld      hl, wait
        dec     (hl)
        jr      nz, idone
        ld      ix, $4000
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
idone:  pop     hl
        pop     ix
        pop     bc
        pop     af
        ei
        ret

        ;; Test song: C Major scale
song:
segno:  defb    $3C,$21,$30,$71,$34,$0D,$38,$33,$3C,$01
        defb    $40,$23,$44,$2D,$48,$26,$4C,$00,$50,$5F
        defb    $54,$99,$58,$5F,$5C,$94,$60,$05,$64,$05
        defb    $68,$05,$6C,$07,$70,$02,$74,$02,$78,$02
        defb    $7C,$02,$80,$11,$84,$11,$88,$11,$8C,$A6
        defb    $90,$00,$94,$00,$98,$00,$9C,$00,$B0,$32
        defb    $B4,$C0,$A4,$1D,$A0,$08,$28,$F0
        defb    $3C,$03,$A4,$1D,$A0,$A5,$28,$F0
        defb    $3C,$03,$A4,$1E,$A0,$56,$28,$F0
        defb    $3C,$03,$A4,$1E,$A0,$B7,$28,$F0
        defb    $3C,$03,$A4,$1F,$A0,$89,$28,$F0
        defb    $3C,$03,$A4,$24,$A0,$3B,$28,$F0
        defb    $3C,$03,$A4,$24,$A0,$BF,$28,$F0
        defb    $3C,$03,$A4,$25,$A0,$08,$28,$F0
        defb    $00
