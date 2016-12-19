        +define ~data, ~game_vec, 2

reset:  sei
        cld

        ;; Wait two frames.
        bit     $2002
-:      bit     $2002
        bpl     -
-:      bit     $2002
        bpl     -

        ;; Mask out sound IRQs.
        lda     #$40
        sta     $4017

        ;; Disable all graphics.
        lda     #$00
        sta     $2000
        sta     $2001

        ;; Clear out RAM.
        lda     #$00
        tax
-:      sta     $000,x
        sta     $100,x
        sta     $200,x
        sta     $300,x
        sta     $400,x
        sta     $500,x
        sta     $600,x
        sta     $700,x
        inx
        bne     -

        ;; Reset the stack pointer.
        dex
        txs

        ;; Clear out SPR-RAM.
        lda     #$02
        sta     $4014

        jsr     clear_name_tables
        cli

        jsr     random_seed
        lda     #<prep_title
        sta     game_vec
        lda     #>prep_title
        sta     game_vec+1

        jsr     rest_screen
hang:   jmp     hang

vblank: jmp     (game_vec)
