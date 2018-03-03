        seg text
        org 0

;;; -----------------------------------------------------
;;;  Initialization, interrupt and exception vectors
;;; -----------------------------------------------------
        dc.l 0,RESET
        dc.l BUS_ERROR, ADDR_ERROR, ILLEGAL_INST, ZERO_DIV
        dc.l CHK_INST, TRAPV_INST, PRIV_VIOLATION, TRACE
        dc.l LINE_1010, LINE_1111
        dc.l INT,INT,INT,INT,INT,INT,INT,INT
        dc.l INT,INT,INT,INT,INT,INT,EXTINT,INT
        dc.l HBL,INT,VBL,INT
        dc.l INT,INT,INT,INT,INT,INT,INT,INT
        dc.l INT,INT,INT,INT,INT,INT,INT,INT
        dc.l INT,INT,INT,INT,INT,INT,INT,INT
        dc.l INT,INT,INT,INT,INT,INT,INT,INT

;;; -----------------------------------------------------
;;;  Header and metadata
;;; -----------------------------------------------------
        ;; Console name, copyright name and date
        dc.b "SEGA GENESIS    "
        dc.b "(C)BUMB 2018.FEB"
        ;; Domestic Name
        dc.b "HELLO WORLD BUMBERSHOOT 2018                    "
        ;; Overseas Name
        dc.b "HELLO WORLD BUMBERSHOOT 2018                    "
        ;; Type of product and product/version number
        dc.b "GM 00000000-00"
        ;; Checksum: wordwise sum of all bytes from $200-ROM end
        dc.w $0000
        ;; I/O support (J = Joystick)
        dc.b "J               "
        ;; ROM start and end
        dc.l $00000000, $00003fff ; 16 KB
        ;; RAM start and end
        dc.l $00ff0000, $00ffffff
        ;; Save RAM: 'RA' if active
        dc.b "  "
        ;; Save RAM type: $F820 for save RAM on odd bytes
        dc.w $2020
        ;; Save RAM start and end address; normally $200001 and then
        ;; start + 2 * sram_size
        dc.l $20202020, $20202020
        ;; Modem data
        dc.b "            "
        ;; Memo
        dc.b "                                        "
        ;; Permissible regions: Japan, US, Europe
        dc.b "JUE             "

        include "reset.s"

        movea.l #$C00000, a0
        move.w  #$8f02, 4(a0)

        ;; Load font into VRAM
        move.l  #$44000000, 4(a0)
        movea.l #font, a1
        move.w  #(fontend-font)-1,d0
@lp:    move.b  (a1)+, d1
        moveq   #7, d2
@lp2:   asl.l   #4, d3
        asl.b   #1, d1
        bcc.s   @nobit
        ori.b   #1, d3
@nobit: dbra    d2, @lp2
        move.l  d3, (a0)
        dbra    d0, @lp

        ;; Load some colors into VRAM
        move.l  #$c0000000, 4(a0)
        move.l  #$FFF, (a0)

        ;; Display our message
        lea     msg1, a1
        move.w  #$069E, d0
        bsr.s   strout
        lea     msg2, a1
        move.w  #$0714, d0
        bsr.s   strout

        ;; Enable the display
        move.w  #$8144, 4(a0)

freeze: bra.s    freeze

        ;; This code assumes a0 is already c00000 and that the
        ;; target field is at $C000 in VRAM and that the VRAM
        ;; increment is 2.
strout: ori     #$4000, d0
        move.w  d0, 4(a0)
        move.w  #$0003, 4(a0)
        clr.l   d0
@lp:    move.b  (a1)+, d0
        beq.s   @done
        move.w  d0, (a0)
        bra.s   @lp
@done:  rts

        align   2
font:
        include "sinestra.s"
fontend:

msg1:   dc.b    "HELLO FROM",0
msg2:   dc.b    "BUMBERSHOOT SOFTWARE",0


;;; Exceptions and interrupts all get ignored.
BUS_ERROR:
ADDR_ERROR:
ILLEGAL_INST:
ZERO_DIV:
CHK_INST:
TRAPV_INST:
PRIV_VIOLATION:
TRACE:
LINE_1010:
LINE_1111:
EXTINT:
INT:
HBL:
VBL:
	rte
