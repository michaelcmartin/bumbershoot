	xdef	_init_gui
	xdef	_poll_gui
	xdef	_close_gui
	xdef	_seed_random
	xdef	_random
	xdef	_timer_seed
	xdef	_report_bug
	xdef	_report_birth
	xdef	_draw_bug
	xdef	_erase_bug
	xdef	_draw_plankton

	xref	_toggle_garden

	xref	_CreateExtIO
	xref	_CreatePort
	xref	_DeleteExtIO
	xref	_DeletePort


;;; exec.library location
_AbsExecBase     =    4

;;; exec.library vector offsets
_LVOForbid       = -132
_LVOFindTask     = -294
_LVOWait         = -318
_LVOGetMsg       = -372
_LVOReplyMsg     = -378
_LVOWaitPort     = -384
_LVOOpenLibrary  = -408
_LVOCloseLibrary = -414
_LVOOpenDevice   = -444
_LVOCloseDevice  = -450
_LVOSendIO       = -462
_LVOCheckIO      = -468
_LVOWaitIO       = -474
_LVOAbortIO      = -480

;;; exec.library structure offsets/sizes
pr_MsgPort       =   92
mp_SigBit        =   15
tr_Command       =   28
tr_secs          =   32
tr_usecs         =   36

;;; exec.library constants
timerequest_size =   40
UNIT_VBLANK      =    1
TR_ADDREQUEST    =    9

;;; intuition.library vector offsets
_LVOClearMenuStrip =  -54
_LVOCloseWindow    =  -72
_LVOCurrentTime    =  -84
_LVOItemAddress    = -144
_LVOOpenWindow     = -204
_LVOSetMenuStrip   = -264

;;; intuition.library structure offsets
Class            =   20
Code             =   24
NextSelect       =   32
RPort            =   50
UserPort         =   86

;;; intuition.library constants
WBENCHSCREEN      =    $0001
IDCMP_MENUPICK    =$00000100
IDCMP_CLOSEWINDOW =$00000200
WFLG_SIZEGADGET   =$00000001
WFLG_DRAGBAR      =$00000002
WFLG_DEPTHGADGET  =$00000004
WFLG_CLOSEGADGET  =$00000008
WFLG_SMART_REFRESH=$00000000
WFLG_ACTIVATE     =$00001000
WFLG_NOCAREREFRESH=$00020000
CHECKWIDTH        = 19
COMMWIDTH         = 27
CHECKIT           =$0001
ITEMTEXT          =$0002
COMMSEQ           =$0004
MENUTOGGLE        =$0008
ITEMENABLED       =$0010
HIGHCOMP          =$0040
CHECKED           =$0100
MENUENABLED       =$0001


;;; graphics.library vector offsets
_LVORectFill     = -306
_LVOSetAPen      = -342

	offset	0
ExecBase:
	ds.l	1
IntuitionBase:
	ds.l	1
GfxBase:
	ds.l	1
WBStartMsg:
	ds.l	1
Window:
	ds.l	1
TimerPort:
	ds.l	1
TimerReq:
	ds.l	1
SignalMask:
	ds.l	1
SegSize:

	bss
bss_start:
	ds.b	SegSize
rng_state:
	ds.w	4
	text

;;; ----------------------------------------------------------------------
;;;   Window *init_gui(void) - set up the Workbench environment
;;;   Loads all the libraries, sets up the timer throttle, and opens
;;;   and configures the window the action will happen in.
;;;   Returns: a pointer to that window, or NULL on failure. The
;;;            receiving code is allowed to ignore the return value
;;;            beyond noticing that it's non-NULL.
;;; ----------------------------------------------------------------------

