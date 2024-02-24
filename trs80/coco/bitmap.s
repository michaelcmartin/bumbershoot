;;;----------------------------------------------------------------------
;;;  Mode 6R Graphics Library for CoCo/Dragon
;;;  This file defines the following functions for use in the 256x192x2
;;;  graphics mode.
;;;
;;;  PMODE: Enter graphics mode. Trashes registers X and D.
;;;  TMODE: Return to text mode. Trashes registers X and D.
;;;  PCLS:  Clears screen to pattern in A. Trashes registers X, Y, and D.
;;;  PCOLOR: Sets color to value in A. Trashes register D.
;;;  PSET: Draws a point in the current color at coordinate (B, A).
;;;  PSET0: As PSET, but always in color 0.
;;;  PSET1: As PSET, but always in color 1.
;;;  POINT: Zero flag set if pixel at (B, A) matches current color.
;;;  PLINE: Draw line from last PSET/POINT/PLINE coordinate to (B, A).
;;;  PAINT: Flood-fill current color at (B, A).
;;;
;;;  The asm6809 assembler doesn't have great support for local/scoped
;;;  labels, so the code below makes aggressive use of "temporary" labels
;;;  with very side scope. Local static variables etc are commented in
;;;  their locations, and are not important to the code that includes it.
;;;----------------------------------------------------------------------

	;; Set graphics mode 6R (256x192x2).
PMODE	LDA	$FF22
	ANDA	#7
	ORA	#$F0
	STA	$FF22
	STA	$FFC0
	STA	$FFC3
	STA	$FFC5
	LDA	$BC
	BRA	1F

	;; Set text mode
TMODE	LDA	$FF22
	ANDA	#7
	STA	$FF22
	STA	$FFC0
	STA	$FFC2
	STA	$FFC4
	LDA	#$04
	;; Fall into common epilogue for PMODE and TMODE

1	;; Set display address page to value in A. A must be even.
	LSRA
	LDX	#$FFC6
2	CLRB
	LSRA
	ROLB
	STA	B,X
	LEAX	2,X
	CMPX	#$FFD4
	BNE	2B
	RTS

	;; Clear screen to the pattern in A.
PCLS	PSHS A
	LDA	$BC
	CLRB
	TFR	D,X
	LDY	#$1800
	PULS	A
1	STA	,X+
	LEAY	-1,Y
	BNE	1B
	RTS

PCOLOR	TSTA
	BEQ	1F
	LDA	#$FF
	STA	101F
	LDD	#PSET1
	BRA	2F
1	CLR	101F
	LDD	#PSET0
2	STD	100F
	RTS

PSET	JMP	[100F]

PSET1	PSHS	D,X,Y
	BSR	1F
	ANDB	#$07
	LDY	#2F
	LDA	B,Y
	ORA	,X
	STA	,X
	PULS	D,X,Y,PC

PSET0	PSHS	D,X,Y
	BSR	1F
	ANDB	#$07
	LDY	#3F
	LDA	B,Y
	ANDA	,X
	STA	,X
	PULS	D,X,Y,PC

POINT	PSHS	D,X,Y
	BSR	1F
	ANDB	#$07
	LDA	,X
	EORA	101F
	LDY	#2F
	ANDA	B,Y
	PULS	D,X,Y,PC

1	;; Compute address for X=B, Y=A. Result in X. A, B unchanged.
	PSHS	D
	STD	98F
	LSRA
	RORB
	LSRA
	RORB
	LSRA
	RORB
	ADDA	$BC
	TFR	D,X
	PULS	D,PC

	;; Mask table for PSET1 and POINT
2	FCB	$80,$40,$20,$10,$08,$04,$02,$01

	;; Mask table for PSET0
3	FCB	$7F,$BF,$DF,$EF,$F7,$FB,$FD,$FE

PLINE	LEAS	-10,S			; Allocate stack frame
	STD	8,S			; 8,S = y2, 9,S = x2
	SUBB	99F			; B = dx = x2 - x1
	BEQ	1F			;  sgn(dx) = 0?
	BLO	2F			;  sgn(dx) = -1?
	LDA	#$01			;  sgn(dx) = 1
	STA	7,S			; 7,S = sgn(x2-x1)
	CLRA
	BRA	3F
