;;;----------------------------------------------------------------------
;;;  Shooting Gallery Core Logic
;;;  This file is intended to be included by the shell code for each of
;;;  the target platforms; check subdirectories for those details.
;;;----------------------------------------------------------------------

sprattrs     # 60
score        #  2
scorebuf     #  4
fire         #  1
collision    #  1
blaster_x    #  1
blaster_face #  1

init_game:
	xor	a
	ld	hl,score
	ld	de,score+1
	ld	bc,blaster_face-score
	ldir
	ld	a,$80
	ld	(blaster_x),a
	ret

irq:	push	ix
	ld	a,(collision)
	and	a
	call	nz,award_point
	ld	de,4			; Sprite stride value

	call	read_joystick

	ld	ix,sprattrs
	ld	a,(blaster_x)
	add	h
	cp	$0a
	jr	z,1f
	cp	$f0
	jr	nz,2f
1	sub	h
2	ld	(blaster_x),a
	ld	a,h			; Did we move at all?
	or	a
	jr	z,1F
	rlca				; Save the sign bit as LSB
	and	1
	ld	(blaster_face),a
1	ld	a,(blaster_face)	; Check facing
	rrca				; C = facing left
	ld	a,(blaster_x)
	jr	c,1F
	sub	5			; Right-facing
	ld	(ix+2),$6c
	ld	(ix+6),$70
	ld	(ix+10),$74
	jr	2F
1	sub	10			; Left-facing
	ld	(ix+2),$60
	ld	(ix+6),$64
	ld	(ix+10),$68
2	ld	(ix+1),a
	ld	(ix+5),a
	ld	(ix+9),a

	ld	b,3
	ld	ix,sprattrs+12		; Targets
.targetlp:
	ld	a,(ix)			; Load Y coordinate
	add	l
	cp	a,$0a
	jr	z,1f
	cp	a,$8a
	jr	nz,2f
1	sub	l
2	ld	(ix),a
	ld	a,(ix+1)		; Load X coordinate
	and	a
	jr	nz,.txok
	ld	a,(ix+3)		; At zero. Are we early-clock?
	and	a
	jp	m,.tclk
	ld	(ix+3),$86		; Set early clock
	ld	a,$20			; and reset position
	jr	.txok
.tclk:	ld	(ix+3),$06		; Set normal clock
	xor	a			; and wrap around
.txok:	sub	2
	ld	(ix+1),a
	add	ix,de
	djnz	.targetlp

	ld	b,8			; 8 shots
	ld	a,(collision)		; Cache collision data in C
	ld	c,a
	ld	a,(sprattrs+12)		; Targets' Y coordinate
	ld	h,a
	ld	l,0			; Lowest shot found so far
.shotlp:
	ld	a,(ix)			; Load shot Y coord
	cp	$c0			; Is it offscreen?
	jr	z,.next
	bit	5,c			; Collision?
	jr	z,.doshot		; If not, proceed
	neg				; Compute target Y - shot Y + 3
	add	h
	add	3
	cp	17			; Is distance <= 16?
	jr	nc,.nohit		; if not, shot still in flight
	ld	c,0			; Otherwise, acknowledge hit,
	ld	a,$c0			; delete shot...
	jr	.next			; and skip update
.nohit:	ld	a,(ix)			; Restore original Y coord on no hit
.doshot:
	sub	2
	cp	$ff			; Off top of screen?
	jr	nz,1F
	ld	a,$c0			; If so, move sprite offscreen
	jr	.next
1	cp	l			; Lower than previous low?
	jr	c,.next
	ld	l,a			; If so, new low
.next:	ld	(ix),a			; Store Y coordinate back
	add	ix,de			; Next shot
	djnz	.shotlp
	ld	a,l			; Is there room for a new shot?
	cp	$76
	jr	nc,.noshot
	ld	a,(fire)		; Either fire button pressed?
	and	a
	jr	z,.noshot
	ld	ix,sprattrs+24		; Reset IX to first shot
	ld	b,8
1	ld	a,(ix)			; Is this shot offscreen?
	cp	$c0
	jr	z,2F			; If so, found
	add	ix,de			; If not, next shot
	djnz	1B
	jr	.noshot			; No free shots
2	ld	(ix),$89		; Set new shot Y coordinate
	ld	a,(blaster_x)		; Copy Blaster X coordinate to new shot
	ld	(ix+1),a
.noshot:
	call	blit_sprites
	pop	ix
	ret

