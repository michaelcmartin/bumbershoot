VOX_BASE     = 0
VOX_CURRENT  = 4
VOX_NEXT_TIME= 8
VOX_REL_TIME =10
VOX_FREQ_CUR =12
VOX_VOL_CUR  =14
VOX_VOL_TGT  =16
VOX_VOL_DELTA=18
VOX_DEC_DELTA=20
VOX_SUS_TGT  =22
VOX_REL_DELTA=24
VOX_STACATTO =26
VOX_SIZE     =28

	text

;;; Takes pointer argument on stack to array of per-voice bases.
;;; Initializes the voice array to the start of each voice, with no
;;; instrument selected.
song_init:
	move.l	4(sp),a0
	movem.l	a2-3/d2,-(sp)
	lea	voices,a1
	moveq	#2,d0
.lp:	move.l	(a0),(a1)+
	move.l	(a0)+,(a1)+
	move.w	#((VOX_SIZE-8)/2)-1,d1
.lp2:	clr.w	(a1)+
	dbra	d1,.lp2
	dbra	d0,.lp
	lea	init_ay7,a3
	tst.l	(a3)
	bne.s	.fin
	move.w	#7,-(sp)
	clr.w	-(sp)
	move.w	#28,-(sp)
	trap	#14
	move.l	d0,(a3)
	addq.l	#6,sp
.fin:	movem.l	(sp)+,a2-3/d2
	rts

;; song_wait: on first call, wait 15ms. Otherwise wait until 15ms since
;;            the last time we called.
song_wait:
	movem.l	a2/d2,-(sp)
	clr.l	-(sp)			; Enter supervisor mode
	move.w	#32,-(sp)
	trap	#1
	move.l	d0,2(sp)		; And prep for user restore
	move.w	#32,(sp)
	lea	wait_target,a0
	lea	$04ba,a1		; hz_200
	move.l	(a0),d0
	bne.s	.do_wait
	;; First run; use our current time as the start
	move.l	(a1),d0
.do_wait:
	addq.l	#3,d0			; Target is 15ms from last
.buzz:	cmp.l	(a1),d0
	bhi.s	.buzz
	move.l	d0,(a0)			; Remember time for next time
	trap	#1			; Restore user mode
	addq.l	#6,sp			; Restore stack
	movem.l	(sp)+,a2/d2
	rts

song_end:
	movem.l	a2-3/d2-3,-(sp)
	subq.l	#6,sp
	moveq	#2,d3
.lp:	move.w	#136,d0
	add.w	d3,d0
	move.w	d0,4(sp)
	clr.w	2(sp)
	move.w	#28,(sp)
	trap	#14
	dbra	d3,.lp
	lea	init_ay7,a3
	tst.l	(a3)
	beq.s	.fin
	move.l	(a3),d0
	move.w	#135,4(sp)
	move.w	d0,2(sp)
	move.w	#28,(sp)
	trap	#14
.fin:	addq.l	#6,sp
	clr.l	(a3)
	movem.l	(sp)+,a2-3/d2-3
	rts

song_step:
	movem.l	a2-4/d2,-(sp)
	lea	voices,a0
	move.l	a0,a4
	moveq	#2,d1
.voice_loop:
	move.w	VOX_VOL_CUR(a0),d0
	sub.w	VOX_VOL_DELTA(a0),d0
	cmp.w	VOX_VOL_TGT(a0),d0
	bpl.s	.vol_updated
	move.w	VOX_VOL_TGT(a0),d0
.vol_updated:
	move.w	d0,VOX_VOL_CUR(a0)
	move.l	VOX_CURRENT(a0),a1
.cmd_loop:
	tst.w	VOX_NEXT_TIME(a0)	; Waiting for the next command?
	bne	.cmds_done		; If so, we're done reading cmds
	clr.w	d0			; Read a byte
	move.b	(a1)+,d0
	cmp.b	#$80,d0			; Rest command?
	bne	.not_rest
	clr.w	VOX_VOL_TGT(a0)		; Target volume zero
	move.w	VOX_REL_DELTA(a0),VOX_VOL_DELTA(a0)
	clr.w	VOX_REL_TIME(a0)
	clr.w	VOX_NEXT_TIME(a0)
	move.b	(a1)+,(VOX_NEXT_TIME+1)(a0)
	bra.s	.cmd_loop
