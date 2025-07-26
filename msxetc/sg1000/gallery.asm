;;;----------------------------------------------------------------------
;;;  Shooting Gallery: SG-1000 edition, all-in-one
;;;  This is a more-or-less direct port of the TI-99 edition, since it
;;;  shares a VDP. The ultimate plan is to refactor the code into a game
;;;  core that can abstract away the platform differences between each
;;;  Z80+VDP platform.
;;;----------------------------------------------------------------------

	include	"sg1000bios.asm"

sprattrs     # 48
score        #  2

main:	ld	de,init_reg		; Init registers
	ld	h,0
	ld	b,8
.reglp:	ld	a,(de)
	inc	de
	ld	l,a
	rst	set_vdp_register
	inc	h
	djnz	.reglp
	;; Draw static screen
	ld	a,$07			; Draw divider line
	ld	bc,$0020
	ld	de,$0020
	rst	fill_vram
	ld	a,$68			; Draw ground
	ld	bc,$0060
	ld	de,$02a0
	rst	fill_vram
	ld	a,$f0			; Initialize Color RAM
	ld	bc,$0020		; Most everything is white on black
	ld	de,$0380
	rst	fill_vram
	ld	a,$22			; Ground is green
	ld	de,$38d
	rst	write_vram
	ld	hl,initial_gfx
	ld	bc,$000b		; Score display
	ld	de,$0014
	rst	blit_vram
	;; Initialize graphics patterns
	ld	bc,$0088		; Tile graphics
	ld	de,$0808
	rst	blit_vram
	ld	bc,$0018		; Sprite graphics
	ld	de,$0b00
	rst	blit_vram
	ld	bc,$0030		; Load sprite attrs to CPU RAM
	ld	de,sprattrs
	ldir
	ld	bc,$0030		; Then blit them to VRAM
	ld	de,$0300
	ld	hl,sprattrs
	rst	blit_vram
	ld	a,$d0			; Write sprite terminator
	out	(VDPDATA),a
	;;	Set up interrupt handler
	ld	hl,irq
	ld	(irqvec),hl
	ei
	ld	hl,$01e1
	rst	set_vdp_register

.ever:	halt
	jr	.ever

irq:	push	ix
	ld	ix,sprattrs
	ld	a,(vdp_status)
	and	$20			; Isolate collision bit
	call	nz,award_point
	ld	de,4			; Sprite stride value

	ld	a,(joy1)		; Read joystick 1
	ld	c,a
	ld	a,(ix+1)
	ld	h,2			; Target/blaster motion speed
	bit	2,c
	jr	z,1f
	cp	$08
	jr	z,1f
	sub	h
1	bit	3,c
	jr	z,1f
	cp	$e8
	jr	z,1f
	add	h
1	ld	(ix+1),a

	ld	b,3
	add	ix,de
.targetlp:
	ld	a,(ix)			; Load Y coordinate
	bit	0,c
	jr	z,1f
	cp	a,$0c
	jr	z,1f
	sub	h
1	bit	1,c
	jr	z,1f
	cp	a,$88
	jr	z,1f
	add	h
1	ld	(ix),a
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
.txok:	sub	h
	ld	(ix+1),a
	add	ix,de
	djnz	.targetlp

	ld	b,8			; 8 shots
	ld	a,(vdp_status)		; Cache collision data in C
	ld	c,a
	ld	a,(sprattrs+4)		; Targets' Y coordinate
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
	ld	a,(joy1)		; Either fire button pressed?
	and	$30
	jr	z,.noshot
	ld	ix,sprattrs+16		; Reset IX to first shot
	ld	b,8
1	ld	a,(ix)			; Is this shot offscreen?
	cp	$c0
	jr	z,2F			; If so, found
	add	ix,de			; If not, next shot
	djnz	1B
	jr	.noshot			; No free shots
2	ld	(ix),$89		; Set new shot Y coordinate
	ld	a,(sprattrs+1)		; Copy Blaster X coordinate to new shot
	ld	(ix+1),a
.noshot:
	ld	hl,sprattrs		; Blit updated sprites to VRAM
	ld	de,$0300
	ld	bc,$0030
	rst	blit_vram
	pop	ix
	ret

scorebuf # 4

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
	ld	hl,scorebuf
	ld	de,$001b
	ld	bc,$0004
	rst	blit_vram
	pop	bc
	pop	de
	pop	hl
	ret

init_reg:
	db	$00,$80,$00,$0e,$01,$06,$01,$f1

initial_gfx:
	;; Score string
	db	1,2,3,4,5,6,0,8,8,8,8
	;; Font patterns
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
	;; Sprite patterns
	db	$10,$38,$ba,$ba,$fe,$fe,$92,$00 ; $60: Blaster
	db	$00,$3c,$42,$5a,$5a,$42,$3c,$00 ; $61: Target
	db	$00,$00,$00,$00,$00,$10,$10,$10 ; $62: Missile
	;; Starting sprite attributes
	db	$99,$78,$60,$09,$38,$38,$61,$06
	db	$38,$78,$61,$06,$38,$b8,$61,$06
	db	$c0,$78,$62,$0b,$c0,$78,$62,$0b
	db	$c0,$78,$62,$0b,$c0,$78,$62,$0b
	db	$c0,$78,$62,$0b,$c0,$78,$62,$0b
	db	$c0,$78,$62,$0b,$c0,$78,$62,$0b

	ds	$400-$,$ff
