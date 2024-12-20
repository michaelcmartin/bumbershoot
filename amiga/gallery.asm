;;; ----------------------------------------------------------------------
;;;  Gallery.asm: Simple shooting gallery game
;;;    (c) 2024, Michael C. Martin
;;;  Available under the MIT license; see LICENSE for details.
;;; ----------------------------------------------------------------------

	;; Register definitions and startup code from reference material
	include	"include/BareMetal.i"
	include	"include/SafeStart.i"

spr_blocks:
	dc.w	4,0,12,16,20,0,24,0

Main:	bsr	init_sprites

	lea	Copper,a2		; a2 = copper list base addr
	lea	bmp,a3			; a3 = graphics buffer base addr
	move.l	a3,d0			; Load bitplane location into copper list
	move.w	d0,6(a2)
	swap	d0
	move.w	d0,2(a2)
	lea	spr_blocks(PC),a0
	lea	sprite_ptrs,a4
	lea	12(a2),a1		; Load sprite definitions into place
	moveq	#7,d1
.sprlp:	move.w	(a0)+,d0
	move.l	(a4,d0),d0
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)
	add	#8,a1
	dbra	d1,.sprlp

	move.l	a2,COP1LC(a5)		; Set primary copper list

.start:	move.w	#$81e0,DMACON(a5)	; Enable Bitplane, Copper, Sprite, and Blitter DMA

	;; Clear screen
	bsr	blitter_wait
	move.l	#$01000000,BLTCON0(a5)
	move.l	a3,BLTDPT(a5)
	clr.w	BLTDMOD(a5)
	move.w	#256*64+20,BLTSIZE(a5)
	bsr	blitter_wait

	;; Draw score and footer
	lea	msg,a0
	lea	25(a3),a1
	bsr	drawtext

	;; Initialize collision control
	move.w	#$2041,CLXCON(a5)	; Match bitplane 1 hits, sprite 3 can collide

	;; Set up keyboard and VBLANK IRQs
	moveq	#0,d0
	move.b	d0,key_pending
	move.b	d0,key_ready
	move.l	S_VBR,a0		; Save out original handler
	move.l	IRQ2(a0),-(a7)
	move.l	IRQ3(a0),-(a7)
	lea	irq2_handler(pc),a1
	move.l	a1,IRQ2(a0)
	lea	irq3_handler(pc),a1
	move.l	a1,IRQ3(a0)
	move.w	#$8028,INTENA(a5)	; Enable PORTS and VERTB interrupts

;;; ----------------------------------------------------------------------

.gameloop:
	;; Wait for VBLANK to process the data we have already
	move.b	gfx_ready,d0
	bne.s	.gameloop

	move.w	CLXDAT(a5),d0		; Load and clear collision data
	and.w	#$6000,d0		; Was there a hit this frame?
	beq.s	.hit_done		; If not, we're done
	lea	spr_missiles-4,a0	; If so, start scanning missiles
	move.b	target_y,d0		; Set up target bounds in d0 and d1
	move.b	d0,d1			; d0 = top (inclusive)
	add.b	#16,d1			; d1 = bottom (exclusive)
.hitlp:	add	#4,a0			; Advance missile pointer
	tst.l	(a0)			; At end of missile list?
	beq.s	.hit_done		; No collision
	cmp.b	(a0),d1			; Does missile start after target?
	bls.s	.hitlp			; If so, it's not this missile
	cmp.b	2(a0),d0		; Does missile end before target?
	bcc.s	.hitlp			; If so, it's not this missile.
	bsr	delete_missile		; If not, it *is* this missile...
	bsr	award_point		; ...so delete it and award a point
