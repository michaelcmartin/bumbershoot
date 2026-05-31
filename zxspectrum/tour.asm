	org $7000
	map bss_start
blastr # 32			; Must be first to align with target/blaster

	ld a,$20
	call clrto
	ld hl,gfx
	ld e,(iy+65)
	ld d,(iy+66)
	ld bc,gfxend-gfx
	ldir
	ld hl,msg
	call print
	call getkey

	;; Draw the Loom
	ld a,$0f
	call clrto

	ld c,$0f
	ld hl,0
	ld de,$ff
	call line
	ld de,$bf00
	call line
	ld hl,$bfff
	call line
	ld de,$ff
	call line

	ld hl,$80
	ld de,$bf02
1	call line
	ld a,h
	ld h,d
	ld d,a
	call line
	ld a,h
	ld h,d
	ld d,a
	ld a,e
	add 10
	ld e,a
	jr nc,1B
	ld hl,$6000
	ld de,$06ff
1	call line
	ld a,e
	ld e,l
	ld l,a
	call line
	ld a,e
	ld e,l
	ld l,a
	ld a,d
	add 10
	ld d,a
	cp $c0
	jr c,1B

	ld hl,msg2
	call print
	call getkey

	;; Screen 3: Rigged gallery display
	;; Black screen
	ld a,$07
	call clrto
	;; Draw the ground
	ld a,$20
	ld hl,$5a80
	ld b,128
1	ld (hl),a
	inc hl
	djnz 1B
	;; Prepare the flipped blaster
	ld hl,blast
	ld de,blastr
	call reverse_sprite
	;; Reload and draw UDG elements
	ld hl,target
	ld e,(iy+65)
	ld d,(iy+66)
	ld bc,96
	ldir
	ld hl,msg3
	call print
	;; Draw some shots
	ld c,$02
	ld hl,$8026
	ld de,$7a26
	call line
	ld hl,$7023
	ld de,$6a23
	call line
	ld hl,$6020
	ld de,$5a20
	call line

	call getkey
	ld a,$38
	;; fall through into clrto

clrto:	ld (iy+83),a			; ATTR-P
	and $38
	ld (iy+14),a			; BORDCR
	rrca
	rrca
	rrca
	out ($fe),a
	xor a
	ld (iy+84),a			; MASK-P
	ld (iy+87),a			; P-FLAGS
	call $0d6b			; CLS
	ld a,2
	jp $1601			; CHAN-OPEN

print:	ld a,(hl)
	inc hl
	inc a
	ret z
	dec a
	rst $10
	jr print

getkey:	res 5,(iy+1)
1	halt
	bit 5,(iy+1)
	jr z,1B
	res 5,(iy+1)
	ret

;;; PLOT: (X,Y) in (L,H), attribute in C. Trashes ABDE.
plot:	;; Convert coordinate to address in DE
	ld a,h
	and 7
	ld d,a
	ld a,h
	rra
	scf
	rra
	rra
	and $58
	or d
	ld d,a
	ld a,h
	add a
	add a
	and $e0
	ld e,a
	ld a,l
	rra
	rra
	rra
	and 31
	or e
	ld e,a
	;; Find the pixel bit for X and blend it in at the appropriate byte
	ld a,l
	and 7
	ld b,a
	inc b
	xor a
	scf
1	rra
	djnz 1B
	ex de,hl
	or (hl)
	ld (hl),a
	;; Convert the pixel address (now HL) to attr address and store attr
	ld a,h
	rrca
	rrca
	rrca
	and 3
	or $58
	ld h,a
	ld (hl),c
	;; Restore Hl on the way out
	ex de,hl
	ret

;;; LINE: Draw in color C from HL to DE, as per PLOT.
line:
	;; Local variables
.dx # 2
.dy # 2
.sx # 1
.sy # 1
.x1 # 1
.y1 # 1
.x2 # 1
.y2 # 1
	;; Store registers (x/y 1/2 stay constant, so no need to stack them)
	push bc
	ld (.x1),hl
	ld (.x2),de

	ld a,e				; A = x2-x1
	sub l
	jr c,1F
	ld (.dx),a			; x2 >= x1: dx=x2-x1, sx=1
	ld a,1
	jr 2F
1	neg				; x2 < x1: dx=x1-x2, sx=-1
	ld (.dx),a
	ld a,$ff
2	ld (.sx),a
	xor a				; Top byte of dx is always 0
	ld (.dx+1),a
	ld a,d				; A = y2-y1
	sub h
	jr c,1F
	ld (.dy),a			; y2 >= y1: dy=y2-y1, sy=1
	ld a,1
	jr 2F
1	neg				; y2 < y1: dy=y1-y2, sy=-1
	ld (.dy),a
	ld a,$ff
2	ld (.sy),a
	xor a				; Top byte of dy is always 0
	ld (.dy+1),a

	ld a,(.dx)
	ld b,a
	ld a,(.dy)
	cp b
	jr nc,.y_major
	;; X-major branch: dx > dy
	ld a,(.dx)			; d = -dx
	neg
	ld l,a
	ld h,$ff
	push hl
	add hl,hl			; dx = -(dx << 1)
	ld (.dx),hl
	ld hl,(.dy)			; dy = dy << 1
	add hl,hl
	ld (.dy),hl
	ld hl,(.x1)			; x = x1; y = y1
