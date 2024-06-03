;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

; Copyright 2021 ing. E. Th. van den Oosterkamp
;
; Example software for the book "BareMetal Amiga Programming" (ISBN 9798561103261)
;
; Permission is hereby granted, free of charge, to any person obtaining a copy 
; of this software and associated files (the "Software"), to deal in the Software 
; without restriction, including without limitation the rights to use, copy,
; modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
; and to permit persons to whom the Software is furnished to do so,
; subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in 
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


exec_AttnFlags	EQU	296

proc_MsgPort	EQU	92
proc_CLI	EQU	172

ExecSupervisor	EQU	-30
ExecForbid	EQU	-132
ExecPermit	EQU	-138
ExecFindTask	EQU	-294
ExecGetMsg	EQU	-372
ExecReplyMsg	EQU	-378
ExecWaitPort	EQU	-384
ExecOldOpenLib	EQU	-408
ExecCloseLib	EQU	-414

gfx_ActiView	EQU	$22
gfx_copinit	EQU	$26
gfx_LOFlist	EQU	$32

GfxLoadView	EQU	-222
GfxWaitTOF	EQU	-270



SafeStart:	MOVE.L	4.w,a6			; A6 = Exec base
		LEA.L	S_GraName(PC),a1	; Name: Graphics library
		JSR	ExecOldOpenLib(a6)	; Get library pointer
		MOVE.L	d0,S_GraBase		; Store for later use
		BEQ.W	.NoGraphics		; No graphics? Unusual and strange

		SUB.L	a1,a1			; A1 = NULL (find my own process)
		JSR	ExecFindTask(a6)	; Get my task/process pointer
		MOVE.L	d0,a5			; A5 = Pointer to my process
		BEQ.W	.NoWBMsg		; No pointer? Unusual and strange

		TST.L	proc_CLI(a5)		; Check if started from Shell/CLI
		BNE.B	.FromCLI		; From CLI! Skip Workbench stuff
		LEA.L	proc_MsgPort(a5),a0	; A0 = Worbench MsgPort 
		JSR	ExecWaitPort(a6)	; Wait for workbench message
		LEA.L	proc_MsgPort(a5),a0	; A0 = Worbench MsgPort 
		JSR	ExecGetMsg(a6)		; Get workbench message
		MOVE.L	d0,_S_WBMsg		; Store message pointer

.FromCLI	JSR	ExecForbid(a6)		; Do not run other tasks

		BTST.B	#0,exec_AttnFlags+1(a6)	; Check if > 68000 processor
		BEQ.B	.NoVBR			; On 68000 no VBR (always zero)
		LEA.L	_S_GetVBR(PC),a5	; Function to call as supervisor
		JSR	ExecSupervisor(a6)	; Call supervisor function in A5
		MOVE.L	d0,S_VBR		; Store the returned VBR contents
.NoVBR
		MOVE.L	S_GraBase(PC),a6	; A6 = Graphics base
		MOVE.L	gfx_ActiView(a6),-(a7)	; Store current View pointer
		SUB.L	a1,a1			; NULL view = default settings
		JSR	GfxLoadView(a6)		; Load the view
		JSR	GfxWaitTOF(a6)		; Wait one screen refresh
		JSR	GfxWaitTOF(a6)		; Wait a 2nd (in case of interlace)

		LEA.L	$DFF000,a5		; A5 = Chipset registers base address
		MOVE.W	#$8000,d0		; Value 
		MOVE.W	DMACONR(a5),-(a7)	; Store system DMA channels
		OR.W	d0,(a7)			; SET/CLR set to SET
		MOVE.W	INTENAR(a5),-(a7)	; Store system enabled interrupts
		OR.W	d0,(a7)			; SET/CLR set to SET
		MOVE.W	ADKCONR(a5),-(a7)	; Audio, disk and UART
		OR.W	d0,(a7)			; SET/CLR set to SET
		MOVE.W	VPOSR(a5),d0		; Vertical pos and Agnus ID
		BTST	#13,d0			; When set: NTSC, when clear: PAL
		BNE.B	.NTSC			; Leave value 0 for NTSC
		MOVE.W	#$FFFF,S_PAL		; Set all bits for PAL
			
