	define	SMS
	include	"sega8bios.asm"

main:	ld	hl,palette
	ld	de,$8000
	ld	bc,4
	rst	blit_vram

	ld	hl,msg
	ld	de,$3ad2
	ld	bc,26
	rst	blit_vram
	ld	hl,gfx
	ld	de,0
	ld	bc,$140
	rst	blit_vram

	ld	hl,$1c0
	rst	set_vdp_register

1	halt
	jr	1B

msg:    defw    1,2,3,3,4,5,0,6,4,7,3,8,9
gfx:    defd    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
        defd    $0000,$6200,$6211,$7e7f,$627f,$6211,$6211,$0031
        defd    $0000,$7e00,$601f,$7c7c,$607e,$6010,$7e00,$003f
        defd    $0000,$6000,$6010,$6070,$6070,$6010,$7e00,$003f
        defd    $0000,$3c00,$621c,$6273,$6273,$6211,$3c01,$001e
        defd    $0000,$0000,$0000,$0000,$0000,$0000,$1800,$300c
        defd    $0000,$6200,$6211,$6273,$6a7b,$7601,$6219,$0031
        defd    $0000,$7c00,$6618,$7c7f,$687e,$6410,$6210,$0031
        defd    $0000,$7c00,$621c,$6273,$6273,$6211,$7c01,$003e
        defd    $0000,$1800,$1804,$181c,$181c,$000c,$1800,$000c

palette:
	defb	$00,$15,$2a,$3f
