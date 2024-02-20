	ORG	$4000

	CLRA
	CLRB
	STD	GFXIDX
	JSR	PCLS
	JSR	PMODE

	BSR	GFXREAD
	JSR	PSET

PLOTLP	LDX	GFXIDX
	CMPX	#GFXSZ
	BEQ	DOPAINT
	BSR	GFXREAD
	BNE	1F
	BSR	GFXREAD			; Y was 0, start new line sequence
	JSR	PSET			; with fresh read
	BRA	PLOTLP
1	JSR	PLINE			; Y was not 0, continue line
	BRA	PLOTLP

DOPAINT	LDD	#$6451			; TODO: These are flood fills
	JSR	PSET
	LDD	#$6690
	JSR	PSET
	LDD	#$8586
	JSR	PSET

	;; Wait for key
1	JSR	[$A000]
	BEQ	1B

        ;; Get back into normal mode
	JSR	TMODE			; Text mode
	LDA	#$60			; Clear screen
	LDX	#$0400
	STX	$88			; Home cursor
1	STA	,X+
	CMPX	#$0600
	BNE	1B
	LDX	#CREDITS		; Print credits message
1	LDA	,X+
	BEQ	1F
	JSR	[$A002]
	BRA	1B
1	RTS

GFXREAD	LDX	GFXIDX
	LDA	YGFX,X
	LDB	XGFX,X
	LEAX	1,X
	STX	GFXIDX
	ADDB	#7			; Center image
	TSTA
	RTS

	INCLUDE	"bitmap.s"

        ;; Graphics data
GFXIDX	FDB	0
XGFX	FCB	$2f,$40,$4b,$6d,$7a,$8a,$91,$88,$83,$72,$67,$5c
	FCB	$56,$56,$5d,$5f,$65,$65,$68,$68,$6b,$6b,$6d,$71
	FCB	$71,$6d,$70,$76,$78,$81,$7f,$7c,$7a,$77,$74,$74
	FCB	$75,$72,$6c,$5f,$58,$57,$5e,$65,$75,$7e,$91,$96
	FCB	$9c,$9d,$a2,$a4,$a5,$a4,$a2,$a0,$9c,$9b,$98,$9c
	FCB	$98,$9c,$9c,$a4,$c2,$ba,$bc,$b8,$b3,$b1,$a8,$ac
	FCB	$a4,$a4,$a7,$d8,$ac,$ac,$e9,$a7,$9e,$cc,$8c,$7e
	FCB	$75,$6d,$5d,$1d,$4c,$4c,$44,$01,$3f,$3f,$10,$43
	FCB	$48,$3f,$2f,$00,$14,$40,$3f,$00,$04,$40,$44,$00
	FCB	$1f,$58,$56,$5c,$62,$00,$7d,$71,$87,$95,$95,$cc
	FCB	$00,$9f,$9f,$a8,$a9,$e8,$00,$ab,$ab,$d8,$00,$a7
	FCB	$a1,$9e,$a6,$a3,$9a,$97,$9c,$98,$91,$8b,$8e,$88
	FCB	$86,$7d,$7d,$78,$78,$71,$71,$6c,$6d,$64,$60,$5c
	FCB	$5f,$58,$51,$4e,$54,$58,$64,$54,$4f,$53,$5e,$68
	FCB	$70,$76,$85,$90,$98,$9c,$a0,$a3,$a4,$a7,$00,$80
	FCB	$80,$82,$89,$90,$94,$92,$8f,$8d,$8b,$8d,$8b,$88
	FCB	$87,$85,$85,$80,$00,$4c,$50,$52,$52,$4c,$00,$68
	FCB	$6a,$73,$76,$7b,$7c,$81,$88,$81,$7d,$7b,$78,$76
	FCB	$71,$70,$71,$7e,$7a,$78,$74,$71,$6d,$69,$69

YGFX	FCB	$78,$90,$ab,$b1,$ae,$99,$8b,$92,$94,$95,$91,$87
	FCB	$76,$6d,$6d,$6a,$6a,$68,$68,$6a,$6a,$68,$68,$6d
	FCB	$73,$7d,$7f,$81,$81,$7f,$7d,$7d,$7d,$7d,$7d,$73
	FCB	$68,$63,$63,$63,$65,$62,$5c,$5b,$53,$59,$5f,$61
	FCB	$6b,$70,$74,$74,$76,$77,$77,$7a,$7e,$82,$84,$8d
	FCB	$a5,$a5,$af,$b3,$b3,$a2,$a0,$9e,$86,$7f,$6f,$6b
	FCB	$5e,$54,$4f,$4e,$45,$43,$3b,$3b,$37,$12,$2f,$2d
	FCB	$0f,$2e,$2f,$12,$35,$37,$3b,$3b,$43,$45,$4f,$4f
	FCB	$55,$6c,$78,$00,$4e,$4a,$44,$00,$3c,$3f,$3c,$00
	FCB	$12,$33,$38,$37,$2e,$00,$2d,$33,$35,$39,$31,$12
	FCB	$00,$38,$3e,$44,$3e,$3b,$00,$43,$4a,$4e,$00,$69
	FCB	$5c,$4e,$48,$45,$4b,$49,$40,$3e,$47,$46,$3c,$3a
	FCB	$45,$44,$39,$39,$44,$45,$3a,$3a,$44,$44,$3b,$3c
	FCB	$45,$47,$3e,$40,$4a,$4a,$47,$4e,$55,$58,$59,$55
	FCB	$51,$4d,$58,$5c,$5d,$5e,$62,$66,$6a,$6a,$00,$68
	FCB	$67,$64,$63,$64,$68,$6a,$6a,$68,$68,$68,$68,$69
	FCB	$68,$68,$6a,$68,$00,$94,$81,$81,$95,$94,$00,$86
	FCB	$86,$83,$83,$84,$83,$84,$86,$86,$86,$86,$86,$86
	FCB	$86,$87,$89,$8a,$8c,$8c,$8b,$8c,$89,$86,$86

GFXSZ	EQU	YGFX-XGFX

CREDITS	FCB	13,"    = PORTRAIT OF LIBERTY =",13,13
	FCB	" ORIGINAL BY JOHN JAINSCHIGG",13
	FCB	" FOR FAMILY COMPUTING, JUL 1986",13,13
	FCB	" COCO/DRAGON PORT BY",13
	FCB	" MICHAEL MARTIN, FEB 2024",13
	FCB	" BASED ON THE C64/PCJR VERSIONS",13,13,0
