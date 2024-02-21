	ORG	$4000

	CLRA
	JSR	PCOLOR
	LDA	#$FF
	JSR	PCLS
	JSR	PMODE

	LDX	#GFX
	LDD	,X++
	JSR	PSET

PLOTLP	CMPX	#GFXEND
	BEQ	DOPAINT
	LDD	,X++
	BNE	1F
	LDD	,X++			; Start new line sequence
	JSR	PSET			; with fresh read
	BRA	PLOTLP
1	JSR	PLINE			; Y was not 0, continue line
	BRA	PLOTLP

DOPAINT	LDD	#$6451
	JSR	PAINT
	LDD	#$6690
	JSR	PAINT
	LDD	#$8586
	JSR	PAINT

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

	INCLUDE	"bitmap.s"

        ;; Graphics data
GFX	FDB	$783D,$904E,$AB59,$B17B,$AE88,$9998,$8B9F,$9296
	FDB	$9491,$9580,$9175,$876A,$7664,$6D64,$6D6B,$6A6D
	FDB	$6A73,$6873,$6876,$6A76,$6A79,$6879,$687B,$6D7F
	FDB	$737F,$7D7B,$7F7E,$8184,$8186,$7F8F,$7D8D,$7D8A
	FDB	$7D88,$7D85,$7D82,$7382,$6883,$6380,$637A,$636D
	FDB	$6566,$6265,$5C6C,$5B73,$5383,$598C,$5F9F,$61A4
	FDB	$6BAA,$70AB,$74B0,$74B2,$76B3,$77B2,$77B0,$7AAE
	FDB	$7EAA,$82A9,$84A6,$8DAA,$A5A6,$A5AA,$AFAA,$B3B2
	FDB	$B3D0,$A2C8,$A0CA,$9EC6,$86C1,$7FBF,$6FB6,$6BBA
	FDB	$5EB2,$54B2,$4FB5,$4EE6,$45BA,$43BA,$3BF7,$3BB5
	FDB	$37AC,$12DA,$2F9A,$2D8C,$0F83,$2E7B,$2F6B,$122B
	FDB	$355A,$375A,$3B52,$3B0F,$434D,$454D,$4F1E,$4F51
	FDB	$5556,$6C4D,$783D,$0000,$4E22,$4A4E,$444D,$0000
	FDB	$3C12,$3F4E,$3C52,$0000,$122D,$3366,$3864,$376A
	FDB	$2E70,$0000,$2D8B,$337F,$3595,$39A3,$31A3,$12DA
	FDB	$0000,$38AD,$3EAD,$44B6,$3EB7,$3BF6,$0000,$43B9
	FDB	$4AB9,$4EE6,$0000,$69B5,$5CAF,$4EAC,$48B4,$45B1
	FDB	$4BA8,$49A5,$40AA,$3EA6,$479F,$4699,$3C9C,$3A96
	FDB	$4594,$448B,$398B,$3986,$4486,$457F,$3A7F,$3A7A
	FDB	$447B,$4472,$3B6E,$3C6A,$456D,$4766,$3E5F,$405C
	FDB	$4A62,$4A66,$4772,$4E62,$555D,$5861,$596C,$5576
	FDB	$517E,$4D84,$5893,$5C9E,$5DA6,$5EAA,$62AE,$66B1
	FDB	$6AB2,$6AB5,$0000,$688E,$678E,$6490,$6397,$649E
	FDB	$68A2,$6AA0,$6A9D,$689B,$6899,$689B,$6899,$6996
	FDB	$6895,$6893,$6A93,$688E,$0000,$945A,$815E,$8160
	FDB	$9560,$945A,$0000,$8676,$8678,$8381,$8384,$8489
	FDB	$838A,$848F,$8696,$868F,$868B,$8689,$8686,$8684
	FDB	$867F,$877E,$897F,$8A8C,$8C88,$8C86,$8B82,$8C7F
	FDB	$897B,$8677,$8677
GFXEND

CREDITS	FCB	13,"    = PORTRAIT OF LIBERTY =",13,13
	FCB	" ORIGINAL BY JOHN JAINSCHIGG",13
	FCB	" FOR FAMILY COMPUTING, JUL 1986",13,13
	FCB	" COCO/DRAGON PORT BY",13
	FCB	" MICHAEL MARTIN, FEB 2024",13
	FCB	" BASED ON THE C64/PCJR VERSIONS",13,13,0
