        ;; Most of this is throwaway
        SECTION "DATA",ROM0
fontbase:
        db      $00,$3C,$7E,$7E,$7E,$7E,$3C,$00 ; Live cell
        db      $00,$00,$00,$FF,$FF,$00,$00,$00 ; Divider
        db      $00,$08,$10,$00,$00,$00,$00,$00 ; '
        db      $00,$00,$00,$00,$00,$00,$18,$30 ; ,
        db      $00,$3C,$66,$6A,$72,$62,$3C,$00 ; 0
        db      $00,$18,$38,$18,$18,$18,$7E,$00 ; 1
        db      $00,$3C,$66,$06,$3C,$60,$7E,$00 ; 2
        db      $00,$3C,$62,$3C,$62,$62,$3C,$00 ; 8
        db      $00,$3C,$62,$7E,$62,$62,$62,$00 ; A
        db      $00,$7C,$62,$7C,$62,$62,$7C,$00 ; B
        db      $00,$3C,$62,$60,$60,$62,$3C,$00 ; C
        db      $00,$7C,$62,$62,$62,$62,$7C,$00 ; D
        db      $00,$7E,$60,$7C,$60,$60,$7E,$00 ; E
        db      $00,$7E,$60,$7C,$60,$60,$60,$00 ; F
        db      $00,$3C,$62,$60,$66,$62,$3C,$00 ; G
        db      $00,$62,$62,$7E,$62,$62,$62,$00 ; H
        db      $00,$3C,$18,$18,$18,$18,$3C,$00 ; I
        db      $00,$60,$60,$60,$60,$60,$7E,$00 ; L
        db      $00,$62,$76,$6A,$62,$62,$62,$00 ; M
        db      $00,$62,$72,$6A,$66,$62,$62,$00 ; N
        db      $00,$3C,$62,$62,$62,$62,$3C,$00 ; O
        db      $00,$7C,$62,$7C,$60,$60,$60,$00 ; P
        db      $00,$7C,$66,$7C,$68,$64,$62,$00 ; R
        db      $00,$3C,$60,$3C,$02,$62,$3C,$00 ; S
        db      $00,$7E,$18,$18,$18,$18,$18,$00 ; T
        db      $00,$62,$62,$62,$62,$62,$3C,$00 ; U
        db      $00,$62,$62,$62,$62,$34,$18,$00 ; V
        db      $00,$62,$62,$62,$6A,$76,$62,$00 ; W
        db      $00,$62,$62,$3C,$18,$18,$18,$00 ; Y
fontsize EQU (@-fontbase)

winmsg: db      2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
        db      0,0,0,0,0,0,0,0,0,0,0,0
        db      0,0,0,0,15,9,19,13,0,21,14,0,18,17,14,13,0,0,0,0

        ;; Condition this out for now; this is the real message we'll
        ;; eventually be scrolling along
        IF 0
        db      11,21,20,28,9,29,3,24,0,15,9,19,13,0,21,14,0,18,17,14
        db      13,0,0,0,0,0,22,23,13,24,13,20,25,13,12,0,10,29,0,10
        db      26,19,10,13,23,24,16,21,21,25,0,24,21,14,25,28,9,23,13
        db      4,0,7,5,6,8,0,0,0,0,0,22,23,13,24,24,0,9,0,25,21,0,24
        db      11,23,9,19,10,18,13,0,10,21,9,23,12,0,0,0,0,0,22,23,13
        db      24,24,0,10,0,25,21,0,18,9,26,20,11,16,0,15,18,17,12,13
        db      23,0,0,0,0,0,22,23,13,24,24,0,24,25,9,23,25,0,25,21,0
        db      23,13,24,13,25,0,10,21,9,23,12,0,25,21,0,10,13,13,16
        db      17,27,13,0,22,9,25,25,13,23,20,0,0,0,0,0
        ENDC

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
        ld      b, fontsize
        ld      de, fontbase
        ld      hl, $8010
.ldlp:  ld      a, [de]
        inc     de
        ldi     [hl], a
        ldi     [hl], a
        dec     b
        jr      nz, .ldlp

        ;; Create initial conditions
        call    rnd_init
        call    life_init
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
