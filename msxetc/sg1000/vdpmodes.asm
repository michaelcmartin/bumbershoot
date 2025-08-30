	include	"sg1000bios.asm"

screenid # 1

NUM_MODES EQU 5

main	xor	a
	ld	(screenid),a
.lp	call	.setmode
1	halt
	ld	a,(screenid)		; Get current displayed screen
	ld	b,a			; Put in B for edits
	ld	c,a			; Copy to C for reference
	ld	a,(joy1_pressed)	; Right or fire pressed?
	and	$38
	jr	z,2F
	inc	b			; If so, increment screen
2	ld	a,(joy1_pressed)	; Left pressed?
	and	$04
	jr	z,2F
	dec	b			; If so, decrement screen
2	ld	a,b			; Wrap around at edges
	cp	NUM_MODES
	jr	nz,2F
	xor	a
2	cp	$ff
	jr	nz,2F
	ld	a,NUM_MODES-1
2	cp	c			; Did the mode change?
	jr	z,1B			; If not, back to frame wait
	ld	(screenid),a		; If so, set new screen value
	jr	.lp			; and draw it before frame wait
.setmode
	ld	a,(screenid)
	or	a			; ScreenID 0 = Text Mode
	jr	nz,1F
	jp	txtmode
1	dec	a			; ScreenID 1 = Graphics Mode 1
	jr	nz,1F
	jp	g1mode
1	dec	a			; ScreenID 2 = Graphics Mode 2 Loom
	jr	nz,1F
	jp	g2_loom
1	dec	a			; ScreenID 3 = Graphics Mode 2 Text
	jr	nz,1F
	jp	g2_text
1	jp	mltmode			; ScreenID 4+ = Multicolor Mode

;; Load 8 VDP register assignments from the array at DE.
ldregs	ld	b,8
	ld	h,0
1	ld	a,(de)
	inc	de
	ld	l,a
	rst	set_vdp_register
	inc	h
	djnz	1B
	ret

;; Copy the character set into VRAM location DE.
ldchar	ld	hl,txtfont
	ld	bc,$0300
	rst	blit_vram
	ret

txtmode	di
	ld	de,txtreg
	call	ldregs
	ld	de,$0
	ld	a,$20
	ld	bc,$3c0
	rst	fill_vram
	ld	de,$0900
	call	ldchar
	ld	hl,txtmsg
	ld	bc,txtlen
	ld	de,$00c8
	rst	blit_vram
	ld	a,$d0
	ld	de,$0480
	rst	write_vram
	ld	hl,$01f0
	rst	set_vdp_register
	ei
	ret

g1mode	di
	ld	de,txtreg
	call	ldregs
	ld	de,$0
	ld	a,$20
	ld	bc,$300
	rst	fill_vram
	ld	a,$f0
	ld	bc,32
	ld	de,$0400
	rst	fill_vram
	ld	a,$e8
	ld	de,$0410
	rst	write_vram
	ld	de,$0900
	call	ldchar
	ld	hl,g1gfx
	ld	de,$0c00
	ld	bc,$0030
	rst	blit_vram
	ld	hl,g1msg
	ld	bc,g1len
	ld	de,$00c0
	rst	blit_vram
	ld	a,$d0
	ld	de,$0480
	rst	write_vram
	ld	hl,$01e0
	rst	set_vdp_register
	ei
	ret

g2_loom	di
	ld	de,gfxreg
	call	ldregs
	ld	de,$1800
	call	prep_vram_write
	ld	hl,0
1	ld	a,l
	out	(VDPDATA),a
	inc	hl
	ld	a,h
	cp	3
	jr	nz,1B
	ld	de,$1b00
	ld	a,$d0
	rst	write_vram
	ld	de,$2000
	ld	bc,$1800
	ld	a,$f4
	rst	fill_vram
	ld	de,0
	ld	bc,$1800
	ld	hl,g2lgfx
	rst	blit_vram
	ld	hl,g2lmsg
	call	g2print
	ld	hl,$01e0
	rst	set_vdp_register
	ei
	ret

