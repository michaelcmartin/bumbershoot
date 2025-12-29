;;; COLECOVISION "Silent Start" initialization code
;;;
;;; To disable the 12-second startup screen for your CV programs, follow
;;; these steps:
;;;
;;;   1. Change the $55AA word at $8000 to $AA55.
;;;   2. Ensure that you have allocated 12 bytes for the BIOS controller
;;;      I/O RAM, with its address registered at $8008 in the header.
;;;   3. Include coleco_bios.asm in the same file that defines your main
;;;      entry point.
;;;   4. Include this file (silent_start.asm) at the very start of your
;;;      main entry point.
;;;
;;; This will configure the VDP and "Table-level API" the same way the
;;; normal boot sequence does; the VRAM, however, will be empty. You
;;; may wish to call LOAD_ASCII yourself if you intend to use the
;;; system font on your own.

	call	TURN_OFF_SOUND
	ld	a,$33
	ld	(RAND_NUM),a
	xor	a
	ld	(DEFER_WRITES),a
	ld	(MUX_SPRITES),a
	out	($c0),a			; Init/clear controller space
	xor	a
	ld	hl,(CONTROLLER_MAP)
	inc	hl
	inc	hl
	ld	b,10
1	ld	(hl),a
	inc	hl
	djnz	1B
	ld	hl,$73d7
	ld	b,27
1	ld	(hl),a
	inc	hl
	djnz	1B
	call	MODE_1
	xor	a			; Clear VRAM
	ld	de,$4000
	ld	h,a
	ld	l,a
	call	FILL_VRAM

