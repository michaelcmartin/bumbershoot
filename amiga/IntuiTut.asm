;;; ----------------------------------------------------------------------
;;;                     Intuition Tutorial: Hello World
;;;
;;;   This file is an adaptation of the sample program constructed over
;;;   the course of Chapter 2 of the Intuition Reference Manual. It is
;;;   realized in vasm-compatible assembly language instead of C, and it
;;;   manages the necessary work for startup and shutdown from the
;;;   Workbench environment that is normally invisible to C programs.
;;;
;;;   Assemble with this command line:
;;;   vasmm68k_mot -Fhunkexe -kick1hunks -nosym -o IntuiTut IntuiTut.asm
;;;
;;;   You will also need to copy some tool's .info file over to
;;;   IntuiTut.info in order to start the program at all, or otherwise
;;;   make use of a utility like PNG2Icon.
;;; ----------------------------------------------------------------------


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

;;; exec.library structure offsets
pr_MsgPort       =   92
mp_SigBit        =   15

;;; intuition.library vector offsets
_LVOCloseScreen  =  -66
_LVOCloseWindow  =  -72
_LVOOpenScreen   = -198
_LVOOpenWindow   = -204

;;; intuition.library structure offsets
RPort            =   50
UserPort         =   86

;;; intuition.library constants
CUSTOMSCREEN=$000F
IDCMP_CLOSEWINDOW =$00000200
WFLG_SIZEGADGET   =$00000001
WFLG_DRAGBAR      =$00000002
WFLG_DEPTHGADGET  =$00000004
WFLG_CLOSEGADGET  =$00000008
WFLG_SMART_REFRESH=$00000000
WFLG_ACTIVATE     =$00001000
WFLG_NOCAREREFRESH=$00020000

;;; graphics.library vector offsets
_LVOText         =  -60
_LVOMove         = -240

	text
	;; Collect the process-start message
	move.l	_AbsExecBase.w,a6
	move.l	a6,d5			; ExecBase
	sub.l	a1,a1			; Find our process structure
	jsr	_LVOFindTask(a6)
	move.l	d0,a0

	;; Consume the process-start event
	lea	pr_MsgPort(a0),a2
	move.l	a2,a0
	jsr	_LVOWaitPort(a6)
	move.l	a2,a0			; FindTask(NULL)->MsgPort
	jsr	_LVOGetMsg(a6)
	move.l	d0,d4			; WBStartMsg

	;; Load our libraries
	lea	intuitionlib,a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,d6			; IntuitionBase
	lea	gfxlib,a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,d7			; GfxBase

	;; Initialize the screen and window
	sub.l	a2,a3			; Clear ScreenPtr
	sub.l	a3,a4			; Clear WindowPtr
	move.l	d6,a6			; IntuitionBase
	lea	screen,a0
	jsr	_LVOOpenScreen(a6)
	tst.l	d0			; Did it work?
	beq	finish			; If not, abort
	move.l	d0,a3			; Save ScreenPtr
	
	lea	window,a0
	move.l	d0,nw_screen(a0)
	jsr	_LVOOpenWindow(a6)
	tst.l	d0			; Did it work?
	beq	finish			; If not, abort
	move.l	d0,a4			; Save WindowPtr
	
	;; Draw the Hello World message
	move.l	RPort(a4),a2
	move.l	d7,a6			; GfxBase
	move.l	a2,a1
	move.l	#20,d0
	move.l	d0,d1
	jsr	_LVOMove(a6)
	lea	window_text,a0
	move.l	a2,a1			; WindowPtr->RPort
	move.l	#window_text_len,d0
	jsr	_LVOText(a6)

	;; Wait for the window to close
	moveq.l	#1,d0
	moveq.l	#0,d1
	move.l	UserPort(a4),a0
	move.b	mp_SigBit(a0),d1
	lsl.l	d1,d0
	move.l	d5,a6			; ExecBase
	jsr	_LVOWait(a6)

finish:
	;; Shut down: Close window and screen if needed
	move.l	d6,a6			; IntuitionBase
	move.l	a4,d0			; WindowPtr
	beq.s	.screen			; If null, we're done
	move.l	d0,a0
	jsr	_LVOCloseWindow(a6)
.screen:
	move.l	a3,d0			; ScreenPtr
	beq.s	.libs
	move.l	d0,a0
	jsr	_LVOCloseScreen(a6)

	;; Shut down: Close libraries
.libs:	move.l	d5,a6			; ExecBase
	move.l	d7,a1			; GfxBase
	jsr	_LVOCloseLibrary(a6)
	move.l	d6,a1			; IntuitionBase
	jsr	_LVOCloseLibrary(a6)

	;; Shut down: Reply to startup message
	jsr	_LVOForbid(a6)
	move.l	d4,a1			; WBStartupMsg
	jsr	_LVOReplyMsg(a6)
	clr.l	d0			; Return code?
	rts

	data

screen:	dc.w	0,0,320,200,2		; 320x200x4
	dc.b	0,1			; Detail Pen, Block Pen
	dc.w	0,CUSTOMSCREEN		; View Mode, screen type
	dc.l	topaz60			; Default font
	dc.l	screen_caption		; Default title
	dc.l	0,0			; Gadgets, CustomBitmap
topaz60:
	dc.l	topaz
	dc.w	9,1			; 9pt, Normal ROM font

window:	dc.w	20,20,300,100		; 300,100 at 20,20
	dc.b	0,1			; Detail Pen, Block Pen
	dc.l	IDCMP_CLOSEWINDOW
	dc.l	WFLG_CLOSEGADGET|WFLG_SMART_REFRESH|WFLG_ACTIVATE|WFLG_SIZEGADGET|WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_NOCAREREFRESH
	dc.l	0,0,window_caption
nw_screen=*-window
	dc.l	0,0
	dc.w	100,25,640,200		; Min/Max size
	dc.w	CUSTOMSCREEN		; Type

intuitionlib:
	dc.b	"intuition.library",0
gfxlib:	dc.b	"graphics.library",0
topaz:	dc.b	"topaz.font",0
screen_caption:
	dc.b	"My Own Screen",0
window_caption:
	dc.b	"A Simple Window",0
window_text:
	dc.b	"Hello World"
window_text_len=*-window_text
	even