.NTSC		BTST.B	#14-8,DMACONR(a5)	; Dummy read
.BltBusy	BTST.B	#14-8,DMACONR(a5)	; Blitter still busy?
		BNE.B	.BltBusy		; If yes, wait a bit
		MOVE.W	#$01FF,DMACON(a5)	; Disable all DMA
		MOVE.W	#$3FFF,INTENA(a5)	; Disable all interrupts

		MOVE.L	S_VBR(PC),a0		; A0 = Pointer to vector base
		MOVE.L	IRQ1(a0),-(a7)		; Store IRQ1 vector
		MOVE.L	IRQ3(a0),-(a7)		; Store IRQ3 vector
		MOVE.L	IRQ4(a0),-(a7)		; Store IRQ4 vector

		BSR.W	Main			; Jump to actual program

		LEA.L	$DFF000,a5		; A5 = Chipset registers base address
		BTST.B	#14-8,DMACONR(a5)	; Dummy read
.BltBusy2	BTST.B	#14-8,DMACONR(a5)	; Blitter still busy?
		BNE.B	.BltBusy2		; If yes, wait a bit
		MOVE.W	#$01FF,DMACON(a5)	; Disable all DMA
		MOVE.W	#$3FFF,INTENA(a5)	; Disable all interrupts

		MOVE.L	S_VBR(PC),a0		; A0 = Pointer to vector base
		MOVE.L	(a7)+,IRQ4(a0)		; Restore IRQ4 vector
		MOVE.L	(a7)+,IRQ3(a0)		; Restore IRQ3 vector
		MOVE.L	(a7)+,IRQ1(a0)		; Restore IRQ1 vector

		MOVE.L	S_GraBase(PC),a6	; A6 = Graphics base
		MOVE.L	gfx_copinit(a6),COP1LC(a5)	; Restore coplist pointer 1
		MOVE.L	gfx_LOFlist(a6),COP2LC(a5)	; Restore coplist pointer 2
		CLR.W	COPJMP1(a5)		; Make Copper use restored pointer

		MOVE.W	(a7)+,ADKCON(a5)	; Restore audio, disk and UART
		MOVE.W	(a7)+,INTENA(a5)	; Restore original interrupts
		MOVE.W	(a7)+,DMACON(a5)	; Restore original DMA

		MOVE.L	(a7)+,a1		; Get original view pointer
		JSR	GfxLoadView(a6)		; Restore the original view
		JSR	GfxWaitTOF(a6)		; Wait one screen refresh
		JSR	GfxWaitTOF(a6)		; Wait a 2nd (in case of interlace)

		MOVE.L	4.w,a6			; A6 = Exec base
		TST.L	_S_WBMsg		; Was there a msg from Workbench?
		BEQ.B	.NoWBMsg		; No. Nothing to do
		MOVE.L	_S_WBMsg(PC),a1		; Pointer to Workbench message
		JSR	ExecReplyMsg(a6)	; Reply message to Workbench

.NoWBMsg	MOVE.L	S_GraBase(PC),a1	; APTR to graphics base
		JSR	ExecCloseLib(a6)	; Close library 

.NoGraphics	MOVEQ	#0,d0			; Return "no errors"
		RTS

_S_GetVBR:	DC.L	$4E7A0801		; MOVEC VBR,d0
		RTE				; Return from supervisor mode

_S_WBMsg:	DC.L	0
S_VBR:		DC.L	0
S_PAL:		DC.W	0
S_GraBase:	DC.L	0
S_GraName:	DC.B	"graphics.library",0
		EVEN


