	;; This somewhat roundabout Hello World program is in part a test
	;; case for cococas. The program loads into $1200, but the actual
	;; program starts at $1210. Do not change the length of the bytes
	;; before the START label or the Makefile will not correctly link
	;; a working cassette image.

	ORG	$1200

DONE	RTS
MSG	FCB	"HELLO, WORLD!",13,0

START	LDX	#MSG
LP	LDA	,X+
	BEQ	DONE
	JSR	[$A002]
	BRA	LP
