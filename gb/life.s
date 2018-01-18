;;; life_init:   Clears the board. Zeroes ABC, trashes HL.
;;; life_glider: Draws a glider in the upper left. Does NOT clear the
;;;              board. Trashes A.
;;; life_step:   Executes a simulation step. Trashes all registers.
;;; life_blit:   Draws the simulation state to the screen starting at
;;;              HL. VBLANK interrupts must be enabled; this takes 4
;;;              frames to render.
        EXPORT  life_init
        EXPORT  life_glider
        EXPORT  life_step
        EXPORT  life_blit

        SECTION "LIFERAM",WRAM0
LS_W    EQU     20
LS_H    EQU     16
LN_W    EQU     (LS_W+2)
LN_H    EQU     (LS_H+2)

state:
        DS      (LS_W * LS_H)
neighbors:
        DS    (LN_W * LN_H)

        SECTION "LIFE",ROM0
life_init:
        xor     a
        ld      hl, state
        ld      b, LS_H
.lp1a:  ld      c, LS_W
.lp1b:  ld      [hl+], a
        dec     c
        jr      nz, .lp1b
        dec     b
        jr      nz, .lp1a
        ret

life_glider:
        ld      a, 1
        ld      [state+2], a
        ld      [state+LS_W],a
        ld      [state+2+LS_W],a
        ld      [state+1+2*LS_W],a
        ld      [state+2+2*LS_W],a
        ret

life_step:
        ;; Clear the neighbors array
        xor     a
        ld      hl, neighbors
        ld      b, LN_H
.lp1a:  ld      c, LN_W
.lp1b:  ld      [hl+], a
        dec     c
        jr      nz, .lp1b
        dec     b
        jr      nz, .lp1a
        ;; Now compute all neighbor values in the array
        ld      de, state
        ld      hl, neighbors + LN_W + 1
        ld      b, LS_H
.lp2a:  ld      c, LS_W
.lp2b:  ld      a, [de]
        and     a
        jr      z, .lp2c
        ;; This cell is live, so mark its neighbors
        push    bc
        push    hl
        dec     hl
        inc     [hl]
        ld      bc, -LN_W
        add     hl, bc
        inc     [hl]
        inc     hl
        inc     [hl]
        inc     hl
        inc     [hl]
        pop     hl
        push    hl
        inc     hl
        inc     [hl]
        ld      bc, LN_W
        add     hl, bc
        inc     [hl]
        dec     hl
        inc     [hl]
        dec     hl
        inc     [hl]
        pop     hl
        pop     bc
        ;; Now update pointers for the next iteration
.lp2c:  inc     de
        inc     hl
        dec     c
        jr      nz, .lp2b
        inc     hl
        inc     hl
        dec     b
        jr      nz, .lp2a
        ;; Merge over the corners
        ld      a, [neighbors+LN_W*LN_H-1]
        ld      b, a
        ld      a, [neighbors+LN_W*(LN_H-1)]
        ld      c, a
        ld      a, [neighbors+LN_W-1]
        ld      d, a
        ld      a, [neighbors]
        ld      e, a
        ld      a, [neighbors+LN_W+1]
        add     b
        ld      [neighbors+LN_W+1], a
        ld      a, [neighbors+2*LN_W-2]
        add     c
        ld      [neighbors+2*LN_W-2], a
        ld      a, [neighbors+LN_W*(LN_H-2)+1]
        add     d
        ld      [neighbors+LN_W*(LN_H-2)+1], a
        ld      a, [neighbors+LN_W*(LN_H-1)-2]
        add     e
        ld      [neighbors+LN_W*(LN_H-1)-2], a
        ;; Correct top entries
        ld      de, neighbors+LN_W+1
        ld      hl, neighbors+LN_W*(LN_H-1)+1
        ld      b, LS_W
.lp3:   ld      a, [hl+]
        ld      c, a
        ld      a, [de]
        add     c
        ld      [de], a
        inc     de
        dec     b
        jr      nz, .lp3
        ;; Correct bottom entries
        ld      de, neighbors+LN_W*(LN_H-2)+1
        ld      hl, neighbors+1
        ld      b, LS_W
.lp4:   ld      a, [hl+]
        ld      c, a
        ld      a, [de]
        add     c
        ld      [de], a
        inc     de
        dec     b
        jr      nz, .lp4
        ;; Correct left and right entries
        ld      de, neighbors+LN_W+1
        ld      hl, neighbors+LN_W*2-1
        ld      b, LS_H
.lp5:   ld      a, [de]
        add     a, [hl]
        ld      [de], a
        dec     de
        dec     hl
        ld      a, [de]
        add     a, [hl]
        ld      [hl], a
        ld      a, 23
        add     a, e
        ld      e, a
        ld      a, 0
        adc     a, d
        ld      d, a
        ld      a, 23
        add     a, l
        ld      l, a
        ld      a, 0
        adc     a, h
        ld      h, a
        dec     b
        jr      nz, .lp5
        ;; Finally, compute new state from current state and neighbors
        ;; matrix
        ld      de, state
        ld      hl, neighbors+LN_W+1
        ld      b, LS_H
.lp6a:  ld      c, LS_W
.lp6b:  ld      a, [hl+]
        sub     a, 3
        jr      nz, .nobrn
        inc     a
        ld      [de], a
        jr      .lp6c
.nobrn: inc     a
        jr      z, .lp6c
        xor     a
        ld      [de], a
.lp6c:  inc     de
        dec     c
        jr      nz, .lp6b
        inc     hl
        inc     hl
        dec     b
        jr      nz, .lp6a
        ret

        SECTION "BLITRAM", HRAM
blit_phase:     ds 1

        SECTION "BLIT", ROM0
life_blit:
        ld      a, LS_H/4       ; Only 4 lines can be blitted per frame
        ld      de, state
.frame: ldh     [blit_phase], a
        ld      b, 4
        halt
.lp0a:  ld      c, LS_W
.lp0b:  ld      a, [de]
        ld      [hl+], a
        inc     de
        dec     c
        jr      nz, .lp0b
        ld      a, 32-LS_W
        add     l
        ld      l, a
        ld      a, 0            ; Cant use "xor a" because that trashes carry
        adc     a, h
        ld      h, a
        dec     b
        jr      nz, .lp0a
        ldh     a, [blit_phase]
        dec     a
        jr      nz, .frame
        ret
