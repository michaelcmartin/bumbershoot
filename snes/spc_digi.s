	org	$0204

	mov	x,#0
loop:	mov	a,!table+x
	bmi	wait
	mov	$f2,a
	inc	x
	mov	a,!table+x
	mov	$f3,a
	inc	x
	bne	loop

wait:	mov	$f2,#$fc		; Check ENDX
	byte	$aa,$f3,$00		; MOV1 C,$f3.0
	bcs	signal
	mov	a,#$ad			; Check for CPU signal
	cbne	$f4,wait
	mov	a,#$de
	cbne	$f5,wait

signal:	mov	$f2,#$5c		; key off
	mov	$f3,#$01
	mov	$f4,#$ed		; Send result code
	mov	$f5,#$fe

siglp:	mov	a,#$ed			; Wait for reply
	cbne	$f4,siglp
	mov	a,#$fe
	cbne	$f5,siglp

forever:
	bra forever

table:	dw	$206c,$ff5c,$ff4c,$025d
	dw	$0002,$0803,$0004,$0005,$e006,$7f07,$7f00,$7f01
	dw	$005c,$007c,$003d,$004d,$7f0c,$7f1c,$002c,$003c,$014c
	db	$ff
