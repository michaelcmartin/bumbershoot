	xdef	_main

	xref	_BeginIO
	xref	_CreateExtIO
	xref	_CreatePort
	xref	_DeleteExtIO
	xref	_DeletePort

;;; exec.library location
_AbsExecBase     =    4

;;; exec.library vector offsets
_LVOCloseLibrary = -414
_LVOOpenDevice	 = -444
_LVOCloseDevice  = -450
_LVOWaitIO       = -474
_LVOOpenLibrary  = -552

;;; Audio I/O offsets
IOAudio_size     = 68
IOAudio_priority =  9
IOAudio_command  = 28
IOAudio_flags    = 30
IOAudio_allocKey = 32
IOAudio_data     = 34
IOAudio_length   = 38
IOAudio_period   = 42
IOAudio_volume   = 44
IOAudio_cycles   = 46

;;; Audio I/O constants
CMD_WRITE        =  3
ADCMD_ALLOCATE   = 32
ADIOF_PERVOL     = 16
ADIOF_NOWAIT     = 64

;;; dos.library vector offsets
_LVOWrite        =  -48
_LVOOutput       =  -60

_main:	moveq.l	#0,d0			; Alloc space for 2 C-fn args
	move.l	d0,-(a7)
	move.l	d0,-(a7)
	lea	AudioPort,a0		; Clear out BSS by hand
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+

	move.l	_AbsExecBase.w,a6

	;; The two arguments are already 0
	jsr	_CreatePort
	move.l	d0,AudioPort
	beq	.cleanup

	move.l	d0,(a7)
	move.l	#IOAudio_size,4(a7)
	jsr	_CreateExtIO
	move.l	d0,AudioRequest
	beq	.cleanup

	lea	auddev,a0
	move.l	d0,a1
	move.l	a1,a2
	move.b	#50,IOAudio_priority(a1)
	move.w	#ADCMD_ALLOCATE,IOAudio_command(a1)
	move.b	#ADIOF_NOWAIT,IOAudio_flags(a1)
	move.w	#0,IOAudio_allocKey(a1)
	move.l	#allocmap,IOAudio_data(a1)
	move.l	#4,IOAudio_length(a1)
	moveq.l	#0,d0
	moveq.l	#0,d1
	jsr	_LVOOpenDevice(a6)
	bne.s	.cleanup

	move.w	#CMD_WRITE,IOAudio_command(a2)
	move.b	#ADIOF_PERVOL,IOAudio_flags(a2)
	move.l	#SoundEffect,IOAudio_data(a2)
	move.l	#SoundEffect_length,IOAudio_length(a2)
	move.w	#224,IOAudio_period(a2)	; 16kHz
	move.w	#$40,IOAudio_volume(a2)
	move.w	#1,IOAudio_cycles(a2)
	move.l	a2,(a7)
	jsr	_BeginIO
	lea	msg,a0
	move.l	#msglen,d0
	jsr	print
	move.l	a2,a1
	jsr	_LVOWaitIO(a6)

.cleanup:
	move.l	AudioRequest,d0
	beq.s	.port
	move.l	d0,a1
	move.l	d0,(a7)
	jsr	_LVOCloseDevice(a6)
	jsr	_DeleteExtIO

.port:	move.l	AudioPort,(a7)
	beq.s	.done
	jsr	_DeletePort

.done:	addq.l	#8,a7
	moveq.l	#0,d0
	rts

print:	movem.l	d2-3,-(a7)
	move.l	a6,-(a7)
	move.l	d0,-(a7)
	move.l	a0,-(a7)
	lea	doslib,a1
	moveq.l	#0,d0
	jsr	_LVOOpenLibrary(a6)
	tst.l	d0
	beq.s	.done
	move.l	d0,a6
	jsr	_LVOOutput(a6)
	move.l	d0,d1
	move.l	(a7),d2
	move.l	4(a7),d3
	jsr	_LVOWrite(a6)
	move.l	a6,a1
	move.l	8(a7),a6
	jsr	_LVOCloseLibrary(a6)
.done	add	#12,a7
	movem.l	(a7)+,d2-3
	rts

allocmap:
	dc.b	3,5,10,12

doslib:	dc.b	"dos.library",0
auddev:	dc.b	"audio.device",0
msg:	dc.b	"Wow! Digital sound!",10
msglen = *-msg

	bss
	even
AudioPort:
	ds.l	1
AudioRequest:
	ds.l	1
AudioDevice:
	ds.l	1

	data_c
	even
SoundEffect:
	incbin "wowmiga.bin"
SoundEffect_length = *-SoundEffect
