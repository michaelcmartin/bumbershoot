        ;; Simple Z80 PSG Music Driver.
        ;; A song in this system is a series of records, where each record
        ;; begins with a byte for the number of frames this record lasts,
        ;; followed by two bytes to write to each voice. If a voice does
        ;; not get a new note, it is instead a single zero byte. (Since
        ;; latching the pitch register requires setting bit 7, there will
        ;; never be any conflict between these forms.
        ;; When a zero byte is reached for a record length, the playback
        ;; loops back to the "segno" label.
        ;;
        ;; Notes that are played have their volume decay one tick every
        ;; other frame until they are silent.
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
        push    de
        push    hl
        ld      de, psg
        ld      hl, wait
        dec     (hl)
        jr      nz, decay
        ld      hl, (ptr)
        ld      a, (hl)
        and     a
        jr      nz, nolp
        ld      hl, segno
        ld      a, (hl)
nolp:   ld      (wait), a
        inc     hl
        ld      a, (hl)
        inc     hl
        and     a
        jr      z, v2
        ;; Voice 1
        ld      (de), a
        ld      a, (hl)
        inc     hl
        ld      (de), a
        ld      a, 7
        ld      (vol),a
        ;; Voice 2
v2:     ld      a, (hl)
        inc     hl
        and     a
        jr      z, v3
        ld      (de), a
        ld      a, (hl)
        inc     hl
        ld      (de), a
        ld      a, 7
        ld      (vol+1), a
        ;; Voice 3
v3:     ld      a, (hl)
        inc     hl
        and     a
        jr      z, vdone
        ld      (de), a
        ld      a, (hl)
        inc     hl
        ld      (de), a
        ld      a, 7
        ld      (vol+2), a
vdone:  ld      (ptr), hl
decay:  ld      a, (vol)
        cp      a, $1f
        jr      z, nodec1
        inc     a
        ld      (vol), a
nodec1: srl     a
        or      $90
        ld      (de), a
        ld      a, (vol+1)
        cp      a, $1f
        jr      z, nodec2
        inc     a
        ld      (vol+1), a
nodec2: srl     a
        or      $b0
        ld      (de), a
        ld      a, (vol+2)
        cp      a, $1f
        jr      z, nodec3
        inc     a
        ld      (vol+2), a
nodec3: srl     a
        or      $d0
        ld      (de), a

        pop     hl
        pop     de
        pop     af
        ei
        reti

        ;; A Chiptune rendition of the Nyancat song, itself adapted from
        ;; Vincent Johnson's arrangement, as seen improvised upon by Tom
        ;; Brier here: https://www.youtube.com/watch?v=dIivJwz5jL8
song:   defb    $07,$00,$a5,$05,$00,$07,$00,$a0,$05,$00,$0e,$00,$a7,$04,$00,$0e
        defb    $00,$a5,$03,$00,$07,$00,$a5,$05,$00,$07,$00,$a0,$05,$00,$07,$00
        defb    $a7,$04,$00,$07,$00,$a5,$03,$00,$07,$00,$a0,$03,$00,$07,$00,$aa
        defb    $02,$00,$07,$00,$a0,$03,$00,$07,$00,$a9,$03,$00,$0e,$00,$a5,$03
        defb    $00,$0e,$00,$a7,$04,$00,$07,$00,$a5,$05,$00,$07,$00,$a0,$05,$00
        defb    $0e,$00,$a7,$04,$00,$0e,$00,$a5,$03,$00,$07,$00,$a0,$03,$00,$07
        defb    $00,$a9,$03,$00,$07,$00,$a5,$03,$00,$07,$00,$a0,$03,$00,$07,$00
        defb    $a8,$02,$00,$07,$00,$aa,$02,$00,$07,$00,$a8,$02,$00,$07,$00,$a0
        defb    $03,$00
segno:  defb    $0e,$8f,$08,$a1,$28,$cd,$1f,$0e,$8f,$07,$ae,$0f,$c0,$14,$07,$8a
        defb    $0a,$ab,$23,$00,$07,$8a,$0a,$00,$00,$07,$00,$ad,$11,$cd,$17,$07
        defb    $86,$0d,$00,$00,$07,$84,$0b,$a7,$35,$00,$07,$8e,$0b,$00,$00,$0e
        defb    $86,$0d,$ae,$0f,$c8,$16,$0e,$86,$0d,$ad,$1f,$00,$0e,$8e,$0b,$ae
        defb    $0f,$cd,$11,$0e,$84,$0b,$aa,$2f,$cd,$25,$07,$84,$0b,$a0,$14,$cc
        defb    $1a,$07,$8e,$0b,$00,$00,$07,$86,$0d,$ab,$23,$c1,$28,$07,$8e,$0b
        defb    $00,$00,$07,$8a,$0a,$ad,$11,$c0,$14,$07,$8f,$08,$00,$00,$07,$8f
        defb    $07,$a7,$35,$00,$07,$8a,$0a,$00,$00,$07,$8f,$08,$ad,$11,$c3,$15
        defb    $07,$8e,$0b,$00,$00,$07,$8a,$0a,$a7,$2a,$00,$07,$86,$0d,$00,$00
        defb    $07,$8e,$0b,$a0,$0f,$c3,$15,$07,$86,$0d,$00,$00,$0e,$8a,$0a,$a1
        defb    $28,$cd,$1f,$0e,$8f,$08,$ae,$0f,$c0,$14,$07,$8f,$07,$ab,$23,$00
        defb    $07,$8a,$0a,$00,$00,$07,$8f,$08,$ad,$11,$cd,$17,$07,$8e,$0b,$00
        defb    $00,$07,$8a,$0a,$a7,$35,$00,$07,$86,$0d,$00,$00,$07,$84,$0b,$ae
        defb    $0f,$c8,$16,$07,$8a,$0a,$00,$00,$07,$84,$0b,$ad,$1f,$00,$07,$8e
        defb    $0b,$00,$00,$07,$86,$0d,$ae,$0f,$cd,$11,$07,$8e,$0b,$00,$00,$0e
        defb    $84,$0b,$aa,$2f,$cd,$25,$07,$86,$0d,$a0,$14,$cc,$1a,$07,$8e,$0b
        defb    $00,$00,$07,$8a,$0a,$ab,$23,$c0,$14,$07,$8f,$08,$00,$00,$07,$8e
        defb    $0b,$ad,$11,$c0,$14,$07,$8a,$0a,$00,$00,$07,$8e,$0b,$a7,$35,$c7
        defb    $2a,$07,$86,$0d,$00,$00,$0e,$8e,$0b,$aa,$2f,$c1,$28,$0e,$86,$0d
        defb    $af,$2c,$cd,$25,$0e,$8e,$0b,$a7,$2a,$cb,$23,$0e,$8f,$08,$a1,$28
        defb    $cd,$1f,$0e,$8f,$07,$ae,$0f,$c0,$14,$07,$8a,$0a,$ab,$23,$00,$07
        defb    $8a,$0a,$00,$00,$07,$00,$ad,$11,$cd,$17,$07,$86,$0d,$00,$00,$07
        defb    $84,$0b,$a7,$35,$00,$07,$8e,$0b,$00,$00,$0e,$86,$0d,$ae,$0f,$c8
        defb    $16,$0e,$86,$0d,$ad,$1f,$00,$0e,$8e,$0b,$ae,$0f,$cd,$11,$0e,$84
        defb    $0b,$aa,$2f,$cd,$25,$07,$84,$0b,$a0,$14,$cc,$1a,$07,$8e,$0b,$00
        defb    $00,$07,$86,$0d,$ab,$23,$c1,$28,$07,$8e,$0b,$00,$00,$07,$8a,$0a
        defb    $ad,$11,$c0,$14,$07,$8f,$08,$00,$00,$07,$8f,$07,$a7,$35,$00,$07
        defb    $8a,$0a,$00,$00,$07,$8f,$08,$ad,$11,$c3,$15,$07,$8e,$0b,$00,$00
        defb    $07,$8a,$0a,$a7,$2a,$00,$07,$86,$0d,$00,$00,$07,$8e,$0b,$a0,$0f
        defb    $c3,$15,$07,$86,$0d,$00,$00,$0e,$8a,$0a,$a1,$28,$cd,$1f,$0e,$8f
        defb    $08,$ae,$0f,$c0,$14,$07,$8f,$07,$ab,$23,$00,$07,$8a,$0a,$00,$00
        defb    $07,$8f,$08,$ad,$11,$cd,$17,$07,$8e,$0b,$00,$00,$07,$8a,$0a,$a7
        defb    $35,$00,$07,$86,$0d,$00,$00,$07,$84,$0b,$ae,$0f,$c8,$16,$07,$8a
        defb    $0a,$00,$00,$07,$84,$0b,$ad,$1f,$00,$07,$8e,$0b,$00,$00,$07,$86
        defb    $0d,$ae,$0f,$cd,$11,$07,$8e,$0b,$00,$00,$0e,$84,$0b,$aa,$2f,$cd
        defb    $25,$07,$86,$0d,$a0,$14,$cc,$1a,$07,$8e,$0b,$00,$00,$07,$8a,$0a
        defb    $ab,$23,$c0,$14,$07,$8f,$08,$00,$00,$07,$8e,$0b,$ad,$11,$c0,$14
        defb    $07,$8a,$0a,$00,$00,$07,$8e,$0b,$a7,$35,$c7,$2a,$07,$86,$0d,$00
        defb    $00,$0e,$8e,$0b,$aa,$2f,$c1,$28,$0e,$86,$0d,$af,$2c,$cd,$25,$0e
        defb    $8e,$0b,$a7,$2a,$cb,$23,$0e,$86,$0d,$a1,$28,$cd,$1f,$07,$8d,$11
        defb    $ae,$0f,$c0,$14,$07,$8e,$0f,$00,$00,$0e,$86,$0d,$a7,$35,$00,$07
        defb    $8d,$11,$ae,$0f,$c0,$14,$07,$8e,$0f,$00,$00,$07,$86,$0d,$a7,$2a
        defb    $00,$07,$8e,$0b,$00,$00,$07,$8a,$0a,$ad,$11,$c0,$14,$07,$86,$0d
        defb    $00,$00,$07,$80,$0a,$ad,$1f,$00,$07,$8a,$0a,$00,$00,$07,$80,$0a
        defb    $ad,$11,$c0,$14,$07,$8f,$08,$00,$00,$0e,$86,$0d,$aa,$2f,$c1,$28
        defb    $0e,$86,$0d,$ae,$0f,$c0,$14,$07,$8d,$11,$ad,$1f,$00,$07,$8e,$0f
        defb    $00,$00,$07,$86,$0d,$ae,$0f,$c0,$14,$07,$8d,$11,$00,$00,$07,$80
        defb    $0a,$a7,$35,$c7,$2a,$07,$8a,$0a,$00,$00,$07,$8e,$0b,$ad,$11,$c3
        defb    $15,$07,$86,$0d,$00,$00,$07,$8d,$11,$a7,$2a,$cb,$23,$07,$83,$15
        defb    $00,$00,$07,$80,$14,$ad,$11,$cc,$1a,$07,$8d,$11,$00,$00,$0e,$86
        defb    $0d,$a1,$28,$cd,$1f,$07,$8d,$11,$ae,$0f,$c0,$14,$07,$8e,$0f,$00
        defb    $00,$0e,$86,$0d,$a7,$35,$00,$07,$8d,$11,$ae,$0f,$c0,$14,$07,$8e
        defb    $0f,$00,$00,$07,$86,$0d,$a7,$2a,$00,$07,$86,$0d,$00,$00,$07,$8e
        defb    $0b,$ad,$11,$c3,$15,$07,$8a,$0a,$00,$00,$07,$86,$0d,$ad,$1f,$00
        defb    $07,$8d,$11,$00,$00,$07,$8e,$0f,$ad,$11,$c3,$15,$07,$8d,$11,$00
        defb    $00,$0e,$86,$0d,$aa,$2f,$c1,$28,$07,$86,$0d,$ae,$0f,$c0,$14,$07
        defb    $83,$0e,$00,$00,$07,$86,$0d,$ad,$1f,$00,$07,$8d,$11,$00,$00,$07
        defb    $8e,$0f,$ae,$0f,$c0,$14,$07,$86,$0d,$00,$00,$07,$80,$0a,$a7,$35
        defb    $c7,$2a,$07,$8a,$0a,$00,$00,$07,$80,$0a,$aa,$2f,$c1,$28,$07,$8f
        defb    $08,$00,$00,$0e,$86,$0d,$a7,$2a,$cb,$23,$0e,$83,$0e,$a7,$2a,$cb
        defb    $21,$0e,$86,$0d,$a1,$28,$cd,$1f,$07,$8d,$11,$ae,$0f,$c0,$14,$07
        defb    $8e,$0f,$00,$00,$0e,$86,$0d,$a7,$35,$00,$07,$8d,$11,$ae,$0f,$c0
        defb    $14,$07,$8e,$0f,$00,$00,$07,$86,$0d,$a7,$2a,$00,$07,$8e,$0b,$00
        defb    $00,$07,$8a,$0a,$ad,$11,$c0,$14,$07,$86,$0d,$00,$00,$07,$80,$0a
        defb    $ad,$1f,$00,$07,$8a,$0a,$00,$00,$07,$80,$0a,$ad,$11,$c0,$14,$07
        defb    $8f,$08,$00,$00,$0e,$86,$0d,$aa,$2f,$c1,$28,$0e,$86,$0d,$ae,$0f
        defb    $c0,$14,$07,$8d,$11,$ad,$1f,$00,$07,$8e,$0f,$00,$00,$07,$86,$0d
        defb    $ae,$0f,$c0,$14,$07,$8d,$11,$00,$00,$07,$80,$0a,$a7,$35,$c7,$2a
        defb    $07,$8a,$0a,$00,$00,$07,$8e,$0b,$ad,$11,$c3,$15,$07,$86,$0d,$00
        defb    $00,$07,$8d,$11,$a7,$2a,$cb,$23,$07,$83,$15,$00,$00,$07,$80,$14
        defb    $ad,$11,$cc,$1a,$07,$8d,$11,$00,$00,$0e,$86,$0d,$a1,$28,$cd,$1f
        defb    $07,$8d,$11,$ae,$0f,$c0,$14,$07,$8e,$0f,$00,$00,$0e,$86,$0d,$a7
        defb    $35,$00,$07,$8d,$11,$ae,$0f,$c0,$14,$07,$8e,$0f,$00,$00,$07,$86
        defb    $0d,$a7,$2a,$00,$07,$86,$0d,$00,$00,$07,$8e,$0b,$ad,$11,$c3,$15
        defb    $07,$8a,$0a,$00,$00,$07,$86,$0d,$ad,$1f,$00,$07,$8d,$11,$00,$00
        defb    $07,$8e,$0f,$ad,$11,$c3,$15,$07,$8d,$11,$00,$00,$0e,$86,$0d,$aa
        defb    $2f,$c1,$28,$07,$86,$0d,$ae,$0f,$c0,$14,$07,$83,$0e,$00,$00,$07
        defb    $86,$0d,$ad,$1f,$00,$07,$8d,$11,$00,$00,$07,$8e,$0f,$ae,$0f,$c0
        defb    $14,$07,$86,$0d,$00,$00,$07,$80,$0a,$a7,$35,$c7,$2a,$07,$8a,$0a
        defb    $00,$00,$07,$80,$0a,$aa,$2f,$c1,$28,$07,$8f,$08,$00,$00,$0e,$86
        defb    $0d,$af,$2c,$cd,$25,$0e,$8e,$0b,$a7,$2a,$cb,$23,$00
