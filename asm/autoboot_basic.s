;;; ----------------------------------------------------------------------
;;;   BASIC autoboot template
;;;   by Michael Martin, 2025
;;;   inspired by Dan Carmichael's "Disk Autoloader", 1984
;;;
;;;   This file produces a tiny "boot" program that, if loaded with the
;;;   traditional ",8,1" arguments, will load and run a BASIC program
;;;   without the need for the user to type RUN on their own. Unlike the
;;;   1984 edition, this version will correctly relink programs where the
;;;   base address is incorrect.
;;;
;;;   To use this for your own programs, customize the value for path
;;;   in the code below.
;;;
;;;   If you wish the classic LOAD "*",8,1 to work, you should copy the
;;;   resulting binary from this as the first file copied into a freshly
;;;   formatted diskette.
;;; ----------------------------------------------------------------------


	.word	$02a7
	.org	$02a7

path:	.byte	"PROG NAME HERE"	; EDIT THIS LINE: 16 CHARACTER MAX

;;; ----- YOU SHOULD NOT NEED TO EDIT ANYTHING PAST THIS POINT -----

	;; BASIC RAM/ROM aliases (from Mapping the C64)
	.alias	txttab	$2b
	.alias	vartab	$2d
	.alias	arytab	$2f
	.alias	imain	$0302
	.alias	ready	$a474
	.alias	linkprg	$a533

	;; KERNAL aliases
	.alias	setlfs	$ffba
	.alias	setnam	$ffbd
	.alias	load	$ffd5
	.alias	clall	$ffe7

	;; Pad out the remainder of the filename space and assert if the
	;; filename is too long
	.alias	pathlen	^-path
	.advance path+16

	;; This code isn't golfed as hard as it could be; this is because
	;; golfing buys us nothing at this scale, we have to pad out to $0304
	;; anyway, and so that the prefix up to the call to LOAD can be as
	;; similar as possible to its machine-language-booting cousin
intercept:
	lda	#$83			; Restore the BASIC Warm Start vector
	sta	imain
	lda	#$a4
	sta	imain+1
	lda	#$01			; Open #1 from device 8 as BASIC
	ldx	#$08
	ldy	#$00
	jsr	setlfs
	lda	#pathlen		; Register filename
	ldx	#<path
	ldy	#>path
	jsr	setnam
	lda	#$00			; Actually do the load
	ldx	txttab			; into BASIC's program space
	ldy	txttab+1
	jsr	load
	stx	vartab			; Set variable space to region
	stx	arytab			; just past end of load
	sty	vartab+1
	sty	arytab+1
	jsr	clall			; Close I/O channels
	jsr	linkprg			; Relink program if necessary
	ldx	#$04			; Reserve 4 characters in KB buffer
	stx	$c6
	dex
*	lda	revcmd,x		; Copy "RUN<enter>" into the
	sta	$0277,x			; keyboard buffer itself
	dex
	bpl	-
	jmp	ready			; Return to BASIC main loop to RUN

	;; Command to stuff into KB buffer
revcmd:	.byte	"RUN",13

	;; Now pad until we hit BASIC's vectors, replicate the first one
	;; with its normal value, and hijack the second (the BASIC warm
	;; start vector) with our intercept routine.
	.advance $0300
	.word	$e38b,intercept