g2_text	di
	ld	de,gfxreg		; Set registers
	call	ldregs
	ld	de,$1800		; Clear nametable to spaces
	ld	a,$20
	ld	bc,$0300
	rst	fill_vram
	ld	de,$2000		; Clear color table to white-on-blue
	ld	a,$f4
	ld	bc,$1800
	rst	fill_vram
	ld	de,$0100		; Load our 6 copies of the charset
	ld	b,6
1	push	bc
	push	de
	call	ldchar
	pop	de
	ld	a,d
	add	4
	ld	d,a
	pop	bc
	djnz	1B
	ld	b,3			; Load 3 copies of the border gfx
	ld	de,$0400
1	push	bc
	push	de
	ld	hl,g1gfx
	ld	bc,$30
	rst	blit_vram
	pop	de
	ld	a,d
	add	8
	ld	d,a
	pop	bc
	djnz	1B
	ld	de,$18e0		; Write message into nametable
	ld	hl,g2msg
	ld	bc,g2len
	rst	blit_vram
	ld	b,3			; Put rainbow colors on the top half
	ld	de,$2400		; of each color table third
1	push	bc
	call	prep_vram_write		; Color the border tiles
	ld	a,$06
2	ld	bc,$0800 | VDPDATA
	ld	hl,g2bcol
	otir
	dec	a
	jr	nz,2B
	inc	d			; Color the letters
	call	prep_vram_write
	ld	a,$60
2	ld	bc,$0800 | VDPDATA
	ld	hl,g2tcol
	otir
	dec	a
	jr	nz,2B
	pop	bc
	ld	a,d
	add	7
	ld	d,a
	djnz	1B
	ld	a,$d0			; Disable sprites
	ld	de,$1b00
	rst	write_vram
	ld	hl,$01e0		; Enable display
	rst	set_vdp_register
	ei
	ret

mltmode	di
	ld	de,mltreg
	call	ldregs
	ld	bc,$0600
	ld	de,0
	ld	hl,mltgfx
	rst	blit_vram
	ld	de,$0800
	call	prep_vram_write
	xor	a
	ld	d,6
1	ld	c,4
2	ld	b,32
3	out	(VDPDATA),a
	inc	a
	djnz	3b
	sub	32
	dec	c
	jr	nz,2b
	add	32
	dec	d
	jr	nz,1b
	ld	a,$d0
	ld	de,$0b00
	rst	write_vram
	ld	hl,$01e8
	rst	set_vdp_register
	ei
	ret

g2print	ld	a,(hl)
	ld	e,a
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	d,a
	or	e			; End of string collection?
	ret	z
	push	hl			; Save source and original dest for color run
	push	de
	call	prep_vram_write
	ld	de,txtfont		; Font base address
1	ld	a,(hl)
	inc	hl
	and	a			; End of string?
	jr	z,.color
	push	hl
	sub	32			; Correct for ASCII offset
	ld	h,0			; Compute source address
	ld	l,a
	add	hl,hl
	add	hl,hl
	add	hl,hl
	add	hl,de
	ld	bc,$0800 | VDPDATA
	otir
	pop	hl
	jr	1B
.color	pop	de
	pop	hl
	ld	a,d
	or	$20			; Write to Color table this time
	ld	d,a
	call	prep_vram_write
1	ld	a,(hl)
	inc	hl
	and	a			; End of string again?
	jr	z,g2print		; If so, next string in set
	ld	a,$b4			; Otherwise, write 8 lines of yellow on blue
	ld	b,8
2	out	(VDPDATA),a
	djnz	2b
	jr	1b

;; Dividers: $400,$40,$800,$80,$800
;; Text/Graphics 1: Name $0000, Color $0400, Pattern $0800, SprAttr $0480, SprPat $1000
;; Graphics 2: Name $1800, Color $2000, Pattern $0000, SprAttr $1B00, Sprpat $3800
;; Multicolor: Name $0800, Color $0B80, Pattern $0000, SprAttr $0B00, SprPat $1000

