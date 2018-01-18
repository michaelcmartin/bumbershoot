        ;; Housekeeping
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