.xmlp:	call plot
	ld a,(.x2)			; if (x==x2) break;
	cp l
	jr z,.end
	ld a,(.sx)			; x += sx
	add l
	ld l,a
	ex (sp),hl			; HL = d, (SP) = x/y
	ld de,(.dy)			; d += dy
	add hl,de
	jr nc,1F			; If d positive, step y/reset d
	ld de,(.dx)			; d += dx
	add hl,de
	ex (sp),hl			; HL = x/y, (SP) = d
	ld a,(.sy)			; y += sy
	add h
	ld h,a
	jr .xmlp			; And on to next pixel
1	ex (sp),hl			; if d still negative, HL=x/y, (SP)=d
	jr .xmlp			; ... and go immediately to next pixel

	;; Y-major branch: dx <= dy
.y_major:
	ld a,(.dy)			; d = -dy
	neg
	ld l,a
	ld h,$ff
	push hl
	add hl,hl			; dy = -(dy << 1)
	ld (.dy),hl
	ld hl,(.dx)			; dx = dx << 1
	add hl,hl
	ld (.dx),hl
	ld hl,(.x1)			; x = x1; y = y1
.ymlp:	call plot
	ld a,(.y2)			; if (y==y2) break;
	cp h
	jr z,.end
	ld a,(.sy)			; y += sy
	add h
	ld h,a
	ex (sp),hl			; HL = d, (SP) = x/y
	ld de,(.dx)			; d += dx
	add hl,de
	jr nc,1F			; if d is positive, step x/reset d
	ld de,(.dy)			; d += dy
	add hl,de
	ex (sp),hl			; HL = x/y, (SP)=d
	ld a,(.sx)			; x += sx
	add l
	ld l,a
	jr .ymlp			; and on to next pixel
1	ex (sp),hl			; if d still negative, HL=x/y, (SP)=d
	jr .ymlp			; and go immediately to next pixel
	;; Balance stack on the way out
.end:	pop hl
	;; Restore registers on the way out
	ld hl,(.x1)
	ld de,(.x2)
	pop bc
	ret

reverse_sprite:
	push	hl
	push	de
	ld	de,16
	add	hl,de
	pop	de
	call	.col
	pop	hl
	call	.col
	ld	a,16
	add	l
	jr	nc,1F
	inc	h
1	ld	l,a
	ret
.col:	ld	c,16
1	push	de
	ld	a,(hl)
	ld	b,8
2	rra
	rl	d
	djnz	2B
	ld	a,d
	pop	de
	ld	(de),a
	inc	hl
	inc	de
	dec	c
	jr	nz,1B
	ret

msg:	db $10,4,$11,0,$16,10,2,$8b,"                          ",$87
	db $13,1,$10,1,$16,11,2," ",$90,$91,$10,7,"  BUMBERSHOOT SOFTWARE   "
	db $10,1,$16,12,2," ",$92,$10,6,$13,0,$93,$13,1,$10,7,"Showing off the Spectrum "
	db $13,0,$10,4,$16,13,2,$8e,"                          ",$8d,255

msg2:	db $10,5,$16,4,3,$94,$95,$95,$95,$95,$95,$95,$95,$95,$95,$95,$95
	db $95,$95,$95,$95,$95,$95,$95,$95,$95,$95,$95,$95,$95,$96
	db $16,5,3,$97,$10,6,"  ALL SPECTRUM DISPLAYS ",$10,5,$98
	db $16,6,3,$97,$10,6,"ARE BITMAPPED, ALLOWING ",$10,5,$98
	db $16,7,3,$97,$10,6,"FOR SEAMLESS INTEGRATION",$10,5,$98
	db $16,8,3,$97,$10,6,"OF TEXT AND GRAPHICS.   ",$10,5,$98
	db $16,9,3,$99,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a
	db $9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9a,$9b,$ff

msg3:	db $10,0,$11,7,$16,0,0,"                   SCORE: 1234  "
	db $10,2,$11,0,$16,6,12,$90,$92,"   ",$90,$92,"   ",$90,$92
	db $16,7,12,$91,$93,"   ",$91,$93,"   ",$91,$93
	db $10,6,$16,18,27,$94,$96,$16,19,27,$95,$97
	db $16,18,5,$98,$9a,$16,19,5,$99,$9b,$ff

gfx:	db $03,$0f,$1f,$3f,$7f,$7f,$ff,$ff
	db $c0,$f0,$f8,$f8,$f0,$e0,$c0,$80
	db $ff,$fe,$7c,$78,$30,$00,$00,$00
	db $80,$c0,$60,$30,$18,$08,$38,$00
	db $ff,$ff,$c0,$c0,$c0,$c0,$c0,$c0
	db $ff,$ff,$00,$00,$00,$00,$00,$00
	db $ff,$ff,$03,$03,$03,$03,$03,$03
	db $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
	db $03,$03,$03,$03,$03,$03,$03,$03
	db $c0,$c0,$c0,$c0,$c0,$c0,$ff,$ff
	db $00,$00,$00,$00,$00,$00,$ff,$ff
	db $03,$03,$03,$03,$03,$03,$ff,$ff
gfxend:

target:	defb $03,$0f,$1c,$30,$63,$66,$cc,$c9,$c9,$cc,$66,$63,$30,$1c,$0f,$03
	defb $c0,$f0,$38,$0c,$c6,$66,$33,$93,$93,$33,$66,$c6,$0c,$38,$f0,$c0
blast:	defb $00,$00,$00,$00,$00,$00,$00,$fa,$8b,$ea,$ef,$88,$80,$db,$3c,$18
	defb $00,$00,$20,$20,$70,$a8,$f8,$aa,$fe,$fa,$ff,$01,$01,$ed,$1e,$0c
	;; Must be last to align with blastr
bss_start:
