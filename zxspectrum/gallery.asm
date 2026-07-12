	org	$7000
	map	bss_start
;;; Graphics data:  must be first
reversed_blaster # 32
target_gfx # 192
blaster_lgfx # 192
blaster_rgfx # 192
blank_gfx # 192
;;; Game logic data
shot_requested # 1
blaster_x # 1
blaster_old_x # 1
blaster_facing # 1
blaster_old_facing # 1
target_y # 1
target_x # 3
target_old # 2
max_shot_y # 1
num_shots # 1
;;; Shot tables.
shot_y # 16
shot_x # 16
shot_collide # 16
shot_tails # 64				; 32 pointers to erase (0-terminated)
shot_heads # 64				; 16 pointers to shot_head struct

;;; SHOT_HEAD struct: { ptr screen_byte (0 = terminator, always even row)
;;;                     byte x_mask (for collision and compositing)
;;;                     byte index (for recording collision) };

	;; Put our mask list at the top so we know it's all on one
	;; memory page
	jr	1F			; ... and jump past it
x_mask:	defb	$80,$40,$20,$10,$08,$04,$02,$01
1

	call	initialize

main:	halt
	call	render
	call	frame_logic
	call	check_quit
	jr	nz,main

	;; Quit program: clear back to normal display
	ld	a,$38
	jp	clrto

initialize:
	call	clear_bss
	call	create_sprites
	call	init_game_state
	jp	draw_main_screen


render:	call	erase_targets
	call	erase_shot_tails
	call	draw_targets
	call	update_blaster
	jp	draw_shots

frame_logic:
	call	handle_input
	call	move_autonomous
	call	record_display_list
	call	compact_shots
	jp	new_shot

;;; ----------------------------------------------------------------------
;;;   Game initialization
;;; ----------------------------------------------------------------------

clear_bss:
	xor	a
	ld	hl,bss_start
	ld	de,bss_start+1
	ld	bc,bss_end - bss_start - 1
	ld	(hl),a
	ldir
	ret

create_sprites:
	;; Create mirrored blaster
	ld	hl,gfx+32
	ld	de,reversed_blaster
	call	reverse_sprite

	;; Create shifted versions of all sprites. The clear_bss
	;; call has already generated the blank_gfx asset.
	ld	hl,gfx
	ld	ix,target_gfx
	ld	b,3
	jp	shift_sprites

init_game_state:
	;; Initialize sprite positions
	ld	a,64
	ld	(blaster_x),a
	ld	(blaster_old_x),a
	ld	a,1
	ld	(blaster_facing),a
	ld	(blaster_old_facing),a
	ld	a,28
	ld	(target_x),a
	add	32
	ld	(target_x+1),a
	add	32
	ld	(target_x+2),a
	ld	a,20
	ld	(target_y),a

	;; Reset score
	ld	a,$30
	ld	hl,score
	ld	b,4
1	ld	(hl),a
	inc	hl
	djnz	1B
	ret

draw_main_screen:
	ld	a,$02			;; Black screen, red text
	call	clrto			;; for main screen (shots/targets)
	ld	hl,$5a60		;; Blaster track
	ld	a,$06
	ld	b,64
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	a,$20			;; Ground
	ld	b,96
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	hl,$5800		;; Header
	ld	a,$38
	ld	b,32
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	hl,header
	jp	print

;;; ----------------------------------------------------------------------
;;;   Screen rendering
;;; ----------------------------------------------------------------------

;;; Erase two rows at target_old and its successor, if required
erase_targets:
	ld	hl,(target_old)
	ld	a,h
	or	a
	ret z
	push	hl
	xor	a
	ld	(hl),a
	ld	d,h
	ld	e,l
	inc	de
	ld	bc,31
	ldir
	pop	hl
	ld	d,h
	ld	e,l
	inc	d
	ld	bc,32
	ldir
	ret

;;; Erase the bottom two pixels of each shot,
erase_shot_tails:
	ld	hl,shot_tails
1	ld	e,(hl)
	inc	hl
	ld	a,(hl)
	or	a
	ret	z
	ld	d,a
	inc	hl
	xor	a
	ld	(de),a
	inc	d			; Shot trails don't cross cells
	ld	(de),a
	jr	1B
	ret

draw_targets:
	ld	a,(target_y)
	ld	d,a
	ld	b,3
	ld	hl,target_x