.hit_done:

	;; Read directional input
	move.w	JOY1DAT(a5),d0
	move.w	d0,d1			; XOR bits 1 and 9 into bits 0 and 8
	lsr.w	#1,d1			; to correct vertical bits
	and.w	#$101,d1
	eor.w	d1,d0			; d0 bits 0189 are down/right/up/left

	;; Adjust player location and sprite
	move.b	player_x,d1
	lea	spr_player,a0
	btst	#9,d0			; Pressing left?
	beq.s	.not_left
	cmp.b	#$48,d1			; At left boundary?
	beq.s	.not_left
	subq	#1,d1			; If it's OK, move left...
	move.b	d1,d2			; and compute and update sprite location and facing
	subq	#5,d2
	move.b	d2,1(a0)
	clr.b	3(a0)
.not_left:
	btst	#1,d0			; Pressing right?
	beq.s	.not_right
	cmp.b	#$d8,d1			; At right boundary?
	beq.s	.not_right
	addq	#1,d1			; If it's OK, move right...
	move.b	d1,d2			; and compute and update sprite location and facing
	subq	#3,d2
	move.b	d2,1(a0)
	move.b	#1,3(a0)
.not_right:
	move.b	d1,player_x		; Record updated blaster position

	;; Adjust target locations and sprites
	move.b	target_y,d1
	lea	spr_targets,a0
	btst	#0,d0			; Pressing down?
	beq.s	.not_down
	cmp.b	#$dc,d1			; At bottom boundary?
	beq.s	.not_down
	addq	#2,d1			; If OK, move down
.not_down:
	btst	#8,d0			; Pressing up?
	beq.s	.not_up
	cmp.b	#$3c,d1			; At top boundary?
	beq.s	.not_up
	subq	#2,d1			; If OK, move up
.not_up:
	move.b	d1,target_y		; Record updated target position
	move.b	d1,(a0)			; Store new y-start positions for all targets
	move.b	d1,4(a0)
	move.b	d1,8(a0)
	add.b	#$10,d1			; Store new y-end positions for all targets
	move.b	d1,2(a0)
	move.b	d1,6(a0)
	move.b	d1,10(a0)
	sub.b	#1,1(a0)		; Move the targets left
	sub.b	#1,5(a0)
	sub.b	#1,9(a0)

	;; Update shot
	lea	spr_missiles,a0
	move.b	(a0),d0			; Are there any shots?
	beq.s	.shot_available		; If not, nothing to do, and shooting is OK
	cmp.b	#$3a,d0			; Is the top shot at the boundary?
	bne.s	.shot_in_range
	bsr	delete_missile		; If so, destroy it
.shot_in_range:
	moveq	#0,d0			; Initialize "final missile" to "no missile"
.shot_lp:
	tst.w	(a0)			; End of missile list?
	beq.s	.shots_moved
	sub.b	#2,(a0)			; Advance missile
	sub.b	#2,2(a0)
	move.l	(a0)+,d0		; Save advanced missile, update list ptr
	bra.s	.shot_lp
.shots_moved:
	cmp.w	#$e000,d0		; Is there space for a new missile?
	bcc.s	.shot_done		; If not, don't check fire button
.shot_available:
	btst	#7,CIAAPRA		; Fire button pressed?
	bne.s	.shot_done
	move.l	#$f000f600,(a0)
	move.b	player_x,1(a0)
	clr.l	4(a0)
.shot_done:

	;; Update actual graphics state
	lea	sprite_ptrs+4,a0	; Start at first player control block
	lea	spr_player,a1
	move.l	(a0)+,a2		; Update player control on left-facing case
	move.l	(a1),d0
	move.l	d0,(a2)
	move.l	a2,d1			; Remember left-facing control block
	btst	#0,d0			; Are we on an odd pixel?
	beq.s	.update_copper		; If not, d1 is fine...
	move.l	(a0),d1			; But if so, use the right-facing graphic
.update_copper:
	lea	Copper+14,a2		; Update Sprite 0 pointer in the copper list
	move.w	d1,4(a2)
	swap	d1
	move.w	d1,(a2)
	moveq	#3,d0			; Update other facing, and all three targets
