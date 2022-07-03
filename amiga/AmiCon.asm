	xref	_DOSBase
	xref	_stdin
	xref	_stdout
	xref	_stderr
	xref	_fflush
	xdef	_open_amiga_console
	xdef	_close_amiga_console

_LVOOpen         =  -30
_LVOClose        =  -36
_LVORead         =  -42
_LVOWrite        =  -48

MODE_OLDFILE     = 1005

	text

_open_amiga_console:
	movem.l	d2/a6,-(a7)
	move.l	12(a7),d1
	move.l	_DOSBase,a6
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)

	lea	stdio,a1
	move.l	_stdin,a0
	move.l	(a0),(a1)
	move.l	d0,(a0)
	move.l	_stdout,a0
	move.l	(a0),4(a1)
	move.l	d0,(a0)
	move.l	_stderr,a0
	move.l	(a0),8(a1)
	move.l	d0,(a0)
	movem.l	(a7)+,d2/a6
	rts

_close_amiga_console:
	movem.l	d2-3/a5-6,-(a7)

	move.l	_stdout,-(a7)
	bsr	_fflush
	move.l	_stderr,(a7)
	bsr	_fflush
	move.l	_stdin,a5
	move.l	a5,(a7)
	bsr	_fflush
	move.l	(a5),a5

	move.l	_DOSBase,a6
	move.l	a5,d1
	lea	prompt(pc),a0
	move.l	a0,d2
	move.l	#promptlen,d3
	jsr	_LVOWrite(a6)

	move.l	a5,d1
	move.l	a7,d2
	moveq.l	#1,d3
	jsr	_LVORead(a6)

	lea	stdio,a1
	move.l	_stdin,a0
	move.l	(a1),(a0)
	move.l	_stdout,a0
	move.l	4(a1),(a0)
	move.l	_stderr,a0
	move.l	8(a1),(a0)

	move.l	a5,d1
	jsr	_LVOClose(a6)

	addq.l	#4,a7
	movem.l	(a7)+,d2-3/a5-6
	rts

prompt:	dc.b	"Press RETURN to exit: "
promptlen = *-prompt
	even

	bss
stdio:	ds.l	3
