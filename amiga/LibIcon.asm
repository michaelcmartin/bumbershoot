	xdef	_SaveIcon

;;; exec.library location
AbsExecBase      =    4

;;; exec.library vector offsets
_LVOFindTask     = -294
_LVOOpenLibrary  = -408
_LVOCloseLibrary = -414

;;; icon.library vector offsets
_LVOPutDiskObject = -84

;;; icon.library constants
WB_MAGIC          = $e310
WB_DISKVERSION    = $0001
WBTOOL            = $0003
GFLG_GADGBACKFILL = $0001
GFLG_GADGHIMAGE   = $0002
GFLG_GADGIMAGE    = $0004
GACT_RELVERIFY    = $0001
GACT_IMMEDIATE    = $0002
GTYP_BOOLGADGET   = $0001
NO_ICON_POSITION  = $80000000

	text

;;; void SaveIcon(const char *filename, uint32_t width, uint32_t height, uint16_t *image, uint16_t *highlight_image, uint32_t stack);
_SaveIcon:
	movem.l	a5-6,-(a7)		; Arguments start at 12(a7)
	
	;; Load our libraries
	move.l	AbsExecBase.w,a6	; Find the Exec library
	lea	iconlib(pc),a1		; Load the Icon library
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	a6,a5			; Exec library base in a5
	move.l	d0,a6			; Icon library base in a6
	
	;; Prepare the DiskObject and images for saving
	lea	dobj(pc),a0
	move.l	16(a7),d0		; width argument
	move.w	d0,do_width(a0)
	move.w	d0,img1_width(a0)
	move.w	d0,img2_width(a0)
	move.l	20(a7),d0		; height argument
	move.w	d0,img1_height(a0)
	move.w	d0,img2_height(a0)
	addq.w	#1,d0
	move.w	d0,do_height(a0)
	move.l	24(a7),img1_data(a0)	; Image data argument
	sub.l	a1,a1			; Highlight data (usually NULL)
	moveq	#GFLG_GADGIMAGE|GFLG_GADGBACKFILL,d0 ; default flags
	move.l	28(a7),img2_data(a0)	; Image data 2 argument
	beq.s	.no_img2
	lea	img2(a0),a1		; img2 exists, set addr/flags
	moveq	#GFLG_GADGIMAGE|GFLG_GADGHIMAGE,d0
.no_img2:
	move.l	a1,do_img2(a0)
	move.w	d0,do_flags(a0)
	move.l	32(a7),do_stack(a0)	; Stack size argument
	
	;; Save the prepared object
	move.l	12(a7),a0		; Output file name
	lea	dobj(pc),a1		; Output icon data
	jsr	_LVOPutDiskObject(a6)
	
	;; Unload our libraries
	move.l	a6,a1			; Close the Icon library
	move.l	a5,a6
	jsr	_LVOCloseLibrary(a6)
	
	;; epilog
	movem.l	(a7)+,a5-6
	rts


dobj:	dc.w	WB_MAGIC,WB_DISKVERSION			; DiskObject id
	;; -- Begin embedded Gadget --
	dc.l	0					; always NULL
	dc.w	0,0					; x/y
do_width	=*-dobj
	dc.w	0
do_height	=*-dobj
	dc.w	0
do_flags	=*-dobj
	dc.w	0					; flags
	dc.w	GACT_RELVERIFY|GACT_IMMEDIATE		; activation
	dc.w	GTYP_BOOLGADGET				; gadget type
	dc.l	img1
do_img2		=*-dobj
	dc.l	0
	dc.l	0,0,0					; non-icon fields
	dc.w	0					; Gadget ID
	dc.l	0					; always NULL
	;; -- End embedded Gadget --
	dc.b	WBTOOL,0				; DiskObject type
	dc.l	0					; Default tool
	dc.l	0					; Tool types array
	dc.l	NO_ICON_POSITION,NO_ICON_POSITION	; Icon position
	dc.l	0					; Drawer data
	dc.l	0					; Tool Window
do_stack	=*-dobj
	dc.l	$1000					; Stack size

img1:							; Absolute address! Used only in dobj data itself
	dc.w	0,0					; x/y
img1_width	=*-dobj
	dc.w	0
img1_height	=*-dobj
	dc.w	0
	dc.w	2					; color depth
img1_data	=*-dobj
	dc.l	0					; Raw image data
	dc.b	3,0					; bitplane selectors
	dc.l	0					; always NULL

img2		=*-dobj
	dc.w	0,0					; x/y
img2_width	=*-dobj
	dc.w	0
img2_height	=*-dobj
	dc.w	0
	dc.w	2					; color depth
img2_data	=*-dobj
	dc.l	0					; Raw image data
	dc.b	3,0					; bitplane selectors
	dc.l	0					; always NULL

iconlib:
	dc.b	"icon.library",0
	even