1	ld	e,(hl)
	inc	hl
	push	hl
	push	de
	push	bc
	ld	hl,target_gfx
	call	draw_sprite
	pop	bc
	pop	de
	pop	hl
	djnz	1B
	ret

update_blaster:
	;; Erase blaster if necessary
	ld	a,(blaster_old_x)
	ld	hl,blaster_x
	cp	(hl)
	jr	z,.draw_blaster
	ld	hl,blaster_old_facing
	sub	2
	bit	0,(hl)
	jr	z,1F
	sub	3
1	ld	e,a
	ld	d,152
	ld	hl,blank_gfx
	call	draw_sprite
.draw_blaster:
	ld	a,(blaster_x)
	sub	5
	ld	e,a
	ld	d,152
	ld	a,(blaster_facing)
	ld	hl,blaster_lgfx
	or	a
	jr	nz,1F
	ld	hl,blaster_rgfx
	ld	a,e
	add	3
	ld	e,a
1	call	draw_sprite
	ret

draw_shots:
	ld	de,shot_heads
.shotlp:
	;; Load next shot into HL
	ld	a,(de)			; Low byte of shot address
	inc	de
	ld	l,a
	ld	a,(de)			; High byte of shot address (0 = end)
	inc	de
	or	a
	ret	z
	ld	h,a
	ld	a,(de)			; mask for shot location in byte
	;; Leave DE here for now; we'll need to reload it later
	and	(hl)			; Collision?
	jr	z,.no_collision
	inc	de
	push	hl
	ld	hl,shot_collide
	ld	a,(de)
	add	l
	jr	nc,1F
	inc	h
1	ld	l,a
	ld	(hl),1
	pop	hl
	dec	de
.no_collision:
	;; Draw the entire shot in case something erased it
	ld	b,3
.drawlp:
	ld	a,(de)			; Composite shot pixel
	or	(hl)
	ld	(hl),a
	inc	h			; Shots always on even rows,
	ld	a,(de)			; so alternating advances are free
	or	(hl)
	ld	(hl),a
	inc	h			; Advance the other pixels the hard way
	ld	a,7
	and	h
	jr	nz,1F
	ld	a,l
	add	32
	ld	l,a
	jr	c,1F
	ld	a,h
	sub	8
	ld	h,a
1	djnz	.drawlp
	;; Proceed to next shot
	inc	de			; Advance to next shot element
	inc	de
	jr	.shotlp

;;; ----------------------------------------------------------------------
;;;   Frame Update Logic Routines
;;; ----------------------------------------------------------------------

handle_input:
	;; Copy current blaster/target locations to last-frame locations
	ld	hl,blaster_x
	ld	b,2
1	ld	a,(hl)
	inc	hl
	ld	(hl),a
	inc	hl
	djnz	1B
	;; Process keypresses
	call	read_keys
	xor	1			; Store fire button
	ld	(shot_requested),a
	ld	de,blaster_x		; Process left and right
	ld	a,(de)
	add	l
	cp	4			; Bounds-check
	jr	z,1F
	cp	123
	jr	nz,2F
1	sub	l
2	ld	(de),a
	ld	a,l			; Did we press a direction at all?
	or	a
	jr	z,1F
	rlca				; If so, convert sign to 0/1 and
	and	1			; use it as our blaster facing
	ld	(blaster_facing),a
1	ld	de,target_y		; Now process up and down
	ld	a,(de)
	add	h
	add	h
	cp	$08			; Bounds-check the targets
	jr	z,1F
	cp	$8a
	jr	nz,2F
1	sub	h
	sub	h
2	ld	(de),a
	;; Prepare row clears if needed
	ld	de,0
	ld	l,a
	ld	a,h
	or	a
	jr	z,1F
	ld	a,l
	jp	m,.up
	sub	2
	jr	2F
.up:	add	16
2	call	row_addr
1	ld	(target_old),de
	ret

move_autonomous:
	;; Move targets left
	ld	hl,target_x
	ld	b,3
1	ld	a,(hl)
	dec	a
	cp	-32
	jr	nz,2F
	ld	a,128
2	ld	(hl),a
	inc	hl
	djnz	1B
	;; Advance onscreen shots - they go offscreen when Y = 0
	ld	hl,shot_y
	ld	a,(num_shots)
	or	a
	ret	z			; Return immediately if no shots
	ld	b,a
1	ld	a,(hl)
	or	a
	jr	z,2F
	sub	2
	ld	(hl),a
2	inc	hl
	djnz	1B
	ret

	;; Translate surviving shot locations to shot_heads/tails
record_display_list:
	ld	ix,shot_y
	ld	hl,shot_tails
	push	hl
	ld	hl,shot_heads
	ld	a,(num_shots)
	or	a			; Any shots at all?
	jp	z,.done
	ld	b,a
.shotplotlp:
	push	bc
	ld	a,(ix+32)		; Don't keep drawing the head on collision
	or	a
	jr	nz,.checkdel
	ld	a,(ix)			; Also don't draw if we're scrolling off the top
	cp	8
	jr	c,.checkdel
	call	row_addr
	ld	a,(ix+16)
	ld	b,a
	rrca
	rrca
	rrca
	and	$1f
	add	e
	ld	(hl),a
	inc	hl
	ld	(hl),d
	inc	hl
	ld	de,x_mask
	ld	a,b
	and	7
	add	e
	ld	e,a
	ld	a,(de)
	ld	(hl),a
	inc	hl
	pop	bc			; Record shot index
	ld	a,(num_shots)
	sub	b
	ld	(hl),a
	inc	hl
	push	bc
.checkdel:
	pop	bc
	ex	(sp),hl			; Now consider tails
	push	bc
1	ld	a,(ix)
	add	6
	cp	8
	jr	c,.checkhit
	call	row_addr
	ld	a,(ix+16)
	rrca
	rrca
	rrca
	and	$1f
	add	e
	ld	(hl),a
	inc	hl
	ld	(hl),d
	inc	hl
.checkhit:
	ld	a,(ix+32)
	or	a
	jr	z,.nextshot
	ld	a,(ix)			; Delete the rest of the shot too
	add	2			; Don't bother erasing the head we skipped
	call	row_addr
	ld	a,(ix+16)
	rrca
	rrca
	rrca
	and	$1f
	add	e
	ld	e,a
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	inc	d
	inc	d			; Advance the other pixels the hard way
	ld	a,7
	and	d
	jr	nz,1F
	ld	a,e
	add	32
	ld	e,a
	jr	c,1F
	ld	a,d
	sub	8
	ld	d,a
1	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	push	hl
	call	award_point
	pop	hl
	ld	(ix+32),0		; Mark the shot as no longer colliding
	ld	(ix),0			; Mark the shot for deletion/compaction
.nextshot:
	inc	ix
	pop	bc
	ex	(sp),hl			; HL back to pointing at heads
	dec	b
	jp	nz,.shotplotlp
	;; Terminate the heads-and-tails lists
.done:	xor	a
	ld	(hl),a
	inc	hl
	ld	(hl),a
	pop	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	ret

;;; Compact the shot array and update max_shot_y. Trashes ABCDEHL/IX.
compact_shots:
	xor	a			; Max Shot Y starts at 0
	ld	(max_shot_y),a
	ld	a,(num_shots)
	or	a			; No shots? Nothing to compact.
	ret	z
	ld	ix,shot_y		; Read ptr for Y and X
	ld	hl,shot_y		; Write ptr for Y
	ld	de,shot_x		; Write ptr for X
	ld	b,a			; Loop var
	ld	c,a			; Number of surviving shots
.lp:	ld	a,(ix)			; Load next shot Y
	dec	c			; Presumptively delete it
	or	a			; If it's nonzero, don't delete...
	jr	z,.skip
	ld	a,(ix)			; Copy its Y coordinate
	ld	(hl),a
	ld	a,(max_shot_y)		; Compare Y coord to max
	cp	(hl)
	jr	nc,1F
	ld	a,(hl)			; New max!
	ld	(max_shot_y),a
1	ld	a,(ix+16)		; Copy X coordinate
	ld	(de),a
	inc	hl			; Advance the write pointers
	inc	de
	inc	c			; Reverse our deletion count
.skip:	inc	ix			; Advance src ptr even when Y=0
	djnz	.lp
	ld	a,c			; Store out the number of shots
	ld	(num_shots),a
	ret

