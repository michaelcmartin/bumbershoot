;;; ----------------------------------------------------------------------
;;;   Unframed LZ4 Decoder for 6502 processor
;;;   (c) Michael C. Martin, 2026. Available under MIT License.
;;; ----------------------------------------------------------------------

;;; lz4dec: Decompress a single unframed LZ4 block.
;;;    $FB-$FC: Pointer to compressed data
;;;    $FD-$FE: Pointer to destination buffer
;;;    One exit, both point one byte past the final byte read/written

.scope
        ;; Redefine these to match your system's ZP usage; these should
        ;; work fine on the C64 and Atari 8-bits
        .alias  _src    $fb
        .alias  _dest   $fd

        .data
        .space  _count  2
        .space  _bksrc  2
        .text

lz4dec: ldy     #$00                    ; Y always 0 at internal fn boundaries
        lda     (_src),y
        inc     _src
        bne     +
        inc     _src+1
*       pha
        lsr
        lsr
        lsr
        lsr
        beq     _bkref
        jsr     _rdlen
        jsr     _ldir
_bkref: sec
        lda     _dest
        sbc     (_src),y
        sta     _bksrc
        iny
        lda     _dest+1
        sbc     (_src),y
        sta     _bksrc+1
        dey
        clc
        lda     _src
        adc     #$02
        sta     _src
        bcc     +
        inc     _src+1
*       lda     _dest
        cmp     _bksrc
        bne     _bkok
        lda     _dest+1
        cmp     _bksrc+1
        bne     _bkok
        pla
        rts
_bkok:  pla
        and     #$0f
        jsr     _rdlen
        lda     _src
        ldx     _bksrc
        pha
        stx     _src
        lda     _src+1
        ldx     _bksrc+1
        pha
        stx     _src+1
        clc
        lda     _count
        adc     #$04
        sta     _count
        bcc     +
        inc     _count+1
*       jsr     _ldir
        pla
        sta     _src+1
        pla
        sta     _src
        jmp     lz4dec
_rdlen: sta     _count
        sty     _count+1
        cmp     #$0f
        bne     _rdone
_rdlp:  lda     (_src),y
        inc     _src
        bne     +
        inc     _src+1
*       tax
        clc
        adc     _count
        sta     _count
        bcc     +
        inc     _count+1
*       cpx     #$ff
        beq     _rdlp
_rdone: rts
_ldir:  ldx     _count
        beq     +
        inc     _count+1
*       lda     (_src),y
        sta     (_dest),y
        iny
        bne     +
        inc     _src+1
        inc     _dest+1
*       dex
        bne     --
        dec     _count+1
        bne     --
        clc
        tya
        adc     _src
        sta     _src
        bcc     +
        inc     _src+1
*       clc
        tya
        adc     _dest
        sta     _dest
        bcc     +
        inc     _dest+1
*       ldy     #$00
        rts
.scend