1	CLRA
	STA	7,S
	BRA	3F
2	LDA	#$FF
	STA	7,S
	STD	4,S			; Negate D
	CLRA
	CLRB
	SUBD	4,S
3	LSLB
	ROLA
	STD	4,S			; 4,S = 2 * abs(x2-x1)
	LDB	8,S
	SUBB	98F			; B = dy = y2 - y1
	BEQ	1F			;  sgn(dy) = 0?
	BLO	2F			;  sgn(dy) = -1?
	LDA	#$01			;  sgn(dy) = 1
	STA	6,S			; 6,S = sgn(y2-y1)
	CLRA
	BRA	3F
1	CLRA
	STA	6,S
	BRA	3F
2	LDA	#$FF
	STA	6,S
	STD	2,S			; Negate D
	CLRA
	CLRB
	SUBD	2,S
3	LSLB
	ROLA
	STD	2,S			; 2,S = 2 * abs(y2-y1)
	CMPD	4,S			; |dy| >= |dx|?
	BGE	1F			; If so, go to Y dominant case
	CLRA				; X dominant: d = -(dx >> 1)
	CLRB
	SUBD	4,S
	ASRA
	RORB
	STD	,S			; 0,S = d (remainder count)
2	LDD	98F			; Plot at x, y
	JSR	[100F]
	CMPB	9,S			; x = x2?
	BEQ	4F			; ... if so, done
	LDD	,S			; d += dy
	ADDD	2,S
	STD	,S
	BLT	3F			; d >= 0?
	SUBD	4,S			; If so, d -= dx...
	STD	,S
	LDB	98F			; ... and y += sy
	ADDB	6,S
	STB	98F
3	LDB	99F			; x += sx
	ADDB	7,S
	STB	99F
	BRA	2B
1	CLRA				; Y dominant: d = -(dy >> 1)
	CLRB
	SUBD	2,S
	ASRA
	RORB
	STD	,S			; 0,S = d (remainder count)
2	LDD	98F			; Plot at x, y
	JSR	[100F]
	CMPA	8,S			; y = y2?
	BEQ	4F			; ... if so, done
	LDD	,S			; d += dx
	ADDD	4,S
	STD	,S
	BLT	3F			; d >= 0?
	SUBD	2,S			; If so, d -= dy...
	STD	,S
	LDB	99F			; ... and x += sx
	ADDB	7,S
	STB	99F
3	LDB	98F			; y += sy
	ADDB	6,S
	STB	98F
	BRA	2B
4	LEAS	8,S			; Line drawn. restore stack
	PULS	D,PC			; and registers and return

PAINT	PSHS	D			; Save args only once, to save
	BSR	3F			; recursive stack. '3' here is the
	PULS	D,PC			; real PAINT implementation.
3	JSR	POINT			; First check: already filled?
	BEQ	2F			; If so, abort
1	JSR	PSET
	PSHS	B			; Save out (Y, X, X) to
	PSHS	D			; become our range
1	DEC	1,S
	LDD	,S
	CMPB	#$FF			; Did we go off the left edge?
	BEQ	1F
	JSR	POINT			; Are we at a drawn boundary?
	BEQ	1F
	JSR	PSET
	BRA	1B
1	INC	1,S
1	INC	2,S
	LDA	,S
	LDB	2,S
	TSTB				; Did we go off the right edge?
	BEQ	1F
	JSR	POINT
	BEQ	1F
	JSR	PSET
	BRA	1B
	;; Stack now holds, in order: base Y, min X, max X + 1. Recurse
	;; up and down from each point in range to complete the
	;; flood fill.
1	LDD	,S
	DECA
	CMPA	#$C0
	BHS	4F
	BSR	3B
4	LDD	,S
	INCA
	CMPA	#$C0
	BHS	4F
	BSR	3B
4	INC	1,S
	LDB	1,S
	CMPB	2,S
	BNE	1B
	LEAS	3,S
2	RTS

	;; In-program memory store
98	FCB	0			; Last Y location
99	FCB	0			; Last X location
100	FDB	PSET1			; Current draw color
101	FCB	$FF			; POINT read mask
