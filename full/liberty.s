        .alias  getin   $ffe4

        .outfile "liberty.prg"

        .data
        .org    $c000
        .space  val_index       1

.text
        ;; PRG header
        .word   $0801
        .org    $0801

        ;; BASIC header
        .word   +,2017
        .byte   $9e,$20,$32,$30,$36,$32,$00
*       .word   0

        jsr     bitmap_cls
        jsr     bitmap_graphics_mode
        lda     #$01
        sta     $d020
        lda     #$51
        ldx     #$00
*       sta     $0400,x
        sta     $0500,x
        sta     $0600,x
        sta     $06e8,x
        inx
        bne     -

        stx     val_index
        jsr     read_val
        jsr     shift_val
plot_lp:
        lda     val_index
        cmp     #gfx_pt_count
        beq     plot_done
        jsr     read_val        ; If 0, Y was 0 and line ended
        bne     +
        jsr     read_val
        jmp     ++
*       jsr     bitmap_line
*       jsr     shift_val
        jmp     plot_lp
plot_done:
        lda     #120
        sta     bitmap_x1
        lda     #00
        sta     bitmap_x1+1
        lda     #100
        sta     bitmap_y1
        jsr     flood_fill
        lda     #183
        sta     bitmap_x1
        lda     #00
        sta     bitmap_x1+1
        lda     #102
        sta     bitmap_y1
        jsr     flood_fill
        lda     #173
        sta     bitmap_x1
        lda     #00
        sta     bitmap_x1+1
        lda     #133
        sta     bitmap_y1
        jsr     flood_fill

        jsr     music_init
        lda     #<banner
        ldx     #>banner
        jsr     song_init

*       jsr     timer_tick
        jsr     music_tick
        jsr     getin
        beq     -

        jsr     music_done

        ;; Get back into normal mode
        lda     #$0e
        sta     $d020
        lda     #$06
        sta     $d021
        jsr     bitmap_text_mode

        lda     #<quitmsg
        ldy     #>quitmsg
        jsr     $ab1e           ; STROUT

        lda     #$00            ; Clear KB buffer
        sta     $c6

        jmp     ($A002)

timer_tick:
        lda     $a2
*       cmp     $a2
        beq     -
        rts

read_val:
        ldy     val_index
        inc     val_index
        clc
        lda     gfx_x, y
        beq     +
        adc     #gfx_x_bias
*       sta     bitmap_x2
        rol                     ; Bit 1 is the old carry...
        and     #$01            ;  ... and that's all that's left
        sta     bitmap_x2+1     ;  ... which is the high byte for X
        lda     gfx_y, y
        sta     bitmap_y2       ; Zero bit is set if Y was 0
        rts

shift_val:
        ldy     #$02
*       lda     bitmap_x2, y
        sta     bitmap_x1, y
        dey
        bpl     -
        rts

;;; These routines turn the entirety of $4000-$9FFF into one
;;; gigantic queue. We'll use that as scratch space for our
;;; flood-fill algorithm.
;;; The read-pointer and write-pointer are fixed inside the
;;; enqueue and dequeue routines, so updates are handled
;;; via modifying the address in-place.

queue_reset:
        lda     #$40
        sta     enqueue+2
        sta     dequeue+2
        lda     #$00
        sta     enqueue+1
        sta     dequeue+1
        rts

        ;; Zero flag is set if the queue is empty.
queue_is_empty:
        ;; The queue is empty if read_ptr = write_ptr.
        lda     enqueue+1
        cmp     dequeue+1
        bne     +
        lda     enqueue+2
        cmp     dequeue+2
*       rts

enqueue:
        sta     $4000
        inc     enqueue+1
        bne     +
        inc     enqueue+2
        lda     enqueue+2
        cmp     #$a0
        bne     +
        lda     #$40
        sta     enqueue+2
*       rts

dequeue:
        lda     $4000
        inc     dequeue+1
        bne     ++
        inc     dequeue+2
        pha
        lda     dequeue+2
        cmp     #$a0
        bne     +
        lda     #$40
        sta     dequeue+2