.ezlp:	move.l	(a0)+,a2		; (the easy cases)
	move.l	(a1)+,(a2)
	dbra	d0,.ezlp
	move.l	(a0),a2			; Load initial missile block (skip sprite 5)
.shlp:	move.l	(a1)+,(a2)		; Load missile block
	beq.s	.done			; If that was terminator, we're done!
	add	#MISSILE_SIZE,a2	; Otherwise skip graphics to next control block
	bra.s	.shlp
.done:

	;; Uncomment the block below to produce scanline-measuring chatter
	;; in the upper left corner of the playfield
;	move.w	VHPOSR(a5),d0		; Record final scanline
;	lea	bmp,a0
;	move.l	#$00ff10ff,(a0)		; Draw guide bars
;	move.w	d0,42(a0)

	;; End frame
	move.b	#1,gfx_ready		; Alert VBLANK handler to signal us
	tst.b	key_ready		; Loop back if ESC not pressed
	beq	.gameloop

;;; ----------------------------------------------------------------------

	;; Clean up interrupt handlers
.end:	move.w	#$0028,INTENA(a5)
	move.l	S_VBR,a0
	move.l	(a7)+,IRQ3(a0)
	move.l	(a7)+,IRQ2(a0)
	;; Return to SafeStart to return control to OS
	rts

irq2_handler:
	movem.l	d0-d3,-(a7)		; Save out registers

	move.b	CIAAICR,d0
	btst	#3,d0			; Was this the keyboard interrupt?
	bne.s	.kb			; If so, handle key event
	btst	#0,d0			; Was this Timer A?
	beq.s	.end			; If not, skip everything

	bclr.b	#6,CIAACRA		; If so, finish handshake
	move.b	#$01,CIAAICR		; Disable Timer A interrupt
	move.b	key_pending,key_ready	; And confirm keystroke
	bra.s	.end

.kb:	move.b	CIAASDR,d0		; Read actual keyboard data
	cmp.b	#$75,d0			; Was it pressing ESCAPE?
	bne.s	.handshake		; If not, ignore it
	move.b	#$ff,key_pending	; Otherwise, record pending keypress

.handshake:
	move.b	#$48,CIAACRA		; Serial output, single-shot timer on A
	clr.b	CIAASDR			; Serial signal low
	move.b	#75,CIAATALO		; for 75 ticks
	clr.b	CIAATAHI
	move.b	#$81,CIAAICR		; Enable Timer A interrupt

.end:	move.w	#$0008,$dff000+INTREQ	; Acknowledge PORTS IRQ
	movem.l	(a7)+,d0-d3
	rte

irq3_handler:
	movem.l	d0-1/a0-2,-(a7)
	move.b	gfx_ready,d0		; Is the graphics info ready yet?
	beq.s	.end
	clr.b	gfx_ready		; Tell the main loop it's time to update again
.end:	move.w	#$0020,$dff000+INTREQ	; Acknowledge VERTB IRQ
	movem.l	(a7)+,d0-1/a0-2
	rte

	;; Copy 1bpp text string (a0) to graphics memory (a1).
drawtext:
	movem.l	a2-4,-(a7)
	lea	font,a2
.loop:	moveq	#0,d0			; Read next character
	move.b	(a0)+,d0
	beq.s	.done			; Quit if it's the null terminator
	and.b	#63,d0			; Convert to screencode
	lsl.w	#3,d0			; Put address of char in a3
	lea	(a2,d0),a3
	move.l	a1,a4			; Draw character
	moveq	#7,d1
.char:	move.b	(a3)+,(a4)
	add	#40,a4
	dbra	d1,.char
	addq	#1,a1			; Advance to next char position
	bra.s	.loop
.done:	movem.l	(a7)+,a2-4
	rts

	;; Score a point and update the score display.
award_point:
	moveq	#3,d0
	lea	score,a0
	lea	32+bmp,a1
.lp:	move.b	(a0,d0),d1
	addq	#1,d1
	move.b	d1,(a0,d0)
	cmp.b	#$3a,d1
	bne.s	.done
	move.b	#$30,(a0,d0)
	dbra	d0,.lp
