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
        cp      0x1f
        jr      z, nodec1
        inc     a
        ld      (vol), a
nodec1: srl     a
        or      0x90
        ld      (de), a
        ld      a, (vol+1)
        cp      0x1f
        jr      z, nodec2
        inc     a
        ld      (vol+1), a
nodec2: srl     a
        or      0xb0
        ld      (de), a
        ld      a, (vol+2)
        cp      0x1f
        jr      z, nodec3
        inc     a
        ld      (vol+2), a
nodec3: srl     a
        or      0xd0
        ld      (de), a

        pop     hl
        pop     de
        pop     af
        ei
        reti

song:   incbin  "res/nyansong.bin"
segno   equ     song+130
