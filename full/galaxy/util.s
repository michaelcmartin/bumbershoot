        +define ~data, ~str_ptr, 2      ; String pointer for text display

kill_screen:
        lda     #$00
        sta     $2000
        sta     $2001
        bit     $2002
-:      bit     $2002
        bpl     -
        rts

graphics_reset:
        jsr     kill_screen
        jsr     clear_name_tables
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2005           ; Clear out VRAM pointers
        sta     $2005
        jsr     clear_sprite_ram
        lda     #>sprites
        sta     $4014
        rts

rest_screen:
        bit     $2002
-:      bit     $2002
        bpl     -
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2005           ; Clear out VRAM pointers
        sta     $2005
        lda     #%10000000
        sta     $2000
        lda     #%00011110
        sta     $2001
        rts

set_color:
        ldx     #$3F
        stx     $2006
        ldx     #$01
        stx     $2006
        sta     $2007
        rts

clear_sprite_ram:
        lda     #0
        ldx     #0
-:      sta     sprites,x
        dex
        bne     -
        rts

clear_name_tables:
        ;; Clear out the Name and Attribute Tables at $2400 and $2800
        ;; (Assumes horizontal mirroring)
        lda     #$24
        sta     $2006
        ldy     #$00
        sty     $2006
        ldx     #$08
        lda     #0
        ldy     #0
-:      sta     $2007
        iny
        bne     -
        dex
        bne     -
        rts

; Draws several null-terminated strings into VRAM.  Each string is preceded by
; the big-endian VRAM address to which it should be written.  A null starting
; this address ends the loop.  Str_Ptr[0-1] holds the little-endian CPU memory address
; of the start of the data.  The str_ptr pointer will point one byte past the null
; once the routine is finished.

draw_text:
        ldy     #0
-:      lda     (str_ptr),y
        beq     +
        sta     $2006
        jsr     inc_str_ptr
        lda     (str_ptr),y
        sta     $2006
        jsr     inc_str_ptr
        jsr     draw_string
        jmp     -
+:      jsr     inc_str_ptr
        rts

; Draws a null-terminated string into VRAM.  Str_Ptr(0-1) holds the little-endian
; CPU memory address of the string.  Set the VRAM pointer appropriately before
; calling this routine.  The str_ptr pointer will point one byte past the null
; once the routine is finished.

draw_string:
        ldy     #0
-:      lda     (str_ptr),y
        beq     +
        sta     $2007
        inc     str_ptr
        bne     -
        inc     str_ptr+1
        jmp     -
+:      jsr     inc_str_ptr
        rts

inc_str_ptr:
        inc     str_ptr
        bne     +
        inc     str_ptr+1
+:      rts
