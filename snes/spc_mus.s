	initial = $00
	current = $02

	;; Sample directory
	org	$0200
	word	square, square

	;; Initialize song pointers
	mov 	a,#(song&$ff)
	mov	initial,a
	mov	current,a
	mov	a,#(song>>8)
	mov	initial+1,a
	mov	current+1,a

	;; Initialize timer to 64Hz
	mov	$fa,#125
	mov	$f1,#$81

	;; Lock Y at 0 for song processing
start:	mov	y,#0
main:	mov	a,[current]+y
	bmi	cmd
	mov	$f2,a
	incw	current
	mov	a,[current]+y
	mov	$f3,a
	incw	current
	bra	main
cmd:	incw	current
	and	a,#$7f
	beq	lpback
pause:	setc
	sbc	a,$fd
	bmi	main
	bne	pause
	bra	main
lpback:	clrc
	mov	a,initial
	adc	a,[current]+y
	mov	x,a
	inc	y			; Changing Y here is fine because
	mov	a,initial+1		; current changes totally, and so
	adc	a,[current]+y		; when we loop back we can just
	mov	current,x		; loop back to where we zero out Y
	mov	current+1,a		; again
	bra	start

square:	byte	$b0,$77,$77,$77,$77,$77,$77,$77,$77
	byte	$b0,$77,$77,$77,$77,$77,$77,$77,$77
	byte	$b0,$88,$88,$88,$88,$88,$88,$88,$88
	byte	$b3,$88,$88,$88,$88,$88,$88,$88,$88

song:	byte    $6c,$20,$0c,$7f,$1c,$7f,$2c,$00,$3c,$00,$4c,$00,$5c,$ff,$2d,$00
        byte    $3d,$00,$4d,$00,$5d,$02,$5c,$00,$00,$7f,$01,$7f,$04,$00,$05,$9f
        byte    $06,$1a,$02,$5f,$03,$08,$5c,$00,$4c,$01,$9c,$5c,$01,$84,$02,$65
        byte    $03,$09,$5c,$00,$4c,$01,$9c,$5c,$01,$84,$02,$8c,$03,$0a,$5c,$00
        byte    $4c,$01,$9c,$5c,$01,$84,$02,$2c,$03,$0b,$5c,$00,$4c,$01,$9c,$5c
        byte    $01,$84,$02,$8b,$03,$0c,$5c,$00,$4c,$01,$9c,$5c,$01,$84,$02,$14
        byte    $03,$0e,$5c,$00,$4c,$01,$9c,$5c,$01,$84,$02,$cd,$03,$0f,$5c,$00
        byte    $4c,$01,$9c,$5c,$01,$84,$02,$be,$03,$10,$5c,$00,$4c,$01,$9c,$5c
        byte    $01,$84,$5c,$00,$f0,$80,$22,$00