txtreg	db	$00,$80,$00,$10,$01,$09,$02,$f4  ; T40 enables with F0 instead
gfxreg	db	$02,$80,$06,$ff,$03,$36,$07,$f4
mltreg	db	$00,$80,$02,$2e,$00,$16,$02,$f4  ; Enable with E8

txtmsg	db	"----------------------------------------"
	db	"                                        "
	db	"    This program is a demonstration of  "
	db	"  the various display modes offered by  "
	db	"  the TMS9918A VDP chip used by the     "
	db	"  TI-99/4A, ColecoVision, SG-1000, and  "
	db	"  MSX systems.                          "
        db      "                                        "
        db	"    Shown here is the 40x24 text mode.  "
	db	"  Move the joystick left and right, or  "
	db	"  press either button, to scroll        "
	db	"  through the various modes.            "
	db	"                                        "
	db	"----------------------------------------"
txtlen	equ	$-txtmsg

g1msg	db	"  ",$80,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$82,"  "
	db	"  ",$83,"                          ",$83,"  "
	db	"  ",$83,"   This is the 32x24 text ",$83,"  "
	db	"  ",$83," mode that the VDP manual ",$83,"  "
	db	"  ",$83," calls ",$22,"Graphics I.",$22,"      ",$83,"  "
	db	"  ",$83,"                          ",$83,"  "
	db	"  ",$83,"   This mode offers more  ",$83,"  "
	db	"  ",$83," control over tile colors ",$83,"  "
	db	"  ",$83," and also enables sprite  ",$83,"  "
	db	"  ",$83," graphics.                ",$83,"  "
	db	"  ",$83,"                          ",$83,"  "
	db	"  ",$84,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$85
g1len	equ	$-g1msg

g2lmsg	dw	$0208
	db	" Graphics II Mode is intended ",0
	dw	$0328
	db	" for bitmap displays. ",0
	dw	0

g1gfx	db	$ff,$ff,$f3,$d9,$cc,$e6,$f3,$db
	db	$ff,$ff,$33,$99,$cc,$66,$ff,$ff
	db	$ff,$ff,$33,$9b,$cf,$67,$f3,$db
	db	$cf,$e7,$f3,$db,$cf,$e7,$f3,$db
	db	$cf,$e7,$f3,$d9,$cc,$e6,$ff,$ff
	db	$cf,$e7,$33,$9b,$cf,$67,$ff,$ff

g2msg	db	"  ",$80,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$82,"  "
	db	"  ",$83,"                          ",$83,"  "
	db	"  ",$83,"  However, Graphics II    ",$83,"  "
	db	"  ",$83," mode may also be used as ",$83,"  "
	db	"  ",$83," a Graphics I-like tiled  ",$83,"  "
	db	"  ",$83," graphics display, just   ",$83,"  "
	db	"  ",$83," with ",$c2,$c5,$d4,$d4,$c5,$d2,$a0,$c3,$cf,$ce,$d4,$d2,$cf,$cc,$a0,$ef,$e6,"   ",$83,"  "
	db	"  ",$83," ",$c3,$cf,$cc,$cf,$d2,$a0,$c1,$d3,$d3,$c9,$c7,$ce,$cd,$c5,$ce,$d4,$d3,".       ",$83,"  "
	db	"  ",$83,"                          ",$83,"  "
	db	"  ",$84,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$81,$85
g2len	equ	$-g2msg

g2tcol	db	$24,$34,$74,$f4,$74,$34,$24,$e4
g2bcol	db	$e2,$e3,$e2,$e6,$e8,$e9,$e8,$e6

txtfont	incbin	"../res/tms9918.bin"
g2lgfx	incbin	"../res/g2loom.bin"
mltgfx	incbin	"../res/mltdemo.bin"

	ds	$4000-$,$ff