*       pla
*       rts

        ;; Check if x1/y1 can be part of a flood fill. If
        ;; so, fill it in and put it in the queue.
seed_point:
        jsr     bitmap_is_set
        bne     +               ; Already set
        jsr     bitmap_pset
        lda     bitmap_x1
        jsr     enqueue
        lda     bitmap_x1+1
        jsr     enqueue
        lda     bitmap_y1
        jsr     enqueue
*       rts

.scope
flood_fill:
        jsr     queue_reset
        jsr     seed_point
_lp:    jsr     queue_is_empty
        bne     +
        ;; Done!
        rts
*       jsr     dequeue
        sta     bitmap_x1
        jsr     dequeue
        sta     bitmap_x1+1
        jsr     dequeue
        sta     bitmap_y1
        dec     bitmap_y1
        jsr     seed_point
        inc     bitmap_y1
        inc     bitmap_y1
        jsr     seed_point
        dec     bitmap_y1
        ldx     bitmap_x1
        dex
        cpx     #$ff
        bne     +
        dec     bitmap_x1+1
*       stx     bitmap_x1
        jsr     seed_point
        clc
        lda     bitmap_x1
        adc     #$02
        sta     bitmap_x1
        lda     bitmap_x1+1
        adc     #$00
        sta     bitmap_x1+1
        jsr     seed_point
        jmp     _lp
.scend

        .include "../asm/protomus.s"
        .include "../asm/bitmap.s"

        ;; Graphics data
        .alias  gfx_x_bias      $2e
        .alias  gfx_pt_count    $e3

gfx_x:
        .byte   $2f,$40,$4b,$6d,$7a,$8a,$91,$88,$83,$72,$67,$5c
        .byte   $56,$56,$5d,$5f,$65,$65,$68,$68,$6b,$6b,$6d,$71
        .byte   $71,$6d,$70,$76,$78,$81,$7f,$7c,$7a,$77,$74,$74
        .byte   $75,$72,$6c,$5f,$58,$57,$5e,$65,$75,$7e,$91,$96
        .byte   $9c,$9d,$a2,$a4,$a5,$a4,$a2,$a0,$9c,$9b,$98,$9c
        .byte   $98,$9c,$9c,$a4,$c2,$ba,$bc,$b8,$b3,$b1,$a8,$ac
        .byte   $a4,$a4,$a7,$d8,$ac,$ac,$e9,$a7,$9e,$cc,$8c,$7e
        .byte   $75,$6d,$5d,$1d,$4c,$4c,$44,$01,$3f,$3f,$10,$43
        .byte   $48,$3f,$2f,$00,$14,$40,$3f,$00,$04,$40,$44,$00
        .byte   $1f,$58,$56,$5c,$62,$00,$7d,$71,$87,$95,$95,$cc
        .byte   $00,$9f,$9f,$a8,$a9,$e8,$00,$ab,$ab,$d8,$00,$a7
        .byte   $a1,$9e,$a6,$a3,$9a,$97,$9c,$98,$91,$8b,$8e,$88
        .byte   $86,$7d,$7d,$78,$78,$71,$71,$6c,$6d,$64,$60,$5c
        .byte   $5f,$58,$51,$4e,$54,$58,$64,$54,$4f,$53,$5e,$68
        .byte   $70,$76,$85,$90,$98,$9c,$a0,$a3,$a4,$a7,$00,$80
        .byte   $80,$82,$89,$90,$94,$92,$8f,$8d,$8b,$8d,$8b,$88
        .byte   $87,$85,$85,$80,$00,$4c,$50,$52,$52,$4c,$00,$68
        .byte   $6a,$73,$76,$7b,$7c,$81,$88,$81,$7d,$7b,$78,$76
        .byte   $71,$70,$71,$7e,$7a,$78,$74,$71,$6d,$69,$69

