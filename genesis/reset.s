;;; -----------------------------------------------------
;;;
;;;       Sega startup code for the ASMX assembler
;;;
;;;        Translated from:
;;;        Sega startup code for the Sozobon C compiler
;;;        Written by Paul W. Lee
;;;        Modified from Charles Coty's code
;;;        Modified by Stephane Dallongeville
;;;        Modified by Michael Martin
;;;

RESET:  tst.l   $a10008
	bne.s   @SkipJoyDetect
        tst.w   $a1000c
@SkipJoyDetect:
	bne.s   @SkipSetup
        lea     @InitData(pc),a5
        movem.w (a5)+,d5-d7
        movem.l (a5)+,a0-a4
        ;; Appease lockout circuitry
        move.b  -$10ff(a1),d0
        andi.b  #$0f,d0
	beq.s   @LockoutOK
        move.l  #$53454741,$2f00(a1)
@LockoutOK:
        move.w  (a4),d0
        moveq   #$00,d0
        movea.l d0,a6
        move    a6,usp

        ;; Set VDP registers
        moveq   #$17,d1
@RegLp: move.b  (a5)+,d5
        move.w  d5,(a4)
        add.w   d7,d5
        dbra    d1,@RegLp

        ;; Fire off DMA (Zero out VRAM)
        move.l  (a5)+,(a4)
        move.w  d0,(a3)

        ;; Capture bus from Z80
        move.w  d7,(a1)
        move.w  d7,(a2)
@ZWait: btst    d0,(a1)
	bne.s   @ZWait

        ;; Load Z80 reset program
        moveq   #$25,d2
@ZFill: move.b  (a5)+,(a0)+
        dbra    d2,@ZFill
        
        ;; Give control back to Z80
        move.w  d0,(a2)
        move.w  d0,(a1)
        move.w  d7,(a2)

        ;; Clear out RAM
@RamLp: move.l  d0,-(a6)
        dbra    d6,@RamLp

        ;; Clear CRAM
        move.l  (a5)+,(a4)
        move.l  (a5)+,(a4)

        moveq   #$1f,d3
@CClr:  move.l  d0,(a3)
        dbra    d3,@CClr

        ;; Clear VSRAM
        move.l  (a5)+,(a4)
        moveq   #$13,d4
@VSClr: move.l  d0,(a3)
        dbra    d4,@VSClr
        
        ;; Reset the PSG
        moveq   #$03,d5
@PSGLp: move.b  (a5)+,$0011(a3)
        dbra    d5,@PSGLp

        ;; Lock the Z80 in RESET
        move.w  d0,(a2)

        ;; Disable interrupts, clear all registers
        movem.l (a6),d0-d7/a0-a6
        move    #$2700,sr
@SkipSetup:
	bra.s   @main

;;; -----------------------------------------------------
;;; Initialization data
;;; -----------------------------------------------------
@InitData:
        ;; Initial values for d5-d7
        dc.w    $8000, $3fff, $0100
        ;; Initial values for a0-a4
        dc.l    $00a00000, $00a11100, $00a11200, $00c00000, $00c00004
        ;; Initial values for VDP registers
        hex     04 14 30 2c 07 54 00 00 00 00 00 00
        hex     81 2b 00 01 01 00 00 ff ff 00 00 80

        ;; VRAM fill target
        dc.w    $4000, $0080

        ;; Z80 Initialization Code
        hex     af 01 d9 1f 11 27 00 21 26 00 f9 77 ed b0 dd e1
        hex     fd e1 ed 47 ed 4f d1 e1 f1 08 d9 c1 d1 e1 f1 f9
        hex     f3 ed 56 36 e9 e9

        ;; CRAM and VSRAM fill controls commands
        dc.w    $8104, $8f01, $c000, $0000, $4000, $0010

        ;; PSG Reset commands
        dc.b    $9f, $bf, $df, $ff
;;; -----------------------------------------------------

@main:  ;; Program start follows!

