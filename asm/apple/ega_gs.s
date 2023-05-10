;;; ----------------------------------------------------------------------
;;;   EGA demo screen for the Apple IIgs
;;;   Build with this command:
;;;      ca65 ega_gs.s && ld65 -t none -o EGA.GRID#ff2000 ega_gs.o
;;; ----------------------------------------------------------------------
        .p816
        .a16
        .i16
        .org    $2000

        ;; Initial setup
        clc                     ; Leave emulation mode
        xce
        rep     #$30            ; 16-bit everything during startup
        tsx                     ; Extract 6502 stack pointer
        lda     #$0fff          ; Reassign stack to pages 09-0F
        tcs
        phx                     ; Save 6502 stack at top of new stack
        phd                     ; Save original direct page
        phb                     ; and data bank
        lda     #$0800          ; Change direct page to $0800
        tcd

        ;; Load 9 palettes, set data bank to #$E1
        lda     #$011f
        ldx     #palettes
        ldy     #$9e00
        mvn     #$00,#$e1

        ;; Clear the screen
        stz     $2000
        lda     #$7cfe
        ldx     #$2000
        txy
        iny
        mvn     #$e1,#$e1

        sep     #$20            ; A8 mode for main program logic
        .a8

        lda     #$c0            ; Enter Super High-Res mode
        tsb     $c029
        lda     #$0f            ; Black border
        trb     $c034

        ;; Select the control codes for each line: $80 for the top and
        ;; bottom 8, then 23 lines of 1-8 each. Two lines of 80-col
        ;; text, and the rest is 16-color graphics
        lda     #$80
        ldx     #$0000
        ldy     #$0008
:       sta     $9d00,x         ; Lines 0-7
        sta     $9dc0,x         ; Lines 192-199
        inx
        dey
        bne     :-

        lda     #$01            ; .X is 8 here, which we want
:       ldy     #23             ; 23 lines per block
:       sta     $9d00,x
        inx
        dey
        bne     :-
        inc     a               ; Next block has next palette
        cmp     #$09            ; Have we done all 8?
        bne     :--             ; If not, next block

        ;; Draw the EGA grid
        ldy     #64             ; 64 boxes to draw
        ldx     #$05b1          ; Starting at (34, 9)
        lda     #$11            ; And fill color 1
draw_grid:
        jsr     box             ; Draw one box
        clc                     ; Advance to next color
        adc     #$11
        cmp     #$99            ; Have we done all 8?
        bne     @right          ; If so, move right
        rep     #$21            ; Otherwise move down. A16, CLC.
        .a16
        txa                     ; .X += (160*23) - (16*7)
        adc     #$df0
        tax
        sep     #$20
        .a8
        lda     #$11            ; And reset to color 1 for next row
        bra     @next
@right: pha                     ; Stash 8-bit color
        rep     #$21            ; A16 and CLC
        .a16
        txa                     ; .X += 16 (move right)
        adc     #$0010
        tax
        sep     #$20
        .a8
        pla                     ; Restore 8-bit color value
@next:  dey                     ; Have we drawn all 64?
        bne     draw_grid       ; If not, back we go

        ;; Draw the header and footer text
        ldx     #$001b
        ldy     #header
        jsr     drawstr_80

        ldx     #$7828
        ldy     #footer
        jsr     drawstr_80

        ;; Label grid entries
        lda     #$33
        ldx     #$6f24
        jsr     drawchar_40
        lda     #$06
        jsr     drawchar_40

        ;; Wait for keypress
:       bit     $c000
        bpl     :-
        bit     $c010

        ;; Leave Super Hi-Res mode
        lda     #$c0
        trb     $c029

        ;; Back to ProDOS
        plb                     ; Restore DBR
        pld                     ; Restore Direct Page
        pla                     ; Restore original stack
        tcs
        sec                     ; Resume emulation mode
        xce
        jsr     $bf00           ; ProDOS QUIT call
        .byte   $65
        .word   :+
        brk                     ; Unreachable
:       .byte   4               ; ProDOS QUIT params
        .byte   0, 0, 0, 0, 0, 0

;;; Draw a bordered box with fill pattern .A(8) at screen address
;;; .X(16).
box:    phy
        phx
        phx
        pha
        lda     #$ff
        ldy     #14
:       sta     $2000,x
        sta     $2c80,x
        inx
        dey
        bne     :-
        lda     #19
        pha
@line:  rep     #$21
        .a16
        lda     3,s
        adc     #160
        sta     3,s
        tax
        sep     #$20
        .a8
        lda     #$ff
        sta     $2000,x
        sta     $200d,x
        lda     2,s
        inx
        ldy     #$0c
