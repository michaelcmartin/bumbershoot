	org	$0204

	mov	x,#0
loop:	mov	a,!table+1+x
	mov	y,a
	mov	a,!table+x
	bmi	wait
	inc	x
	inc	x
	movw	$f2,ya
	bra	loop

wait:	mov	a,#$fc			; Check ENDX
	mov	$f2,a
	mov	a,$f3
	and	a,#$01
	bne	signal
	mov	a,$f4			; Check for CPU signal
	cmp	a,#$ad
	bne	wait
	mov	a,$f5
	cmp	a,#$de
	bne	wait

signal:	mov	a,#$ed			; Send result code
	mov	$f4,a
	mov	a,#$fe
	mov	$f5,a
	mov	a,#$5c			; key off
	mov	y,#$01
	movw	$f2,ya

siglp:	mov	a,$f4			; Wait for reply
	cmp	a,#$ed
	bne	siglp
	mov	a,$f5
	cmp	a,#$fe
	bne	siglp

forever:
	bra forever

table:	dw	$206c,$004c,$ff5c,$025d
	dw	$7f00,$7f01,$0002,$0803,$0004,$0005,$e006,$7f07
	dw	$005c,$007c,$003d,$004d,$7f0c,$7f1c,$002c,$003c,$014c
	db	$ff