_init_gui:
	movem.l	a4-6,-(a7)
	lea	bss_start,a4

	;; Find Exec
	move.l	_AbsExecBase.w,a6
	move.l	a6,ExecBase(a4)

	;; Consume and cache our WB startup object
	sub.l	a1,a1			; Find our process structure
	jsr	_LVOFindTask(a6)
	move.l	d0,a0
	lea	pr_MsgPort(a0),a5	; Consume the process-start event
	move.l	a5,a0
	jsr	_LVOWaitPort(a6)
	move.l	a5,a0			; FindTask(NULL)->MsgPort
	jsr	_LVOGetMsg(a6)
	move.l	d0,WBStartMsg(a4)

	;; Create our timer device
	moveq.l	#0,d0
	move.l	d0,-(a7)
	move.l	d0,-(a7)
	jsr	_CreatePort
	move.l	d0,TimerPort(a4)
	beq.s	.timerfail
	move.l	d0,(a7)
	move.l	#timerequest_size,4(a7)
	jsr	_CreateExtIO
	move.l	d0,TimerReq(a4)
	move.l	d0,a1
	lea	timer_dev,a0
	moveq.l	#UNIT_VBLANK,d0
	moveq.l	#0,d1
	jsr	_LVOOpenDevice(a6)
	beq.s	.timerok		; OpenDevice is 0 on success
	move.l	TimerReq(a4),(a7)	; On failure delete the request so
	jsr	_DeleteExtIO		; we don't try to CloseDevice a
	clr.l	TimerReq(a4)		; null pointer
.timerfail:
	addq.l	#8,a7
	bra.s	.fail

.timerok:
	addq.l	#8,a7
	;; Load our libraries
	lea	graphics_lib(pc),a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,GfxBase(a4)
	beq.s	.fail
	lea	intuition_lib(pc),a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,IntuitionBase(a4)
	beq.s	.fail

	;; Create our window (IntuitionBase already in d0)
	move.l	d0,a6
	lea	window_spec(pc),a0
	jsr	_LVOOpenWindow(a6)
	move.l	d0,Window(a4)
	bne.s	.ok

.fail:	movem.l	(a7)+,a4-6
	bra.s	_close_gui

.ok:	;; Install the menu
	move.l	d0,a0
	lea	menu_spec(pc),a1
	jsr	_LVOSetMenuStrip(a6)
	;; Compute the signal mask
	moveq.l	#1,d0
	moveq.l	#0,d1
	move.l	Window(a4),a0
	move.l	UserPort(a0),a0
	move.b	mp_SigBit(a0),d1
	lsl.l	d1,d0
	move.l	d0,-(a7)
	moveq.l	#1,d0
	move.l	TimerPort(a4),a0
	move.b	mp_SigBit(a0),d1
	lsl.l	d1,d0
	move.l	(a7)+,d1
	or.l	d1,d0
	move.l	d0,SignalMask(a4)

	jsr	set_timer
	movem.l	(a7)+,a4-6
	rts

;;; ----------------------------------------------------------------------
;;;   void close_gui(void) Shuts down the system. Uninitializes and
;;;      closes everything that open_gui opened. There must not be any
;;;      outstanding timer events at this point. This routine shuts
;;;      down the Workbench connection, so the program must exit
;;;      immediately after this function is called.
;;; ----------------------------------------------------------------------

_close_gui:
	movem.l d2/a4/a6,-(a7)
	lea	bss_start,a4

	move.l	IntuitionBase(a4),d0
	beq.s	.winclosed		; Couldn't open window w/o Intuition
	move.l	d0,a6
	move.l	Window(a4),d2
	beq.s	.winclosed
	move.l	d2,a0
	jsr	_LVOClearMenuStrip(a6)
	move.l	d2,a0
	jsr	_LVOCloseWindow(a6)
.winclosed:
	;; Close the timer
	subq.l	#4,a7
	move.l	TimerReq(a4),d2
	beq.s	.devicedone
	move.l	d2,(a7)
	jsr	_CloseDevice
	move.l	d2,(a7)
	jsr	_DeleteExtIO
.devicedone:
	move.l	TimerPort(a4),d2
	beq.s	.portdone
	move.l	d2,(a7)
	jsr	_DeletePort
.portdone:
	addq.l	#4,a7
	;; Close our libraries
	move.l	a6,d0			; IntuitionBase
	move.l	ExecBase(a4),d1
	beq.s	.done			; No Exec means init_gui never ran
	move.l	d1,a6
	tst.l	d0			; Retest IntuitionBase...
	beq.s	.intclosed		; Move on, Exec in a6, if null
	move.l	d0,a1
	jsr	_LVOCloseLibrary(a6)