.not_rest:
	cmp.b	#$81,d0			; GOTO command?
	bne	.not_goto
	move.b	(a1)+,d0
	lsl.w	#8,d0
	move.b	(a1)+,d0
	move.l	VOX_BASE(a0),a1
	lea	(a1,d0),a1
	bra.s	.cmd_loop
.not_goto:
	cmp.b	#$82,d0			; INSTRUMENT command?
	bne	.not_instrument
	moveq	#7,d0
	lea	VOX_DEC_DELTA(a0),a2
.inslp:	move.b	(a1)+,(a2)+
	dbra	d0,.inslp
	bra.s	.cmd_loop
.not_instrument:
	lea	frequency_table,a2	; It's a note
	lsl.w	#1,d0
	move.w	(a2,d0),VOX_FREQ_CUR(a0)
	move.w	#$0FFF,VOX_VOL_CUR(a0)
	move.w	VOX_SUS_TGT(a0),VOX_VOL_TGT(a0)
	move.w	VOX_DEC_DELTA(a0),VOX_VOL_DELTA(a0)
	move.b	(a1)+,d0		; Note duration
	move.w	d0,VOX_NEXT_TIME(a0)
	sub.w	VOX_STACATTO(a0),d0
	cmp.w	#1,d0
	bpl.s	.relok
	moveq	#1,d0
.relok:	move.w	d0,VOX_REL_TIME(a0)
	bra	.cmd_loop
.cmds_done:
	move.l	a1,VOX_CURRENT(a0)
	subq.w	#1,VOX_NEXT_TIME(a0)
	cmp.w	#1,VOX_REL_TIME(a0)
	bmi.s	.one_voice_done
	subq.w	#1,VOX_REL_TIME(a0)
	bne.s	.one_voice_done
	clr.w	VOX_VOL_TGT(a0)
	move.w	VOX_REL_DELTA(a0),VOX_VOL_DELTA(a0)
.one_voice_done:
	add.l	#VOX_SIZE,a0
	dbra	d1,.voice_loop
	;; Voice state has been updated. Now we mirror the relevant
	;; data to the sound chip.
	subq.l	#6,sp
	lea	ay3_dump,a3
.aylp:	clr.l	2(sp)
	move.b	(a3)+,5(sp)
	beq.s	.fin
	clr.w	d0
	move.b	(a3)+,d0
	move.b	(a4,d0),3(sp)
	move.w	#28,(sp)
	trap	#14
	bra.s	.aylp
.fin:	move.w	#135,4(sp)
	move.w	#56,2(sp)
	move.w	#28,(sp)
	trap	#14
	addq.l	#6,sp
	movem.l	(sp)+,a2-4/d2
	rts

	data
frequency_table:
	dc.w	$0FFF, $0FFF, $0FFF, $0FFF, $0FFF, $0FFF, $0FFF, $0FFF
	dc.w	$0FFF, $0FFF, $0FFF, $0FD2, $0EEE, $0E18, $0D4D, $0C8E
	dc.w	$0BDA, $0B2F, $0A8F, $09F7, $0968, $08E1, $0861, $07E9
	dc.w	$0777, $070C, $06A7, $0647, $05ED, $0598, $0547, $04FC
	dc.w	$04B4, $0470, $0431, $03F4, $03BC, $0386, $0353, $0324
	dc.w	$02F6, $02CC, $02A4, $027E, $025A, $0238, $0218, $01FA
	dc.w	$01DE, $01C3, $01AA, $0192, $017B, $0166, $0152, $013F
	dc.w	$012D, $011C, $010C, $00FD, $00EF, $00E1, $00D5, $00C9
	dc.w	$00BE, $00B3, $00A9, $009F, $0096, $008E, $0086, $007F
	dc.w	$0077, $0071, $006A, $0064, $005F, $0059, $0054, $0050
	dc.w	$004B, $0047, $0043, $003F, $003C, $0038, $0035, $0032
	dc.w	$002F, $002D, $002A, $0028, $0026, $0024, $0022, $0020

ay3_dump:
	dc.b	128,13,129,12,130,41,131,40,132,69,133,68
	dc.b	136,14,137,42,138,70,0,0

	even
init_ay7:
	dc.l	0

wait_target:
	dc.l	0

	bss
	even
voices:	ds.b	VOX_SIZE * 3

	text
