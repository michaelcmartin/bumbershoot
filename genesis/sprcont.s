	seg	data
	org	$ff0000
ptr_y:	ds	2
ptr_x:	ds	2

	seg	text
	org	0

;;; -----------------------------------------------------
;;;  Initialization, interrupt and exception vectors
;;; -----------------------------------------------------
	dc.l	0,RESET
	dc.l	BUS_ERROR, ADDR_ERROR, ILLEGAL_INST, ZERO_DIV
	dc.l	CHK_INST, TRAPV_INST, PRIV_VIOLATION, TRACE
	dc.l	LINE_1010, LINE_1111
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,EXTINT,INT
	dc.l	HBL,INT,VBL,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT

;;; -----------------------------------------------------
;;;  Header and metadata
;;; -----------------------------------------------------
	;; Console name, copyright name and date
	dc.b	"SEGA GENESIS    "
	dc.b	"(C)BUMB 2018.FEB"
	;; Domestic Name
	dc.b	"SPRITE AND JOYSTICK TEST                        "
	;; Overseas Name
	dc.b	"SPRITE AND JOYSTICK TEST                        "
	;; Type of product and product/version number
	dc.b	"GM 00000000-00"
	;; Checksum: wordwise sum of all bytes from $200-ROM end
	dc.w	$0000			; Corrected by smdfix
	;; I/O support (J = Joystick)
	dc.b	"J               "
	;; ROM start and end
	dc.l	$00000000, $000fffff	; Corrected by smdfix
	;; RAM start and end
	dc.l	$00ff0000, $00ffffff
	;; Save RAM: 'RA' if active
	dc.b	"  "
	;; Save RAM type: $F820 for save RAM on odd bytes
	dc.w	$2020
	;; Save RAM start and end address; normally $200001 and then
	;; start + 2 * sram_size
	dc.l	$20202020, $20202020
	;; Modem data
	dc.b	"            "
	;; Memo
	dc.b	"                                        "
	;; Permissible regions: Japan, US, Europe
	dc.b	"JUE             "

	include	"reset.s"
	bra	main

;;; Exceptions and interrupts. Pull these out if you intend to
;;; implement them yourself.
BUS_ERROR:
ADDR_ERROR:
ILLEGAL_INST:
ZERO_DIV:
CHK_INST:
TRAPV_INST:
PRIV_VIOLATION:
TRACE:
LINE_1010:
LINE_1111:
EXTINT:
INT:
HBL:
VBL:
	rte

	include "text.s"
	include "joystick.s"
	include	"z80load.s"

main:	subq	#8,sp			; Reserve space for fn args

	move.l	#sinestra,(sp)
	bsr	LoadFont

	move.l	#(CRAM_WRITE << 16),(sp)
	bsr	SetVRAMPtr
	move.l	#$00000eee,$c00000

	move.l	#headers,(sp)
	bsr	DrawStrings

	bsr	init_sprites

	lea	NyanCat,a0
	move.w	#NyanCat_len,d0
	moveq	#0,d1
	bsr	Z80Load

	move.w	#$8144,$c00004

	moveq	#$0,d7
	lea	upstr(pc),a3
mainlp: move.l	VRAM_CONTROL(pc),a0
.v1:	move.w	(a0),d0
	btst	#3,d0			; Wait for no VBLANK
	bne.s	.v1
.v2:	move.w	(a0),d0
	btst	#3,d0			; Wait for VBLANK
	beq.s	.v2
	;; Clear the control display
	move.l	#(VRAM_WRITE << 16) | ($C000+128*11),(sp)
	bsr	SetVRAMPtr
	moveq	#$0,d0
	subq.l	#4,a0			; VRAM_DATA
	move.w	#64*5-1,d1
.clr:	move.w	d0,(a0)
	dbra	d1,.clr

	;; Now display the controls that are active
	lea	button_table(pc),a2
	bsr	ReadJoy1
	move.w	d0,d2
	move.w	d0,d7
	moveq	#$7,d3
.dlp:	moveq	#0,d4
	move.w	(a2)+,d4
	lsr	#1,d2
	bcc.s	.dnxt
	move.w	(a3,d4.w),(sp)
	move.w	#0,2(sp)
	lea	2(a3,d4.w),a0
	move.l	a0,4(sp)
	bsr	WriteStr
.dnxt:	dbra	d3,.dlp

	;; Now update the sprite position
	move.w	d7,(sp)
	bsr	move_cursor
	move.l	#(VRAM_WRITE << 16) | $A820,(sp)
	bsr	SetVRAMPtr
	lea	ptr_y,a0
	move.l	VRAM_DATA(pc),a1
	move.w	(a0)+,(a1)
	move.l	#$22002,(a1)		; Middle sprite table bits are fixed
	move.w	(a0),(a1)

	;; Back to main loop
	addq.b	#1,d7
	bra	mainlp

DrawStrings:
	move.l	4(sp),a0
	subq	#8,sp
	move.w	#0,2(sp)
