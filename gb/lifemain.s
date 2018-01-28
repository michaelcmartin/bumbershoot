        ;; Most of this is throwaway
        SECTION "DATA",ROM0
fontbase:
        db      $00,$3C,$7E,$7E,$7E,$7E,$3C,$00 ; Live cell
        db      $00,$00,$00,$FF,$FF,$00,$00,$00 ; W-E
        db      $00,$00,$00,$1F,$1F,$18,$18,$18 ; NW
        db      $00,$00,$00,$F8,$F8,$18,$18,$18 ; NE
        db      $18,$18,$18,$1F,$1F,$00,$00,$00 ; SW
        db      $18,$18,$18,$F8,$F8,$00,$00,$00 ; SE
        db      $00,$3C,$4E,$4E,$7E,$4E,$4E,$00 ; A
        db      $00,$7E,$60,$7C,$60,$60,$7E,$00 ; E
        db      $00,$7E,$60,$60,$7C,$60,$60,$00 ; F
        db      $00,$3C,$66,$60,$6E,$66,$3E,$00 ; G
        db      $00,$3C,$18,$18,$18,$18,$3C,$00 ; I
        db      $00,$60,$60,$60,$60,$60,$7E,$00 ; L
        db      $00,$46,$6E,$7E,$56,$46,$46,$00 ; M
        db      $00,$3C,$66,$66,$66,$66,$3C,$00 ; O
fontsize EQU (@-fontbase)

winmsg: db      3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,4
        db      0,0,0,0,0,0,0,0,0,0,0,0
        db      5,2,2,0,10,7,13,8,0,14,9,0,12,11,9,8,0,2,2,6

        SECTION "MAIN",ROM0
        EXPORT  program_start
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
        ldi     [hl], a
        ldi     [hl], a
        dec     bc
        ld      a, b
        and     a
        jr      nz, .ldlp
        ld      a, c
        and     a
        jr      nz, .ldlp

        ;; Create initial conditions
        call    rnd_init
        call    life_init
        call    life_glider
        call    life_blit_init
        call    window_init

        ;; Re-enable display and enable the VBLANK interrupt.
        ld      a, $f1
        ld      [$ff40], a
        ld      a, $01
        ld      [$ffff], a
        xor     a
        ldh     [last_input], a
        ei

endlp:  ld      b, 4
render: halt
        push    bc
        call    life_blit
        pop     bc
        dec     b
        jr      nz, render

        call    life_step

        ld      b, 8
delay:  halt
        push    bc
        call    check_input
        bit     0, a
        jr      z, .noa
        call    life_scramble
.noa:   bit     1, a
        jr      z, .nob
        call    life_glider
.nob:   bit     3, a
        jr      z, .nost
        call    life_init
.nost:  call    rnd
        pop     bc
        dec     b
        jr      nz, delay

        jr      endlp

        SECTION "HANDLERS",ROM0
        EXPORT rst_00
        EXPORT rst_08
        EXPORT rst_10
        EXPORT rst_18
        EXPORT rst_10
        EXPORT rst_18
        EXPORT rst_20
        EXPORT rst_28
        EXPORT rst_30
        EXPORT rst_38
        EXPORT int_vblank
        EXPORT int_lcd_stat
        EXPORT int_timer
        EXPORT int_serial
        EXPORT int_joypad
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
        push    af
        ldh     a, [life_blit_scroll]
        ldh     [$ff42], a
        pop     af
int_lcd_stat:
int_timer:
int_serial:
int_joypad:
        reti

        SECTION "MAINRAM", HRAM
last_input:     ds 1

        SECTION "INPUT", ROM0
check_input:
        push    bc
        ld      a, $df
        ldh     [$ff00], a
        ld      b, 8
.l1:    ldh     a, [$ff00]
        dec     b
        jr      nz, .l1
        xor     $ff
        ld      b, a
        ldh     a, [last_input]
        xor     $ff
        and     b
        ld      c, a
        ld      a, b
        ldh     [last_input], a
        ld      a, c
        pop     bc
        ret

        SECTION "WINDOW", ROM0
window_init:
        ld      de, $9c00
        ld      hl, winmsg
        ld      b, 52
.l1:    ld      a, [hl+]
        ld      [de], a
        inc     de
        dec     b
        jr      nz, .l1
        ld      a, $80
        ld      [$ff4a], a
        ld      a, $07
        ld      [$ff4b], a
        ret