:       sta     $2000,x
        inx
        dey
        bne     :-
        lda     1,s
        dec     a
        sta     1,s
        bne     @line
        pla
        pla
        plx
        plx
        ply
        rts

;;; ----------------------------------------------------------------------
;;;   Text drawing routines
;;; ----------------------------------------------------------------------

        ;; Direct page locations used by the system
        row_count := $00
        char_row  := $01
        str_ptr   := $02

drawstr_80:
        phy
        sty     str_ptr
        lda     #$00
        sta     str_ptr+2
        ldy     #$0000
:       lda     [str_ptr],y
        bmi     @done
        jsr     drawchar_80
        iny
        bra     :-
@done:  ply
        rts

charaddr:
        rep     #$20
        .a16
        and     #$ff
        asl     a               ; Y = A * 8
        asl     a
        asl     a
        tax
        sep     #$20
        .a8
        rts

drawchar_80:
        phx
        phy
        txy
        jsr     charaddr
        lda     #$08
        sta     row_count
:       lda     f:font,x
        sta     char_row
        jsr     @decode_byte
        jsr     @decode_byte
        rep     #$20
        .a16
        tya
        clc
        adc     #158
        tay
        sep     #$20
        .a8
        inx
        dec     row_count
        bne     :-
        ply
        plx
        inx
        inx
        rts
@decode_byte:
        lda     #$00
        asl     char_row
        bcc     :+
        ora     #$C0
:       asl     char_row
        bcc     :+
        ora     #$30
:       asl     char_row
        bcc     :+
        ora     #$0C
:       asl     char_row
        bcc     :+
        ora     #$03
:       sta     $2000,y
        iny
        rts

drawchar_40:
        phx
        phy
        txy
        jsr     charaddr
        lda     #$08
        sta     row_count
:       lda     f:font,x
        sta     char_row
        jsr     @decode_byte
        jsr     @decode_byte
        jsr     @decode_byte
        jsr     @decode_byte
        rep     #$20
        .a16
        tya
        clc
        adc     #156
        tay
        sep     #$20
        .a8
        inx
        dec     row_count
        bne     :-
        ply
        plx
        inx
        inx
        inx
        inx
        rts
@decode_byte:
        lda     #$00
        asl     char_row
        bcc     :+
        ora     #$F0
:       asl     char_row
        bcc     :+
        ora     #$0F
:       ora     $2000,y
        sta     $2000,y
        iny
        rts

palettes:
        ;; Palette 0: For our 640x480 mode, black-red-green-white
        .word   $0000,$0f00,$00f0,$0fff,$0000,$0f00,$00f0,$0fff
        .word   $0000,$0f00,$00f0,$0fff,$0000,$0f00,$00f0,$0fff
        ;; Palettes 1-8: The full EGA palette, in order, in indices
        ;; 1-8 in each palette. Color 0 is always black and 15 is
        ;; always white.
        .word   $0000,$0000,$000a,$00a0,$00aa,$0a00,$0a0a,$0aa0
        .word   $0aaa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0005,$000f,$00a5,$00af,$0a05,$0a0f,$0aa5
        .word   $0aaf,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0050,$005a,$00f0,$00fa,$0a50,$0a5a,$0af0
        .word   $0afa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0055,$005f,$00f5,$00ff,$0a55,$0a5f,$0af5
        .word   $0aff,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0500,$050a,$05a0,$05aa,$0f00,$0f0a,$0fa0
        .word   $0faa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0505,$050f,$05a5,$05af,$0f05,$0f0f,$0fa5
        .word   $0faf,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0550,$055a,$05f0,$05fa,$0f50,$0f5a,$0ff0
        .word   $0ffa,$0000,$0000,$0000,$0000,$0000,$0000,$0fff
        .word   $0000,$0555,$055f,$05f5,$05ff,$0f55,$0f5f,$0ff5
        .word   $0fff,$0000,$0000,$0000,$0000,$0000,$0000,$0fff

.macro  scrcode arg
        .repeat .strlen(arg), i
        .if     (.strat(arg, i) < 32) || (.strat(arg, i) >= 96)
                .error "Illegal character in scrcode string"
        .elseif     .strat(arg, i) >= 64
                .byte .strat(arg,i) - 64
        .else
                .byte .strat(arg,i)
        .endif
        .endrep
        .byte   255
.endmacro

header: scrcode "FLEXING ON IBM PC GRAPHICS IN 1986 WHILE WE STILL CAN"
footer: scrcode "80-COLUMN TEXT WITH ALL 64 EGA COLORS!!!"
        ;; Font table. This is an 1-bit font definition that uses the
        ;; C64 screen code order, so we'll need to do some translation
        ;; to actually get anywhere with this. char4 and char16 (above)
        ;; manage that feat.
font:   .include "../fonts/sinestra.s"