.intclosed:
	move.l	GfxBase(a4),d0
	beq.s	.gfxclosed
	move.l	d0,a1
	jsr	_LVOCloseLibrary(a6)
.gfxclosed:
	;; Signal our exit
	jsr	_LVOForbid(a6)
	move.l	WBStartMsg(a4),a1
	jsr	_LVOReplyMsg(a6)
.done:	movem.l	(a7)+,d2/a4/a6
	moveq.l	#0,d0			; return 0 if we came via init_gui
	rts

;;; ----------------------------------------------------------------------
;;;    int poll_gui(void): Processes window events and waits for the
;;;      frame timer to expire. Returns zero if a program-quit option was
;;;      selected. It is only safe to call close_gui if poll_gui has
;;;      returned zero.
;;; ----------------------------------------------------------------------
_poll_gui:
	movem.l d2-3/a4-6,-(a7)
	move.l	a4,a5				; Cache the small data base
	lea	bss_start,a4
	move.l	ExecBase(a4),a6			; ExecBase
.poll:	move.l	SignalMask(a4),d0
	jsr	_LVOWait(a6)
.win:
	move.l	Window(a4),a0
	move.l	UserPort(a0),a0
	jsr	_LVOGetMsg(a6)
	tst.l	d0
	beq.s	.no_win
	;; Collect message class and code, then reply
	move.l	d0,a1
	move.l	Class(a1),d2
	move.w	Code(a1),d3
	jsr	_LVOReplyMsg(a6)
	cmp.l	#IDCMP_CLOSEWINDOW,d2		; Are we CloseWindow?
	beq.s	.closewin			; If so, quit. If not, it's MENUPICK
.menu:	cmp.w	#$ffff,d3			; Is it MENUNULL?
	beq.s	.win				; If so, next window message
	move.w	d3,d0
	and.w	#$07ff,d0			; Ignore the "subitem" field
	cmp.w	#$0020,d0			; Is it QUIT?
	beq.s	.closewin			; If so, quit.
	exg	a4,a5				; If not, it must be "Toggle Garden".
	jsr	_toggle_garden
	exg	a4,a5
	;; Check next menu selection
	move.l	IntuitionBase(a4),a6
	lea	menu_spec(pc),a0
	moveq	#0,d0
	move.w	d3,d0
	jsr	_LVOItemAddress(a6)
	move.l	d0,a0
	move.w	NextSelect(a0),d3
	move.l	ExecBase(a4),a6
	bra.s	.menu				; Next menu selection
.no_win:
	move.l	TimerReq(a4),a1
	jsr	_LVOCheckIO(a6)
	tst.l	d0
	beq.s	.poll				; Window done, Timer not ready yet
	move.l	TimerReq(a4),a1
	jsr	_LVOWaitIO(a6)			; Get our timer request back
	bsr	set_timer			; ... and send it out for the next frame
	moveq.l	#1,d0				; Program is still running
	bra.s	.fin
.closewin:
	move.l	TimerReq(a4),a1
	jsr	_LVOAbortIO(a6)
	move.l	TimerReq(a4),a1
	jsr	_LVOWaitIO(a6)
	moveq.l	#0,d0				; We closed, do not continue
.fin:	movem.l	(a7)+,d2-3/a4-6
	rts

;;; ----------------------------------------------------------------------
;;;   Requeue the timer request. NOT C ABI COMPATIBLE.
;;;   Input: bss_start in a4.
;;;   Trashes: d0-1/a0-1.
;;; ----------------------------------------------------------------------
set_timer:
	move.l	a6,-(a7)
	move.l	TimerReq(a4),a1
	move.w	#TR_ADDREQUEST,tr_Command(a1)
	clr.l	tr_secs(a1)
	move.l	#13000,tr_usecs(a1)
	move.l	ExecBase(a4),a6
	jsr	_LVOSendIO(a6)
	move.l	(a7)+,a6
	rts

_report_bug:
_report_birth:
	rts

