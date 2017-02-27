;;; ======================================================================
;;;   Bitmap library for C64
;;;
;;;  This is a fairly simple library, and it's some of the earliest 6502
;;;  work I did. Its interface and efficiency probably leave much to be
;;;  desired.
;;;
;;;  Functions are exported to enter, leave, and clear graphics mode,
;;;  draw or erase points, and draw lines.
;;;
;;;  All functions work only on the high-resolution display, which
;;;  must be placed at $2000.
;;;
;;;  Arguments are passed in via the global variables bitmap_x1,
;;;  bitmap_y1, bitmap_x2, and bitmap_y2. These variables are
;;;  contiguous and in order. Y coordinates are one byte long
;;;  (valid values: 0-199) and X coordinates are two bytes long
;;;  (valid values: 0-319). bitmap_x#+3 is the same as bitmap_y#.
;;;
;;;  Memory layout is somewhat finicky. The default .data segment
;;;  must have been declared prior to including this file. All
;;;  functions that modify the display also trash $fb and $fc,
;;;  which are used as a workspace.
;;;
;;; ----------------------------------------------------------------------
;;;  Exported functions summary:
;;;
;;;    bitmap_graphics_mode:       Sets bitmap mode
;;;    bitmap_text_mode:           Ends bitmap mode
;;;    bitmap_cls:                 Clears bitmap area
;;;    bitmap_pset:                Sets point at (x1, y1)
;;;    bitmap_preset:              Clears point at (x1, y1)
;;;    bitmap_is_set:              Nonzero .A and flag if (x1, y1) set
;;;    bitmap_line:                Draws a line from (x1, y1)-(x2, y2)
;;; ----------------------------------------------------------------------

.scope
.alias _ptr $fb                 ; Scratch point used by most fns

        .data
.space bitmap_x1 2              ; First coordinate
.space bitmap_y1 1
.space bitmap_x2 2              ; Second coordinate
.space bitmap_y2 1

        .text

;;; ======================================================================
;;;  bitmap_graphics_mode - configure bitmap at $2000 and enable it.
;;;     Arguments: None
;;;       Returns: None
;;;       Trashes: Accumulator and flags
;;; ----------------------------------------------------------------------
bitmap_graphics_mode:
        lda $D018       ; Set bit 3 of $D018 to put bitmap at $2000
        ora #$08
        sta $D018
        lda $D011       ; Set bit 5 of $D011 to activate bitmap mode
        ora #$20
        sta $D011
        rts

;;; ======================================================================
;;;  bitmap_text_mode - return to default text mode display.
;;;     Arguments: None
;;;       Returns: None
;;;       Trashes: Accumulator and flags
;;; ----------------------------------------------------------------------
bitmap_text_mode:
        lda $D018       ; Set bits 1-3 of $D018 to restore default charset
        and #$F1
        ora #$04
        sta $D018
        lda $D011       ; Clear bit 5 of $D011 to deactivate bitmap mode
        and #$DF
        sta $D011
        rts

;;; ======================================================================
;;;  bitmap_cls - Clear the bitmap screen.
;;;     Arguments: None
;;;       Returns: None
;;;       Trashes: all registers, and $fb-$fc.
;;; ----------------------------------------------------------------------
bitmap_cls:
        lda #$00
        ldx #$20
        ldy #$00
        sty _ptr         ; Start at $2000
        stx _ptr+1
*       sta (_ptr), y
        iny
        bne -
        inc _ptr+1
        dex
        bne -
        rts

;;; ======================================================================
;;;  _bitmap_get_address: Internal function for navigating the display.
;;;                       Given a point in (x1, y1), it computes the
;;;                       address of the byte that contains that point
;;;                       and the bitmask necessary to isolate the
;;;                       pixel itself.
;;;     Arguments: Coordinates in (x1, y1)
;;;       Returns: $2000+(y1 >> 3)*320+(x1>>3)*8+y1&7 in $fb, $fc
;;;                2**(7-(x1&7)) in accumulator
;;;       Trashes: all other registers
;;; ----------------------------------------------------------------------
_bitmap_get_address:
	lda bitmap_y1
	and #$07
	sta _ptr
	lda bitmap_x1
	and #$F8
	ora _ptr
	sta _ptr
	lda bitmap_y1
	and #$F8
	asl
	asl
	asl
	clc
	adc _ptr
	sta _ptr
	lda #$20
	adc bitmap_x1+1
	sta _ptr+1
	lda bitmap_y1
	clc
	lsr
	lsr
	lsr
	pha
	clc
	adc _ptr+1
	sta _ptr+1
	pla
	lsr
	lsr
	clc
	adc _ptr+1
	sta _ptr+1
        lda bitmap_x1
        and #$07
        tax
        clc
        lda #$80
*       cpx #0
        beq +
        lsr
        dex
        jmp -
*       rts

;;; ======================================================================
;;;  bitmap_pset - Draw a point on the bitmap display.
;;;     Arguments: Point at (x1, y1)
;;;       Returns: None
;;;       Trashes: All registers and flags, $fb, $fc
;;; ----------------------------------------------------------------------
bitmap_pset:
        jsr _bitmap_get_address
        ldy #0
        ora (_ptr),y
        sta (_ptr),y
        rts

;;; ======================================================================
;;;  bitmap_preset - Erase a point from the bitmap display.
;;;     Arguments: Point at (x1, y1)
;;;       Returns: None
;;;       Trashes: All registers and flags, $fb, $fc
;;; ----------------------------------------------------------------------
bitmap_preset:
        jsr _bitmap_get_address
        eor #$ff
        ldy #0
        and (_ptr),y
        sta (_ptr),y
        rts

