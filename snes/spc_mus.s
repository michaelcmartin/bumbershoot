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

song = square + 36
