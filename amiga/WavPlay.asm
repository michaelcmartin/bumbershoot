
;;; exec.library location
_AbsExecBase     =    4

;;; exec.library vector offsets
_LVOFindTask     = -294
_LVOAllocSignal  = -330
_LVOFreeSignal   = -336
_LVOCloseLibrary = -414
_LVOOpenDevice	 = -444
_LVOCloseDevice  = -450
_LVOWaitIO       = -474
_LVOOpenLibrary  = -552

_DEVBeginIO      =  -30

;;; Audio I/O offsets
IOAudio_size     = 68
IOAudio_device   = 20
IOAudio_command  = 28
IOAudio_flags    = 30
IOAudio_data     = 34
IOAudio_length   = 38
IOAudio_period   = 42
IOAudio_volume   = 44
IOAudio_cycles   = 46

;;; Audio I/O constants
PA_SIGNAL        =  0
CMD_WRITE        =  3
NT_MSGPORT       =  4
NT_MESSAGE       =  5
ADCMD_ALLOCATE   = 32
ADIOF_PERVOL     = 16
ADIOF_NOWAIT     = 64

;;; dos.library vector offsets
_LVOWrite        =  -48
_LVOOutput       =  -60

	move.l	_AbsExecBase.w,a6	; Exec in a6 by default

	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,AudioTask
	moveq.l	#0,d0
	subq.l	#1,d0
	jsr	_LVOAllocSignal(a6)
	move.b	d0,AudioSignal
	bpl.s	.signalok
	lea	signalerrmsg,a0
	move.l	#signalerrmsglen,d0
	jsr	print
	bra	.done

.signalok:
	lea	AudioRequest,a2
	lea	auddev,a0
	move.l	a2,a1
	moveq.l	#0,d0
	moveq.l	#0,d1
	jsr	_LVOOpenDevice(a6)
	beq.s	.deviceok
	lea	deviceerrmsg,a0
	move.l	#deviceerrmsglen,d0
	jsr	print
	bra.s	.closeport

.deviceok:
	move.w	#CMD_WRITE,IOAudio_command(a2)
	move.b	#ADIOF_PERVOL,IOAudio_flags(a2)
	move.l	#SoundEffect,IOAudio_data(a2)
	move.l	#SoundEffect_length,IOAudio_length(a2)
	move.w	#224,IOAudio_period(a2)	; 16kHz
	move.w	#64,IOAudio_volume(a2)
	move.w	#1,IOAudio_cycles(a2)
	move.l	a2,a1
	move.l	a6,a5
	move.l	IOAudio_device(a1),a6
	jsr	_DEVBeginIO(a6)
	move.l	a5,a6
	lea	msg,a0
	move.l	#msglen,d0
	jsr	print
	move.l	a2,a1
	jsr	_LVOWaitIO(a6)

	;; Close the device
	lea	AudioRequest,a1
	jsr	_LVOCloseDevice(a6)

.closeport:
	moveq.l	#0,d0
	move.b	AudioSignal,d0
	jsr	_LVOFreeSignal(a6)

.done:	moveq.l	#0,d0
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
signalerrmsg:
	dc.b	"Could not allocate signal",10
signalerrmsglen = *-signalerrmsg
deviceerrmsg:
	dc.b	"Could not open audio device",10
deviceerrmsglen = *-deviceerrmsg

	data
	even
AudioPort:
	dc.l	0,0			; mp_Node.Succ/Pred
	dc.b	NT_MSGPORT,0		; mp_Node.Type/Priority
	dc.l	0			; mp_Node.Name
	dc.b	PA_SIGNAL		; mp_Flags
AudioSignal:
	dc.b	-1			; mp_SigBit
AudioTask:
	dc.l	0			; mp_SigTask
.msglist:
	dc.l	.msglist+4,0,.msglist
	dc.w	0

AudioRequest:
	dc.l	0,0			; io_Message.Node.Succ/Pred
	dc.b	NT_MESSAGE,50		; io_Message.Node.Type/Priority
	dc.l	0			; io_Message.Node.Name
	dc.l	AudioPort		; io_Message.ReplyPort
	dc.w	IOAudio_size		; io_Message.Length
	dc.l	0,0			; io_Device,io_Unit
	dc.w	ADCMD_ALLOCATE		; io_Command
	dc.b	ADIOF_NOWAIT,0		; io_Flags, io_Error
	dc.w	0			; ioa_AllocKey
	dc.l	allocmap,4		; ioa_Data, ioa_Length
	dc.w	0,0,0			; ioa_Period, ioa_Volume, ioa_Cycles
	dc.l	0,0,0,0,0		; io_WriteMessage

	data_c
	even
SoundEffect:
	incbin "wowmiga.bin"
SoundEffect_length = *-SoundEffect
