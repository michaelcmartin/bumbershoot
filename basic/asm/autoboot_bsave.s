	.org	$34c
	.alias	path	$33c

	.alias	setlfs	$ffba
	.alias	setnam	$ffbd
	.alias	save	$ffd8
	.alias	clall	$ffe7

	lda	#$00
	ldx	#<path
	ldy	#>path
	jsr	setnam
	lda	#$08
	tax
	ldy	#$ff
	jsr	setlfs
	lda	#$a7
	sta	$fb
	lda	#$b7
	sta	$0302
	lda	#$02
	sta	$fc
	sta	$0303
	lda	#$fb
	ldx	#$04
	ldy	#$03
	jsr	save
	jsr	clall
	lda	#$83
	sta	$0302
	lda	#$a4
	sta	$0303
	rts