.done:	bra.s	drawtext

blitter_wait:
	btst	#14,DMACONR(a5)		; Amiga 1000 compat dummy read
.lp:	btst	#14,DMACONR(a5)
	bne.s	.lp
	rts

;;; ----------------------------------------------------------------------
;;;  Replicate and format sprite data in chip memory
;;; ----------------------------------------------------------------------

init_sprites:
	move.l	a2,-(a7)
	lea	spritebuf,a0
	lea	sprite_ptrs,a1
	move.l	a0,(a1)+		; Handle the "no graphic" case
	clr.l	(a0)+
	lea	gfx_blaster_l,a2
	bsr	.load_sprite
	lea	gfx_blaster_r,a2
	bsr	.load_sprite
	moveq	#2,d0
.lp1:	lea	gfx_target,a2
	bsr	.load_sprite
	dbra	d0,.lp1
	lea	gfx_missile,a2
	bsr	.load_sprite
	moveq	#14,d0
.lp2:	lea	gfx_missile,a2		; 16 potential entries for the missile
	bsr	.lslp
	dbra	d0,.lp2
	move.l	a0,(a1)			; Save final address
	move.l	(a7)+,a2
	rts
.load_sprite:
	move.l	a0,(a1)+		; Save sprite location
	clr.l	(a0)+			; Leave space for control code
.lslp:	move.l	(a2)+,(a0)+
	bne.s	.lslp
	rts

;;; ----------------------------------------------------------------------
;;;  Missile management routines
;;; ----------------------------------------------------------------------

	;; Delete the missile at a0. Leaves all registers intact.
delete_missile:
	movem.l	a0-1,-(a7)
	tst.l	(a0)			; Do nothing at end of list!
	beq.s	.done
	lea	4(a0),a1
.lp:	move.l	(a1)+,(a0)+
	bne.s	.lp
.done:	movem.l	(a7)+,a0-1
	rts

;;; ----------------------------------------------------------------------
;;;  Public memory data
;;; ----------------------------------------------------------------------

	data
font:	incbin	"res/sinestra.bin"
msg:	dc.b	"SCORE: "
score:	dc.b	"0000",0

	;; Game flow state machine
gfx_ready:	dc.b	1
key_pending:	dc.b	0
key_ready:	dc.b	0

	;; Abstract game state
player_x:	dc.b	$90
target_y:	dc.b	$50
	even

spr_player:	dc.l	$ef8dfc01
spr_targets:	dc.l	$506c6000, $508c6000, $50ac6000
spr_missiles:	dcb.l	17

gfx_blaster_l:
	dc.w	%0000000000100000, %0000000000100000
	dc.w	%0000000000100000, %0000000000100000
	dc.w	%0000000001110000, %0000000001110000
	dc.w	%0000000010101000, %0000000010101000
	dc.w	%0000000011111000, %1111100011111000
	dc.w	%1110001010101010, %0001101010101010
	dc.w	%1110001111111110, %0001101111111110
	dc.w	%1110001011111010, %0001101011111010
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0001100000000110, %1110011111111001
	dc.w	%0011110000001111, %1100001111110000
	dc.w	%0001100000000110, %0000000000000000
	dc.w	0,0

gfx_blaster_r:
	dc.w	%0000010000000000, %0000010000000000
	dc.w	%0000010000000000, %0000010000000000
	dc.w	%0000111000000000, %0000111000000000
	dc.w	%0001010100000000, %0001010100000000
	dc.w	%0001111100000000, %0001111100011111
	dc.w	%0101010101000111, %0101010101011000
	dc.w	%0111111111000111, %0111111111011000
	dc.w	%0101111101000111, %0101111101011000
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0000000000000000, %1111111111111111
	dc.w	%0110000000011000, %1001111111100111
	dc.w	%1111000000111100, %0000111111000011
	dc.w	%0110000000011000, %0000000000000000
	dc.w	0,0

