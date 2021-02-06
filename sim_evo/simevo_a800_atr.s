;;; ATR disk header
        .word   $0296, $2080, $80
        .advance $10
        .outfile "simevo.atr"

;;; Boot sector: loaded into cassette buffer ($0400) then copied to
;;; its origin ($0700)
        .org    $0700

        ;; Boot data
        .byte   0               ; Flags
        .byte   [end-$681]/128  ; Number of sectors
        .word   $0700
        .word   init

        ;; Copy the location at the end of our program to MEMLO and
        ;; APPMHI. This should include the unloaded space used by
        ;; scratch RAM.
        lda     #$00
        sta     $02e7
        sta     $14
        lda     #$40
        sta     $2e8
        sta     $15
        ;; Now initialize DOSVEC so restart works the way we expect
        lda     #<start
        sta     $0a
        lda     #>start
        sta     $0b

        ;; Boot succeeded!
        clc

        ;; Fall through to the program init routine, which does
        ;; nothing, so this is a dual-purpose return statement
init:   rts

        .alias  bssstart $2000
        .alias  bitmap   $3000
start:  .include "simevo_a800_shell.s"
end:

        ;; Now we need to null out the rest of the disk.
        ;; The disk is $20800, so we have to juggle our PC a bit.

        .advance $2700
        .org 0
        .advance $6000
        .org 0
        .advance $8000
        .org 0
        .advance $8000
        .org 0
        .advance $8800
        .org 0
