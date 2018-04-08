        seg data
        org $ff0000
CCA_buf_0:
        ds  $4000
CCA_buf_1:
        ds  $4000
CCA_vram_mirror:
        ds  $4000
        ;; Lesser globals
scroll_pos:
        ds  4

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
        dc.b "CYCLIC CELLULAR AUTOMATON                       "
        ;; Overseas Name
        dc.b "CYCLIC CELLULAR AUTOMATON                       "
        ;; Type of product and product/version number
        dc.b "GM 00000000-00"
        ;; Checksum: wordwise sum of all bytes from $200-ROM end
        dc.w $0000              ; Corrected by srec2smd
        ;; I/O support (J = Joystick)
        dc.b "J               "
        ;; ROM start and end
        dc.l $00000000, $000fffff ; Corrected by srec2smd
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

        bsr     BumbershootLogo
        bsr     InitFakeCGA
        bsr     CGATestPattern

freeze: bra.s   freeze

;;; Exceptions and interrupts. Pull these out if you intend to
;;; implement them yourself.
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

        include "fakecga.s"
        include "logo.s"