gfx_target:
	dc.w	%0000001111000000, %0000001111000000
	dc.w	%0000111111110000, %0000110000110000
	dc.w	%0001111111111000, %0001001111001000
	dc.w	%0011110000111100, %0010111111110100
	dc.w	%0111101111011110, %0101111111111010
	dc.w	%0111011111101110, %0101111001111010
	dc.w	%1110111111110111, %1011110110111101
	dc.w	%1110111001110111, %1011101111011101
	dc.w	%1110111001110111, %1011101111011101
	dc.w	%1110111111110111, %1011110110111101
	dc.w	%0111011111101110, %0101111001111010
	dc.w	%0111101111011110, %0101111111111010
	dc.w	%0011110000111100, %0010111111110100
	dc.w	%0001111111111000, %0001001111001000
	dc.w	%0000111111110000, %0000110000110000
	dc.w	%0000001111000000, %0000001111000000
	dc.w	0,0

gfx_missile:
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%1000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%0000000000000000, %1000000000000000
	dc.w	%1000000000000000, %0000000000000000
	dc.w	0,0
MISSILE_SIZE	= *-gfx_missile

;;; ----------------------------------------------------------------------
;;;  Chipmem data: Copper list and graphics data
;;; ----------------------------------------------------------------------

	data_c

Copper:
	;; Bitplane pointers
	dc.w	BPL1PTH,0
	dc.w	BPL1PTL,0
	dc.w	$1807,$fffe	; Give IRQ time to run; it updates ptrs below
	;; Sprite pointers
	dc.w	SPR0PTH,0
	dc.w	SPR0PTL,0
	dc.w	SPR1PTH,0
	dc.w	SPR1PTL,0
	dc.w	SPR2PTH,0
	dc.w	SPR2PTL,0
	dc.w	SPR3PTH,0
	dc.w	SPR3PTL,0
	dc.w	SPR4PTH,0
	dc.w	SPR4PTL,0
	dc.w	SPR5PTH,0
	dc.w	SPR5PTL,0
	dc.w	SPR6PTH,0
	dc.w	SPR6PTL,0
	dc.w	SPR7PTH,0
	dc.w	SPR7PTL,0
	;; Initial palette
	dc.w	COLOR0,$005a
	dc.w	COLOR1,$0fff
	dc.w	COLOR17,$0555
	dc.w	COLOR18,$00a5
	dc.w	COLOR19,$0fa5
	dc.w	COLOR21,$0a00
	dc.w	COLOR22,$000a
	dc.w	COLOR23,$0fff
	dc.w	COLOR25,$0a00
	dc.w	COLOR26,$000a
	dc.w	COLOR27,$0fff
	dc.w	COLOR29,$0550
	dc.w	COLOR30,$0aa0
	dc.w	COLOR31,$0ff0
	;; Display boundaries
	dc.w	DIWSTRT,$2c81
	dc.w	DIWSTOP,$2cc1
	;; DMA boundaries
	dc.w	DDFSTRT,$38
	dc.w	DDFSTOP,$d0
	;; Fixed configuration
	dc.w	BPL1MOD,0	; No modulo
	dc.w	FMODE,0		; Slow DMA on post-OCS
	dc.w	BPLCON0,$1200	; 1 bitplane, low-res, color on composite
	dc.w	BPLCON1,0	; Nothing else special
	dc.w	BPLCON2,0
	;; Draw divider line with Copper
	dc.w	$380f,$fffe
	dc.w	COLOR0,$0fff
	dc.w	$3a0f,$fffe
	dc.w	COLOR0,$005a
	;; Draw ground with Copper
	dc.w	$fc0f,$fffe
	dc.w	COLOR0,$0270
	;; Wait for end of frame
	dc.w	$ffff,$fffe

	bss_c
bmp:		ds.b	40*256

spritebuf:	ds.b	1024
spritebuf_end:

	bss
;; Graphics state vars
sprite_ptrs:	ds.l	8
