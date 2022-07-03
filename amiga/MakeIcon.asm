;;; exec.library location
_AbsExecBase      =     4

;;; exec.library vector offsets
_LVOOpenLibrary   =  -408
_LVOCloseLibrary  =  -414

;;; icon.library vector offsets
_LVOPutDiskObject =   -84

;;; icon.library constants
WB_MAGIC          = $e310
WB_DISKVERSION    = $0001
WBTOOL            = $0003
GFLG_GADGBACKFILL = $0001
GFLG_GADGIMAGE    = $0004
GACT_RELVERIFY    = $0001
GACT_IMMEDIATE    = $0002
GTYP_BOOLGADGET   = $0001
NO_ICON_POSITION  = $80000000

;;; Our own constants
IMG_WIDTH         =    48
IMG_HEIGHT        =    18

	text

	move.l	_AbsExecBase.w,a6
	lea	iconlib(pc),a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	a6,a5			; Exec library base in a5
	move.l	d0,a6			; Icon library base in a6
	lea	outname(pc),a0
	lea	dobj(pc),a1
	jsr	_LVOPutDiskObject(a6)
	move.l	a6,a1
	move.l	a5,a6
	jsr	_LVOCloseLibrary(a6)
	rts


dobj:	dc.w	WB_MAGIC,WB_DISKVERSION
	dc.l	0
	dc.w	0,0,IMG_WIDTH,IMG_HEIGHT+1
	dc.w	GFLG_GADGIMAGE|GFLG_GADGBACKFILL
	dc.w	GACT_RELVERIFY|GACT_IMMEDIATE
	dc.w	GTYP_BOOLGADGET
	dc.l	crown,0,0,0,0
	dc.w	0
	dc.l	0
	dc.b	WBTOOL,0
	dc.l	0,0,NO_ICON_POSITION,NO_ICON_POSITION,0,0
	dc.l	$1000

crown:	dc.w	0,0,IMG_WIDTH,IMG_HEIGHT,2
	dc.l	imgdat
	dc.b	3,0
	dc.l	0

imgdat:	dc.w	$0000,$0000,$0000,$0000,$03C0,$0000,$0007,$83C1
	dc.w	$E000,$0007,$8001,$E000,$1E00,$0000,$0078,$1E01
	dc.w	$0180,$8078,$0003,$8181,$C000,$01C3,$E3C7,$C380
	dc.w	$007D,$FBDF,$BE00,$003F,$FFFF,$FC00,$0019,$FFFF
	dc.w	$9800,$0012,$FE7F,$2800,$0021,$7CBE,$1400,$0030
	dc.w	$F85F,$0C00,$0079,$FC3F,$9E00,$00FF,$FE7F,$FF00
	dc.w	$0007,$FFFF,$E000,$0000,$0000,$0000,$0000,$03C0
	dc.w	$0000,$0007,$84E1,$E000,$0009,$C462,$7000,$1E08
	dc.w	$C3C2,$3078,$2707,$8181,$E09C,$2303,$83C1,$C08C
	dc.w	$1FC7,$E3C7,$E3F8,$03FF,$FFFF,$FFC0,$01FF,$FFFF
	dc.w	$FF80,$007F,$FFFF,$FE00,$003F,$FFFF,$FC00,$0039
	dc.w	$FFFF,$9C00,$0070,$FE7F,$0E00,$0079,$FC3F,$9E00
	dc.w	$00FF,$FE7F,$FF00,$01FF,$FFFF,$FF80,$03FF,$FFFF
	dc.w	$FFC0,$0007,$FFFF,$E000

iconlib:
	dc.b	"icon.library",0
outname:
	dc.b	"Hamurabi",0
