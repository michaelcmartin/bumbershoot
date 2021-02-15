;;; ----------------------------------------------------------------------
;;;    Multicolor Bitmap Routines
;;;
;;;  These functions provide an interface for plotting and reading pixels
;;;  from the multicolor display. They do not handle color control or line
;;;  plotting.
;;; ----------------------------------------------------------------------

        .scope
        .data
        .org    [^+$ff] & $FF00         ; Align to page
        .space  _y_low  100
        .space  _y_high 100
        .space  _vars     2             ; Scratch fn data

        .alias  _ptr    $fb             ; Scratch pointer
        .text

;;; ----------------------------------------------------------------------
;;;  enter_bitmap: enters bitmap mode. This function also computes the
;;;                address tables for each line.
;;;                Bitmap data is held at $2000-$3FFF, with the screen
;;;                memory at $0400.
;;;    input: .A = high byte of bitmap base address
;;;   output: None
;;;  trashes: .A, .X, .Y
;;; ----------------------------------------------------------------------
enter_bitmap:
        .scope
        lda     #$93                    ; Clear text screen (and thus BMP
        jsr     $ffd2                   ; color to $20).

        lda     #$00                    ; Now we clear the bitmap screen.
        sta     _y_low                  ; (0 is also the first low byte)
        tay                             ; This only clears the 8KB of the
        ldx     #$20                    ; bitmap data; the caller needs
        stx     _y_high
        stx     _ebm_clr
        .alias  _ebm_clr        ^+2     ; to make sure that color memory
*       sta     $c000,y                 ; is properly configured.
        iny
        bne     -
        inc     _ebm_clr
        dex
        bne     -

        ;; Now that it won't be a big mess, now we can actually switch into
        ;; bitmap mode.
        lda     #$18                    ; Video addresses ($0400/$2000)
        sta     $d018
        lda     #$bb                    ; Set bitmap mode.
        sta     $d011
        lda     #$18                    ; Set multicolor mode.
        sta     $d016

        ;; Which in turn means it's time to define the colors. We will use
        ;; green for color 1 (bacteria) and white for color 2 (bugs), with
        ;; color 3 matching the light blue border. The background will be
        ;; dark blue.
        lda     #$06
        sta     $d021
        lda     #$0e
        sta     $d020
        ldy     #$00
*       sta     $d800,y
        sta     $d900,y
        sta     $da00,y
        sta     $dae8,y
        iny
        bne     -
        lda     #$51
*       sta     $0400,y
        sta     $0500,y
        sta     $0600,y
        sta     $06e8,y
        iny
        bne     -

        ;; Now we need to compute the byte offset for each line so we don't
        ;; need to do a ton of multiplications when plotting.
        ldx     #$00                    ; pixel row index
_alp:   ldy     #$03                    ; 4 pixel rows per char row
_blp:   lda     _y_high,x               ; The seven lines after the first
        sta     _y_high+1,x             ; pixel row in a char row are just
        lda     _y_low,x                ; simple increments that cannot
        clc                             ; cross page boundaries. We use
        adc     #$02                    ; three of them.
        sta     _y_low+1,x
        inx
        dey
        bne     _blp
        cpx     #99                     ; Was that the last line?
        bne     +                       ; If so, return
        rts
*       clc                             ; The jump to a new char row is
        lda     _y_low,x                ; 320 ($140) bytes from the start of
        adc     #$3a                    ; the previous char row, or $13a from
        sta     _y_low+1,x              ; the sixth.
        lda     _y_high,x
        adc     #$01
        sta     _y_high+1,x
        inx                             ; never 0
        bne     _alp                    ; so branch to next char row.
        .scend

leave_bitmap:
        lda     #$93
        jsr     $ffd2
        lda     #$14
        sta     $d018
        lda     #$08
        sta     $d016
        lda     #$9b
        sta     $d011
        rts


        ;; .X = X (0-159), .Y = Y (0-199), UNCHECKED
        ;; Puts the target address in ($fb)+y, pixel offset in .X (0 left,
        ;; 3 right).
_find_address:
        lda     _y_low,y
        sta     $fb
        lda     _y_high,y
        sta     $fc
        txa
        and     #$fc
        asl
        bcc     +
        inc     $fc
*       tay                             ; Low 8 bits of X become ind-ind offs
        txa
        and     #$03                    ; Low 2 bits of X become pixel index
        sta     $fd
        tax
        rts

        ;; .A = color, .X = X (0-159), .Y = Y (0-199)
pset:   cpx     #160                    ; Abort immediately if we try
        bcs     _fin                    ; to plot off the screen
        cpy     #100
        bcs     _fin
        pha                             ; Stash color
        pha
        sty     _vars
        stx     _vars+1
        jsr     _find_address
        lda     _mask0,x                ; Erase original color
        and     ($fb),y
        sta     $fe
        pla                             ; Restore color
        beq     _prset                  ; If it's black, we have our value
        asl
        asl                             ; times 4 (carry is now clear)
        adc     $fd                     ; Add low 2 bits of X for mask
        tax
        lda     _mask0,x                ; color bits
        ora     $fe
        bne     _psfin                  ; always branches

_prset: lda     $fe                     ; On reset restore masked value

_psfin: sta     ($fb),y                 ; Write updated byte
        iny                             ; and duplicate it on the next row
        sta     ($fb),y                 ; (160x100 simulated display)
        ldx     _vars+1                 ; Restore arguments
        ldy     _vars
        pla
_fin:   rts

        ;; .X = X (0-159), .Y = Y (0-199).
        ;; On success, .A holds the color at that location.
        ;; Carry is clear on success.
pread:  cpx     #160                    ; Abort immediately if we try
        bcs     _fin                    ; to read off the screen
        cpy     #200
        bcs     _fin
        sty     _vars
        stx     _vars+1
        jsr     _find_address
        lda     ($fb),y
*       cpx     #$03
        beq     +
        lsr
        lsr
        inx
        bne     -
*       and     #$03
        ldy     _vars
        ldx     _vars+1
        clc
        rts

        ;; Align mask data to 16-byte boundary
        .advance [^+15] & $FFF0
_mask0: .byte   $3f,$cf,$f3,$fc
_mask1: .byte   $40,$10,$04,$01
_mask2: .byte   $80,$20,$08,$02
_mask3: .byte   $c0,$30,$0c,$03
        .scend