award_point:
	push	hl
	push	de
	push	bc
	ld	hl,score
	ld	a,(hl)
	inc	a
	daa
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	adc	$00
	daa
	ld	(hl),a
	ld	b,2
1	inc	hl
	ld	c,a
	rlca
	rlca
	rlca
	rlca
	and	$0f
	add	$08
	ld	(hl),a
	inc	hl
	ld	a,c
	and	$0f
	add	$08
	ld	(hl),a
	ld	a,(score)
	djnz	1b
	call	blit_score
	pop	bc
	pop	de
	pop	hl
	ret

gfx_score:
	db	1,2,3,4,5,6,0,8,8,8,8
gfx_pat:
	db	$00,$3c,$60,$3c,$02,$62,$3c,$00 ; $01: S
	db	$00,$3c,$62,$60,$60,$62,$3c,$00 ; $02: C
	db	$00,$3c,$62,$62,$62,$62,$3c,$00 ; $03: O
	db	$00,$7c,$66,$7c,$68,$64,$62,$00 ; $04: R
	db	$00,$7e,$60,$7c,$60,$60,$7e,$00 ; $05: E
	db	$00,$00,$18,$00,$00,$18,$00,$00 ; $06: Colon
	db	$00,$00,$ff,$ff,$00,$00,$00,$00 ; $07: Divider line
	db	$00,$3c,$66,$6a,$72,$62,$3c,$00 ; $08: 0
	db	$00,$18,$38,$18,$18,$18,$7e,$00 ; $09: 1
	db	$00,$3c,$66,$06,$3c,$60,$7e,$00 ; $0a: 2
	db	$00,$3c,$42,$1c,$02,$62,$3c,$00 ; $0b: 3
	db	$00,$62,$62,$7e,$02,$02,$02,$00 ; $0c: 4
	db	$00,$7e,$60,$7e,$02,$62,$3c,$00 ; $0d: 5
	db	$00,$3c,$60,$7c,$62,$62,$3c,$00 ; $0e: 6
	db	$00,$7e,$04,$08,$10,$20,$60,$00 ; $0f: 7
	db	$00,$3c,$62,$3c,$62,$62,$3c,$00 ; $10: 8
	db	$00,$3c,$62,$3e,$02,$62,$3c,$00 ; $11: 9
gfx_sprpat:
	db	$00,$00,$00,$00,$00,$f8,$18,$18 ; $60: Blaster L-A
	db	$18,$ff,$ff,$e7,$c3,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$ff,$ff,$f9,$f0,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$02,$03 ; $64: Blaster L-B
	db	$02,$00,$00,$00,$00,$00,$00,$00
	db	$00,$20,$20,$70,$a8,$f8,$aa,$fe
	db	$fa,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$e0,$e0 ; $68: Blaster L-C
	db	$e0,$00,$00,$18,$3c,$18,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$06,$0f,$06,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00 ; $6C: Blaster R-A
	db	$00,$ff,$ff,$9f,$0f,$00,$00,$00
	db	$00,$00,$00,$00,$00,$1f,$18,$18
	db	$18,$ff,$ff,$e7,$c3,$00,$00,$00
	db	$00,$04,$04,$0e,$15,$1f,$55,$7f ; $70: Blaster R-B
	db	$5f,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$40,$c0
	db	$40,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00 ; $74: Blaster R-C
	db	$00,$00,$00,$60,$f0,$60,$00,$00
	db	$00,$00,$00,$00,$00,$00,$07,$07
	db	$07,$00,$00,$18,$3c,$18,$00,$00
	db	$03,$0f,$1c,$30,$63,$66,$cc,$c9 ; $78: Target A
	db	$c9,$cc,$66,$63,$30,$1c,$0f,$03
	db	$c0,$f0,$38,$0c,$c6,$66,$33,$93
	db	$93,$33,$66,$c6,$0c,$38,$f0,$c0
	db	$00,$00,$00,$00,$00,$00,$00,$00 ; $7C: Missile
	db	$00,$00,$80,$80,$80,$80,$80,$80
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
gfx_sprattr:
	db	$99,$78,$6c,$0c,$99,$78,$70,$09
	db	$99,$78,$74,$0e,$38,$38,$78,$06
	db	$38,$78,$78,$06,$38,$b8,$78,$06
	db	$c0,$78,$7c,$0b,$c0,$78,$7c,$0b
	db	$c0,$78,$7c,$0b,$c0,$78,$7c,$0b
	db	$c0,$78,$7c,$0b,$c0,$78,$7c,$0b
	db	$c0,$78,$7c,$0b,$c0,$78,$7c,$0b
	db	$d0