gfx_y:
        .byte   $78,$90,$ab,$b1,$ae,$99,$8b,$92,$94,$95,$91,$87
        .byte   $76,$6d,$6d,$6a,$6a,$68,$68,$6a,$6a,$68,$68,$6d
        .byte   $73,$7d,$7f,$81,$81,$7f,$7d,$7d,$7d,$7d,$7d,$73
        .byte   $68,$63,$63,$63,$65,$62,$5c,$5b,$53,$59,$5f,$61
        .byte   $6b,$70,$74,$74,$76,$77,$77,$7a,$7e,$82,$84,$8d
        .byte   $a5,$a5,$af,$b3,$b3,$a2,$a0,$9e,$86,$7f,$6f,$6b
        .byte   $5e,$54,$4f,$4e,$45,$43,$3b,$3b,$37,$12,$2f,$2d
        .byte   $0f,$2e,$2f,$12,$35,$37,$3b,$3b,$43,$45,$4f,$4f
        .byte   $55,$6c,$78,$00,$4e,$4a,$44,$00,$3c,$3f,$3c,$00
        .byte   $12,$33,$38,$37,$2e,$00,$2d,$33,$35,$39,$31,$12
        .byte   $00,$38,$3e,$44,$3e,$3b,$00,$43,$4a,$4e,$00,$69
        .byte   $5c,$4e,$48,$45,$4b,$49,$40,$3e,$47,$46,$3c,$3a
        .byte   $45,$44,$39,$39,$44,$45,$3a,$3a,$44,$44,$3b,$3c
        .byte   $45,$47,$3e,$40,$4a,$4a,$47,$4e,$55,$58,$59,$55
        .byte   $51,$4d,$58,$5c,$5d,$5e,$62,$66,$6a,$6a,$00,$68
        .byte   $67,$64,$63,$64,$68,$6a,$6a,$68,$68,$68,$68,$69
        .byte   $68,$68,$6a,$68,$00,$94,$81,$81,$95,$94,$00,$86
        .byte   $86,$83,$83,$84,$83,$84,$86,$86,$86,$86,$86,$86
        .byte   $86,$87,$89,$8a,$8c,$8c,$8b,$8c,$89,$86,$86

        ;; Music data
.scope
banner: .word   _banner1, _banner2, _banner3

_banner1:
        .byte   $82,$20,$02,$83,$0A,$84,$84,$00,$08
        .byte   $37,$18,$34,$08,$30,$20,$34,$20,$37,$20,$3c,$40,$40,$18,$3e,$08
        .byte   $3c,$20,$34,$20,$36,$20,$37,$40,$37,$10,$37,$10,$40,$30,$3e,$10
        .byte   $3c,$20,$3b,$40,$39,$18,$3b,$08,$3c,$20,$3c,$20,$37,$20,$34,$20
        .byte   $30,$20,$37,$18,$34,$08,$30,$20,$34,$20,$37,$20,$3c,$40,$40,$18
        .byte   $3e,$08,$3c,$20,$34,$20,$36,$20,$37,$40,$37,$10,$37,$10,$40,$30
        .byte   $3e,$10,$3c,$20,$3b,$40,$39,$18,$3b,$08,$3c,$20,$3c,$20,$37,$20
        .byte   $34,$20,$30,$20,$40,$18,$40,$08,$40,$20,$41,$20,$43,$20,$43,$40
        .byte   $41,$10,$40,$10,$3e,$20,$40,$20,$41,$20,$41,$40,$41,$20,$40,$30
        .byte   $3e,$10,$3c,$20,$3b,$40,$39,$18,$3b,$08,$3c,$20,$34,$20,$36,$20
        .byte   $37,$40,$37,$20,$3c,$20,$3c,$20,$3c,$10,$3b,$10,$39,$20,$39,$20
        .byte   $39,$20,$3e,$10,$40,$10,$41,$10,$40,$10,$3e,$10,$3c,$10,$3c,$20
        .byte   $3b,$20,$37,$10,$37,$10,$3c,$30,$3e,$10,$40,$10,$41,$10,$43,$40
        .byte   $3c,$10,$3e,$10,$40,$20,$41,$20,$3e,$20,$3c,$40
        .byte   $81,$00,$00