.lp:	move.w	(a0)+,d0
	beq.s	.done
	move.w	d0,(sp)
	move.l	a0,4(sp)
	bsr	WriteStr
	move.l	d0,a0
	bra.s	.lp
.done:	addq	#8,sp
	rts

init_sprites:
	move.l	a2,-(sp)
	;; Step 1: Load up our sprite images
	move.l	VRAM_DATA(pc),a2
	move.w	#$8f02,4(a2)
	move.l	#(VRAM_WRITE << 16) | $0020,-(sp)
	bsr	SetVRAMPtr
	lea	sprite_img(pc),a0
	moveq	#$0f,d0
.lp:	move.l	(a0)+,(a2)
	dbra	d0,.lp
	;; Step 2: Load up our sprite colors
	move.l	#(CRAM_WRITE << 16) | $0020,(sp)
	bsr	SetVRAMPtr
	moveq	#$07,d0
	moveq	#$00,d1
.lp2:	move.w	d1,(a2)
	add	#$0022,d1
	dbra	d0,.lp2
	;; Step 3: Load up our sprite attributes
	move.l	#(VRAM_WRITE << 16) | $A800,(sp)
	bsr	SetVRAMPtr
	lea	sprite_attrs(pc),a0
	moveq	#$09,d0
.lp3:	move.l	(a0)+,(a2)
	dbra	d0,.lp3
	;; Step 4: Load the initial cursor position into place
	lea	ptr_y,a0
	move.w	#128+112,(a0)+
	move.w	#128+160,(a0)
	;; Clean up on the way out
	addq.l	#4,sp
	move.l	(sp)+,a2
	rts

move_cursor:
	move.w	4(sp),d0
	lea	ptr_y,a0
	move.w	(a0),d1
.up:	lsr	#1,d0
	bcc.s	.down
	subq.w	#1,d1
.down:	lsr	#1,d0
	bcc.s	.ychk
	addq	#1,d1
.ychk:	cmp.w	#128,d1
	bge.s	.ychk2
	move.w	#128,d1
.ychk2: cmp.w	#128+224,d1
	blt.s	.left
	move.w	#128+223,d1
.left:	move.w	d1,(a0)+
	move.w	(a0),d1
	lsr	#1,d0
	bcc.s	.right
	subq.w	#1,d1
.right: lsr	#1,d0
	bcc.s	.xchk
	addq.w	#1,d1
.xchk:	cmp.w	#128,d1
	bge.s	.xchk2
	move.w	#128,d1
.xchk2:	cmp.w	#128+320,d1
	blt.s	.done
	move.w	#128+319,d1
.done:	move.w	d1,(a0)
	rts

sinestra:
	incbin	"res/sinestra.bin"

headers:
	align	2
	dc.w	$c000 + 128*2 + 14
	dc.b	"SPRITE AND CONTROLLER TEST",0
	align	2
	dc.w	$c000 + 128*26 + 14
	dc.b	"BUMBERSHOOT SOFTWARE, 2018",0
	align	2
	dc.w	$0000
upstr:	dc.w	$c000 + 128*11 + 22
	dc.b	"UP",0
	align	2
dnstr:	dc.w	$c000 + 128*15 + 20
	dc.b	"DOWN",0
	align	2
lfstr:	dc.w	$c000 + 128*13 + 10
	dc.b	"LEFT",0
	align	2
rtstr:	dc.w	$c000 + 128*13 + 30
	dc.b	"RIGHT",0
	align	2
a_str:	dc.w	$c000 + 128*13 + 48
	dc.b	"A",0
	align	2
b_str:	dc.w	$c000 + 128*13 + 52
	dc.b	"B",0
	align	2
c_str:	dc.w	$c000 + 128*13 + 56
	dc.b	"C",0
	align	2
ststr:	dc.w	$c000 + 128*13 + 60
	dc.b	"START",0
	align	2
button_table:
	dc.w	upstr-upstr,dnstr-upstr,lfstr-upstr,rtstr-upstr
	dc.w	a_str-upstr,b_str-upstr,c_str-upstr,ststr-upstr

sprite_img:
	dc.l	$70000007
	dc.l	$07000070
	dc.l	$00700700
	dc.l	$00077000
	dc.l	$00077000
	dc.l	$00700700
	dc.l	$07000070
	dc.l	$70000007

	dc.l	$20000000
	dc.l	$22000000
	dc.l	$25200000
	dc.l	$25520000
	dc.l	$25552000
	dc.l	$25222200
	dc.l	$22000000
	dc.l	$20000000

sprite_attrs:
	dc.w	124, 1, $2001, 124
	dc.w	124+224, 4, $2001, 124
	dc.w	124, 3, $2001, 124+320
	dc.w	124+224, 0, $2001, 124+320
	dc.w	128+112, 2, $2002, 128+160

NyanCat:
	incbin	"psg80.bin"
NyanCat_len equ $ - NyanCat
