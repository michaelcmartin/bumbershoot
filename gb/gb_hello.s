        SECTION "DATA",ROM0
fontbase:
        db      $00,$3c,$4e,$4e,$7e,$4e,$4e,$00
        db      $00,$7c,$66,$7c,$66,$66,$7c,$00
        db      $00,$7e,$60,$7c,$60,$60,$7e,$00
        db      $00,$7e,$60,$60,$7c,$60,$60,$00
        db      $00,$46,$46,$7e,$46,$46,$46,$00
        db      $00,$60,$60,$60,$60,$60,$7e,$00
        db      $00,$46,$6e,$7e,$56,$46,$46,$00
        db      $00,$3c,$66,$66,$66,$66,$3c,$00
        db      $00,$7c,$66,$66,$7c,$68,$66,$00
        db      $00,$3c,$60,$3c,$0e,$4e,$3c,$00
        db      $00,$7e,$18,$18,$18,$18,$18,$00
        db      $00,$46,$46,$46,$46,$4e,$3c,$00
        db      $00,$46,$46,$56,$7e,$6e,$46,$00
        def fontsize EQU (@-fontbase)

        SECTION "MAIN",ROM0
program_start:
        ;; Wait for not-VBLANK
        ld      a, [$ff41]      ; LCD status
        and     3
        cp      1
        jr      z, program_start
        ;; then wait for VBLANK
.vblp:  ld      a, [$ff41]
        and     3
        cp      1
        jr      nz, .vblp
        ;; Shut off display
        xor     a,a
        ld      [$ff40],a
        ;; Load font into BG Tile array
        ld      bc, fontsize
        ld      de, fontbase
        ld      hl, $8010
.ldlp:  ld      a, [de]
        inc     de
        ld      [hl+], a
        ld      [hl+], a
        dec     bc
        ld      a, b
        and     a
        jr      nz, .ldlp
        ld      a, c
        and     a
        jr      nz, .ldlp

        ;; Clear the tile RAM. A,B,C are already 0 here.
        ld      b, 4
        ld      hl, $9800
.clrlp: ld      [hl+], a
        dec     c
        jr      nz, .clrlp
        dec     b
        jr      nz, .clrlp

        ;; Load our message in as lines 8 and 10.
        ld      hl, $9800 + 8*32
        ld      de, msg
        ld      c, 20
m1lp:   ld      a, [de]
        ld      [hl+], a
        inc     de
        dec     c
        jr      nz, m1lp
        ld      c, 20
        ld      hl, $9800 + 10*32
m2lp:   ld      a, [de]
        ld      [hl+], a
        inc     de
        dec     c
        jr      nz, m2lp

        ;; Position the scroll point at (0, 4) to center the message.
        ld      a, 4
        ld      [$ff42], a
        xor     a
        ld      [$ff43], a

        ;; Re-enable display
        ld      a, $91
        ld      [$ff40], a

        ;; Go into low-power mode.
endlp:  halt
        jr      endlp

msg:    db      0,0,0,0,0,5,3,6,6,8,0,4,9,8,7,0,0,0,0,0
        db      2,12,7,2,3,9,10,5,8,8,11,0,10,8,4,11,13,1,9,3

        SECTION "HANDLERS",ROM0
rst_00:
rst_08:
rst_10:
rst_18:
rst_20:
rst_28:
rst_30:
rst_38:
        ret

int_vblank:
int_lcd_stat:
int_timer:
int_serial:
int_joypad:
        reti

        SECTION "Restarts",ROM0[$0000]

        jp      rst_00
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_08
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_10
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_18
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_20
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_28
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_30
        db      $ff,$ff,$ff,$ff,$ff
        jp      rst_38
        db      $ff,$ff,$ff,$ff,$ff
        jp      int_vblank
        db      $ff,$ff,$ff,$ff,$ff
        jp      int_lcd_stat
        db      $ff,$ff,$ff,$ff,$ff
        jp      int_timer
        db      $ff,$ff,$ff,$ff,$ff
        jp      int_serial
        db      $ff,$ff,$ff,$ff,$ff
        jp      int_joypad
        db      $ff,$ff,$ff,$ff,$ff

        SECTION "Header",ROM0[$0100]
        ;; Initial start
        nop
        jp      program_start
        REPT    $4c
        db      0
        ENDR
