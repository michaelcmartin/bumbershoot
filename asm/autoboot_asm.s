;;; ----------------------------------------------------------------------
;;;   Machine language autoboot template
;;;   by Michael Martin, 2025
;;;   inspired by Dan Carmichael's "Disk Autoloader", 1984
;;;
;;;   This file produces a tiny "boot" program that, if loaded with the
;;;   traditional ",8,1" arguments, will load and run a machine language
;;;   program from any point in RAM without the need for the user to type
;;;   a SYS command of their own. Customize the values for path and main
;;;   below, and note that main is the START address, not necessarily the
;;;   LOAD address. The load address will take care of itself.
;;;
;;;   If you wish the classic LOAD "*",8,1 to work, you should copy the
;;;   resulting binary from this as the first file copied into a freshly
;;;   formatted diskette.
;;; ----------------------------------------------------------------------

	.word	$02a7
	.org	$02a7

path:	.byte	"PROG NAME HERE"	; EDIT THIS LINE: 16 CHARACTER MAX

	.alias	main	$c000		; EDIT THIS LINE: START ADDRESS

;;; ----- YOU SHOULD NOT NEED TO EDIT ANYTHING PAST THIS POINT -----

	;; BASIC RAM/ROM aliases (from Mapping the C64)
	.alias	txttab	$2b
	.alias	imain	$0302
	.alias	scrtch	$a642
	.alias	ready	$a474

	;; KERNAL aliases
	.alias	setlfs	$ffba
	.alias	setnam	$ffbd
	.alias	chrout	$ffd2
	.alias	load	$ffd5
	.alias	clall	$ffe7

	;; Pad out the remainder of the filename space and assert if the
	;; filename is too long
	.alias	pathlen	^-path
	.advance path+16

	;; This code isn't golfed as hard as it could be; this is because
	;; golfing buys us nothing at this scale, we have to pad out to $0304
	;; anyway, and so that the prefix up to the call to LOAD can be as
	;; similar as possible to its BASIC-booting cousin
intercept:
	lda	#$83			; Restore the BASIC Warm Start vector
	sta	imain
	lda	#$a4
	sta	imain+1
	lda	#$01			; Open #1 from device 8 as binary
	ldx	#$08
	ldy	#$01
	jsr	setlfs
	lda	#pathlen		; Register filename
	ldx	#<path
	ldy	#>path
	jsr	setnam
	lda	#$00			; Actually do the load
	ldx	txttab			; (with TXTTAB as dummy values)
	ldy	txttab+1
	jsr	load
	jsr	scrtch			; NEW to reset BASIC runtime pointers
	lda	#$0d			; Print new line after the LOADING
	jsr	chrout
	jsr	main			; Run the actual program
	jmp	ready			; Return to BASIC prompt directly

	;; Now pad until we hit BASIC's vectors, replicate the first one
	;; with its normal value, and hijack the second (the BASIC warm
	;; start vector) with our intercept routine.
	.advance $0300
	.word	$e38b,intercept
