	ORG	$1200

	CLRA
	LDX	#$0400
LP	STA	,X+
	INCA
	BNE	LP
	LDA	#$60
LP2	STA	,X+
	CMPX	#$0600
	BNE	LP2
	LDD	#$0400+32*8
	STD	<$88
	RTS
