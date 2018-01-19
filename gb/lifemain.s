        ;; Most of this is throwaway
        SECTION "DATA",ROM0
fontbase:
        db      $00,$3C,$7E,$7E,$7E,$7E,$3C,$00
fontsize EQU (@-fontbase)

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
        ld      de,fontbase
        ld      hl,$8010
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

        ;; Re-enable display and enable the VBLANK interrupt.
        ld      a, $91
        ld      [$ff40], a
        ld      a, $01
        ld      [$ffff], a
        xor     a
        ldh     [last_input], a
        ei

endlp:  ld      hl, $9800
        call    life_blit
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