;;; New shot if max_shot_y is low enough and we have enough space for them.
new_shot:
	ld	a,(shot_requested)	; Are we shooting at all?
	or	a
	ret	z			; If not, nothing to do.
	ld	a,(max_shot_y)		; Lowest shot too low?
	cp	124
	ret	nc			; If so, nothing to do.
	ld	hl,num_shots		; Too many shots already?
	ld	a,(hl)
	cp	16
	ret	z			; If so, nothing to do.
	inc	a
	ld	(hl),a
	ld	l,a
	ld	h,0
	ld	de,shot_y-1
	add	hl,de
	ld	a,146
	ld	(hl),a
	ld	de,16
	add	hl,de
	ld	a,(blaster_x)
	add	a
	ld	(hl),a
	ld	a,(blaster_facing)	; Adjust shot location
	or	a			; if facing right
	ret	nz
	inc	(hl)
	ret

;;; ----------------------------------------------------------------------
;;;   Scoring logic
;;; ----------------------------------------------------------------------

award_point:
	ld	hl,score+3
	ld	b,4
.lp:	ld	a,(hl)
	inc	a
	cp	$3a
	jr	z,.carry
	ld	(hl),a
	jr	.disp
.carry:	ld	(hl),$30
	dec	hl
	djnz	.lp
.disp:	ld	hl,header
	jp	print

;;; ----------------------------------------------------------------------
;;;   Player input routines
;;; ----------------------------------------------------------------------

;;; QAOP controls. Returns DY in H, DX in L
;;;   A 0 (and ZF set) if Space is pressed
;;;   A 1 (and ZF reset) if Space is not pressed
read_keys:
	ld	hl,0
	ld	bc,$fbfe		; Check Q
	in	a,(c)
	rra
	jr	c,1F
	dec	h
1	ld	b,$fd			; Check A
	in	a,(c)
	rra
	jr	c,1F
	inc	h
1	ld	b,$df			; Check P
	in	a,(c)
	rra
	jr	c,1F
	inc	l
1	rra				; Check O
	jr	c,1F
	dec	l
1	ld	b,$7f			; Check SPACE
	in	a,(c)
	and	1			; Set Z if SPACE pressed
	ret

;; Zero flag set if a quit is requested.
;; Quit is requested with CAPS-SHIFT-SPACE (Break)
;; or CAPS-SHIFT-1 (EDIT, Esc in emulators)
check_quit:
	ld	bc,$fefe		; Check SHIFT
	in	a,(c)
	and	1
	ret	nz			; If no SHIFT, done.
	ld	b,$f7			; Check EDIT
	in	a,(c)
	and	1
	ret	z			; If EDIT/ESC, done.
	ld	b,$7f			; Check BREAK
	in	a,(c)
	and	1			; Return Z/NZ on BREAK
	ret

include "zxsprites.asm"

;;; ----------------------------------------------------------------------
;;;   Other graphical support routines
;;; ----------------------------------------------------------------------

clrto:	ld	(iy+83),a		; ATTR-P
	and	$38
	ld	(iy+14),a		; BORDCR
	rrca
	rrca
	rrca
	out	($fe),a
	xor	a
	ld	(iy+84),a		; MASK-P
	ld	(iy+87),a		; P-FLAGS
	call	$0d6b			; CLS
	ld	a,2
	jp	$1601			; CHAN-OPEN

print:	ld	a,(hl)
	inc	hl
	cp	$ff
	ret	z
	rst	$10
	jr	print

;;; ----------------------------------------------------------------------
;;;   Graphics data
;;; ----------------------------------------------------------------------

header:	db	$10,0,$11,7,$16,0,20,"SCORE: "
score:	db	"----",$ff

	;; "gfx" must be last so that the start of the BSS map bumps up against
	;; it. That lets the mirrored sprites show up as part of a contiguous
	;; block for the sprite shifter.
gfx:	defb	$03,$0f,$1c,$30,$63,$66,$cc,$c9,$c9,$cc,$66,$63,$30,$1c,$0f,$03
	defb	$c0,$f0,$38,$0c,$c6,$66,$33,$93,$93,$33,$66,$c6,$0c,$38,$f0,$c0
	defb	$00,$00,$00,$00,$00,$00,$00,$fa,$8b,$ea,$ef,$88,$80,$db,$3c,$18
	defb	$00,$00,$20,$20,$70,$a8,$f8,$aa,$fe,$fa,$ff,$01,$01,$ed,$1e,$0c
bss_start:
bss_end # 1