_banner2:
        .byte   $82,$20,$02,$83,$0A,$84,$84,$00,$08
        .byte   $80,$80,$39,$40,$2c,$18,$2c,$08,$2d,$20,$30,$20,$30,$20,$2f,$40
        .byte   $2b,$10,$2b,$10,$30,$30,$2f,$10,$2d,$20,$2b,$40,$2b,$10,$2b,$10
        .byte   $30,$20,$30,$20,$2f,$20,$30,$20,$80,$20,$80,$80,$39,$40,$2c,$18
        .byte   $2c,$08,$2d,$20,$30,$20,$30,$20,$2f,$40,$2b,$10,$2b,$10,$30,$30
        .byte   $2f,$10,$2d,$20,$2b,$40,$2b,$10,$2b,$10,$30,$20,$30,$20,$2f,$20
        .byte   $30,$20,$80,$20,$80,$80,$24,$20,$28,$20,$2a,$20,$2b,$40,$80,$20
        .byte   $2b,$20,$2d,$20,$2f,$20,$30,$30,$2f,$10,$2d,$10,$2a,$10,$2b,$40
        .byte   $29,$18,$2b,$08,$28,$20,$2d,$20,$26,$20,$2b,$10,$2d,$10,$2b,$10
        .byte   $29,$10,$28,$10,$26,$10,$24,$20,$24,$20,$28,$10,$24,$10,$29,$20
        .byte   $29,$20,$25,$20,$26,$10,$21,$10,$26,$10,$28,$10,$29,$10,$26,$10
        .byte   $2b,$20,$2b,$20,$2b,$10,$2b,$10,$24,$30,$23,$10,$24,$10,$26,$10
        .byte   $28,$40,$29,$10,$26,$10,$24,$20,$26,$20,$23,$20,$24,$40
        .byte   $81,$00,$00

_banner3:
        .byte   $82,$20,$02,$83,$0A,$84,$84,$00,$08
        .byte   $80,$40,$30,$20,$2f,$20,$2d,$40,$23,$18,$23,$08,$30,$20,$2d,$20
        .byte   $32,$20,$32,$40,$80,$20,$3c,$30,$37,$10,$34,$10,$36,$10,$37,$40
        .byte   $35,$18,$37,$08,$34,$20,$34,$20,$35,$20,$80,$40,$80,$40,$30,$20
        .byte   $2f,$20,$2d,$40,$23,$18,$23,$08,$30,$20,$2d,$20,$32,$20,$32,$40
        .byte   $80,$20,$3c,$30,$37,$10,$34,$10,$36,$10,$37,$40,$35,$18,$37,$08
        .byte   $34,$20,$34,$20,$35,$20,$80,$40,$30,$18,$30,$08,$30,$20,$32,$20
        .byte   $34,$20,$34,$40,$32,$10,$30,$10,$2f,$20,$30,$20,$32,$20,$32,$40
        .byte   $32,$20,$30,$30,$37,$10,$34,$10,$36,$10,$37,$40,$35,$18,$32,$08
        .byte   $34,$20,$32,$20,$32,$20,$37,$40,$37,$20,$34,$20,$34,$20,$37,$10
        .byte   $34,$10,$35,$20,$35,$20,$34,$20,$39,$10,$37,$10,$39,$10,$37,$10
        .byte   $39,$10,$39,$10,$37,$20,$37,$20,$37,$10,$35,$10,$34,$30,$32,$10
        .byte   $30,$10,$32,$10,$34,$40,$39,$10,$38,$10,$37,$20,$39,$20,$37,$20
        .byte   $34,$40
        .byte   $81,$00,$00
.scend

quitmsg:
        .byte   147, 13,"        = PORTRAIT OF LIBERTY =",13,13
        .byte   "ORIGINAL BY JOHN JAINSCHIGG",13
        .byte   "  FOR FAMILY COMPUTING, JUL 1986",13,13
        .byte   "NEW C64 PORT BY MICHAEL MARTIN, JUL 2017"
        .byte   "  BASED ON THE C64 AND PCJR VERSIONS",13,0

        ;; Don't get stomped by our bitmap display!
        .checkpc $2000
