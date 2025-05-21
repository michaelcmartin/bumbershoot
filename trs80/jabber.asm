cls	equ	$01c9

	org	$6a00

	call	cls
	ld	hl,msg		; Source ptr
	ld	ix,$3cc0	; Dest ptr
	ld	de,32		; Line stride
	ld	c,13		; Number of lines
lp_0:	ld	b,32		; Number of chars/line
lp_1:	ld	a,(hl)
	ld	(ix),a
	ld	(ix+32),a
	inc	ix
	inc	hl
	djnz	lp_1
	add	ix,de
	dec	c
	jr	nz,lp_0
	ret

msg:	defm	"'Twas brillig,                  "
	defm	"    and the slithy toves        "
	defm	"Did gyre and gimble             "
	defm	"    in the wabe:                "
	defm	"All mimsy were the borogoves    "
	defm	"And the mome raths outgrabe.    "
	defm    "                                "
	defb	34
	defm    "Beware the Jabberwock, my son! "
	defm	"The jaws that bite,             "
	defm	"    the claws that catch!       "
	defm	"Beware the Jub-Jub bird,        "
	defm	"    and shun                    "
	defm	"The frumious bandersnatch!"
	defb	34
	defm	"      "