;;; ======================================================================
;;;  bitmap_is_set - Test a point on the bitmap display.
;;;     Arguments: Point at x1, y1
;;;       Returns: Masked pixel in accumulator. Z set if blank.
;;;       Trashes: All other registers, $fb, $fc
;;; ----------------------------------------------------------------------
bitmap_is_set:
        jsr _bitmap_get_address
        ldy #0
        and (_ptr),y
        rts

;;; ======================================================================
;;;  bitmap_line - Draw a line on the bitmap display. This implementation
;;;                is basically a simple hand-translation of Bresenham's
;;;                algorithm.
;;;     Arguments: Endpoints (x1, y1) and (x2, y2)
;;;       Returns: None
;;;       Trashes: All registers and flags, $fb, $fc
;;; ----------------------------------------------------------------------
.scope
.data
.space _d 2
.space _ax 2
.space _ay 2
.space _sx 2
.space _sy 1
.space _temp 2
.space _old 3

.text
bitmap_line:
        lda bitmap_x1           ; store old values of x1 and y1.
        sta _old
        lda bitmap_x1+1
        sta _old+1
        lda bitmap_y1
        sta _old+2

        sec                     ; ax=x2-x1
        lda bitmap_x2
        sbc bitmap_x1
        sta _ax
        lda bitmap_x2+1
        sbc bitmap_x1+1
        sta _ax+1
        bmi +
        lda #$01                ; ax is positive; sx = 1.
        sta _sx
        lda #$00
        sta _sx+1
        jmp ++
*       eor #$FF                ; ax is negative; ax = -ax
        sta _ax+1
        lda _ax
        eor #$FF
        clc
        adc #$01
        sta _ax
        lda _ax+1
        adc #$00
        sta _ax+1
        lda #$FF                ; and sx = -1.
        sta _sx
        sta _sx+1
*       clc                     ; ax *= 2.  Now holds the value of abs(x2-x1)*2.
        rol _ax
        rol _ax+1

        sec                     ; ay = y2-y1
        lda bitmap_y2
        sbc bitmap_y1
        sta _ay
        lda #$00
        sbc #$00
        sta _ay+1
        bmi +
        lda #$01                ; ay is positive; sy = 1.
        sta _sy
        jmp ++
*       eor #$FF                ; ay is negative; ay = -ay
        sta _ay+1
        lda _ay
        eor #$FF
        clc
        adc #$01
        sta _ay
        lda _ay+1
        adc #$00
        sta _ay+1
        lda #$FF                ; and sy = -1
        sta _sy
*       clc
        rol _ay             ; ay *= 2.  Now ay = abs(y2-y1)*2.
        rol _ay+1

        sec
        lda _ax
        sbc _ay
        lda _ax+1
        sbc _ay+1
        bpl _x_dominant
        jmp _y_dominant
_x_dominant:
        lda _ax             ; temp = ax / 2
        sta _temp
        lda _ax+1
        sta _temp+1
        clc
        ror _temp+1
        ror _temp
        sec                     ; d = ay - temp (ay - ax / 2)
        lda _ay
        sbc _temp
        sta _d
        lda _ay+1
        sbc _temp+1
        sta _d+1
_x_dominant_loop:
        jsr bitmap_pset         ; Draw pixel
        lda bitmap_x1           ; If x = x2, return.
        cmp bitmap_x2
        bne +
        lda bitmap_x1+1
        cmp bitmap_x2+1
        bne +
        jmp _done
*       bit _d+1            ; Is d>=0?
        bmi +
        clc                     ; If not, y += sy
        lda bitmap_y1
        adc _sy
        sta bitmap_y1
        sec                     ; and d -= ax
        lda _d
        sbc _ax
        sta _d
        lda _d+1
        sbc _ax+1
        sta _d+1
*       clc                     ; End if.  Now let x += sx...
        lda bitmap_x1
        adc _sx
        sta bitmap_x1
        lda bitmap_x1+1
        adc _sx+1
        sta bitmap_x1+1
        clc                     ; and d += ay
        lda _d
        adc _ay
        sta _d
        lda _d+1
        adc _ay+1
        sta _d+1
        jmp _x_dominant_loop
_y_dominant:
        lda _ay             ; temp = ay / 2
        sta _temp
        lda _ay+1
        sta _temp+1
        clc
        ror _temp+1
        ror _temp
        sec                     ; d = ax - temp (ax - ay / 2)
        lda _ax
        sbc _temp
        sta _d
        lda _ax+1
        sbc _temp+1
        sta _d+1
_y_dominant_loop:
        jsr bitmap_pset         ; Draw pixel
        lda bitmap_y1           ; If y = y2, return.
        cmp bitmap_y2
        bne +
        jmp _done
*       bit _d+1            ; Is d>=0?
        bmi +
        clc                     ; If not, x += sx
        lda bitmap_x1
        adc _sx
        sta bitmap_x1
        lda bitmap_x1+1
        adc _sx+1
        sta bitmap_x1+1
        sec                     ; and d -= ay
        lda _d
        sbc _ay
        sta _d
        lda _d+1
        sbc _ay+1
        sta _d+1
*       clc                     ; End if.  Now let y += sy...
        lda bitmap_y1
        adc _sy
        sta bitmap_y1
        clc                     ; and d += ax
        lda _d
        adc _ax
        sta _d
        lda _d+1
        adc _ax+1
        sta _d+1
        jmp _y_dominant_loop

_done:                      ; restore old values of x1 and y1.
        lda _old
        sta bitmap_x1
        lda _old+1
        sta bitmap_x1+1
        lda _old+2
        sta bitmap_y1
        rts
.scend
.scend