;;; ----------------------------------------------------------------------
;;; Prepare the registry file for graphics operations. NOT C ABI COMPATIBLE.
;;; Input: Pen color in d0
;;; Output: bss_start in a4; Window->RPort in a5; GfxBase in a6.
;;;         Window's pen color set to input.
;;; Trashes: d0-1/a0-1/a4-6. C-ABI functions must save a4-6 before calling.
;;; ----------------------------------------------------------------------
pen_init:
	lea	bss_start,a4
	move.l	Window(a4),a5
	move.l	RPort(a5),a5
	move.l	GfxBase(a4),a6
	move.l	a5,a1
	jmp	_LVOSetAPen(a6)

_erase_bug:
	moveq.l	#0,d0
	bra.s	bug_rect

_draw_bug:
	moveq.l	#1,d0
bug_rect:
	movem.l	d2-3/a4-6,-(a7)		; Args start at 24
	bsr.s	pen_init
	move.l	a5,a1
	move.l	24(a7),d0
	add.l	d0,d0
	move.l	28(a7),d1
	addq.l	#4,d0
	add.l	#11,d1
	move.l	d0,d2
	move.l	d1,d3
	addq.l	#5,d2
	addq.l	#2,d3
	jsr	_LVORectFill(a6)
	movem.l	(a7)+,d2-3/a4-6
	rts

_draw_plankton:
	movem.l	d2-3/a4-6,-(a7)		; Args start at 24
	moveq.l	#3,d0
	bsr.s	pen_init
	move.l	a5,a1
	move.l	24(a7),d0
	add.l	d0,d0
	move.l	28(a7),d1
	addq.l	#4,d0
	add.l	#11,d1
	move.l	d0,d2
	move.l	d1,d3
	addq.l	#1,d2
	jsr	_LVORectFill(a6)
	movem.l	(a7)+,d2-3/a4-6
	rts

;;; void seed_random(unsigned long seed)
;;; Seeds the PRNG. The Amiga edition uses the same 64-bit Xorshift-
;;; star PRNG as the modern Linux and Windows ports, but it only
;;; accepts 32-bit seeds. Its output will match the modern ports if the
;;; modern port's seed fits in 32 bits.
_seed_random:
	lea.l	rng_state,a0
	clr.l	d0
	addq.l	#1,d0
	move.l	d0,(a0)+
	or.l	4(sp),d0
	move.l	d0,(a0)+
	rts

;;; unsigned long random(void)
;;; Returns a random 32-bit integer. The Atari ST edition uses the
;;; same 64-bit Xorshift-star PRNG as the modern Linux and Windows
;;; ports. All 32 bits in the return value are random enough to
;;; rely on, so using bitmask or modulus operators to limit the
;;; result is safe.
_random:
	lea.l	rng_state,a0
	movem.l	(a0),d0-d1
	movem.l	d2-d6,-(sp)

	;; rng_state = rng_state ^ (rng_state >> 12)
	moveq	#12,d3
	moveq	#20,d4
	move.l	d1,d2
	lsr.l	d3,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsl.l	d4,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsr.l	d3,d2
	eor.l	d2,d0

	;; rng_state = rng_state ^ (rng_state << 25)
	moveq	#25,d3
	move.l	d0,d2
	lsl.l	d3,d2
	eor.l	d2,d0
	move.l	d1,d2
	lsr.l	#7,d2
	eor.l	d2,d0
	move.l	d1,d2
	lsl.l	d3,d2
	eor.l	d2,d1

	;; rng_state = rng_state ^ (rng_state >> 27)
	moveq	#27,d3
	move.l	d1,d2
	lsr.l	d3,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsl.l	#5,d2
	eor.l	d2,d1
	move.l	d0,d2
	lsr.l	d3,d2
	eor.l	d2,d0

	movem.l	d0-d1,(a0)

	;; Return the high 32 bits of the 64-bit product of the RNG
	;; state and the constant $2545F4914F6CDD1D
	move.l	#$2545F491,d2
	move.l	#$4F6CDD1D,d3
	clr.l	d4
	clr.l	d5
	moveq	#63,d6
.m64:	lsr.l	d0
	roxr.l	d1
	bcc.s	.m64_next
	add.l	d3,d5
	addx.l	d2,d4
.m64_next:
	lsl.l	d3
	roxl.l	d2
	dbra	d6,.m64
	move.l	d4,d0			; High dword of product as retval

	;; Restore all the registers and exit
	movem.l	(sp)+,d2-d6
	rts

;;; uint32_t timer_seed(void)
;;; Returns a random seed based on the current value of the Intuition timer.
;;; Not actually monotonically increasing.
_timer_seed:
	move.l	a6,-(a7)
	subq.l	#8,a7
	move.l	a7,a0
	lea	4(a7),a1
	lea	bss_start,a6
	move.l	IntuitionBase(a6),a6
	jsr	_LVOCurrentTime(a6)
	move.l	(a7)+,d0
	move.l	(a7)+,d1
	eor.l	d1,d0
	move.l	(a7)+,a6
	rts


window_spec:
	dc.w	20,20,308,113		; 300,100 client area at 20,20
	dc.b	0,1			; Detail Pen, Block Pen
	dc.l	IDCMP_CLOSEWINDOW|IDCMP_MENUPICK
	dc.l	WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|WFLG_ACTIVATE|WFLG_DRAGBAR|WFLG_DEPTHGADGET
	dc.l	0,0,window_caption
	dc.l	0,0
	dc.w	100,25,640,200		; Min/Max size
	dc.w	WBENCHSCREEN		; Type

PROJECT_WIDTH=CHECKWIDTH+COMMWIDTH+16*8

menu_spec:
	dc.l	0			; NextMenu
	dc.w	1,0			; LeftEdge, TopEdge
	dc.w	PROJECT_WIDTH,0		; Width, Height
	dc.w	MENUENABLED		; Flags
	dc.l	project_str		; MenuName
	dc.l	garden_spec		; FirstItem
	dc.w	0,0,0,0			; Beats and Jazz?

garden_spec:
	dc.l	quit_spec		; NextItem
	dc.w	0,0,PROJECT_WIDTH,10	; Left,Top,Width,Height
	dc.w	CHECKIT|CHECKED|ITEMTEXT|COMMSEQ|ITEMENABLED|HIGHCOMP|MENUTOGGLE
	dc.l	0			; MutualExclude
	dc.l	garden_text,0		; ItemFill, SelectFill
	dc.b	'G',0			; Command
	dc.l	0			; SubItem
	dc.w	0			; NextSelect

quit_spec:
	dc.l	0			; NextItem
	dc.w	0,10,PROJECT_WIDTH,10	; Left,Top,Width,Height
	dc.w	ITEMTEXT|COMMSEQ|ITEMENABLED|HIGHCOMP	; Flags
	dc.l	0			; MutualExclude
	dc.l	quit_text,0		; ItemFill, SelectFill
	dc.b	'Q',0			; Command
	dc.l	0			; SubItem
	dc.w	0			; NextSelect

garden_text:
	dc.b	2,1,0,0			; FrontPen, BackPen, DrawMode (JAM1)
	dc.w	CHECKWIDTH,1		; LeftEdge, TopEdge
	dc.l	topaz80,garden_str	; ITextFont, IText
	dc.l	0			; NextText

quit_text:
	dc.b	2,1,0,0			; FrontPen, BackPen, DrawMode (JAM1)
	dc.w	CHECKWIDTH,1		; LeftEdge, TopEdge
	dc.l	topaz80,quit_str	; ITextFont, IText
	dc.l	0			; NextText

topaz80:
	dc.l	topaz_font
	dc.w	8,1			; 8pt, Normal ROM font

intuition_lib:
	dc.b	"intuition.library",0
graphics_lib:
	dc.b	"graphics.library",0
timer_dev:
	dc.b	"timer.device",0
topaz_font:
	dc.b	"topaz.font",0
window_caption:
	dc.b	"Simulated Evolution",0
project_str:
	dc.b	"Project",0
garden_str:
	dc.b	"Garden of Eden",0
quit_str:
	dc.b	"Quit",0
	even
