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
        dc.b "BUMBERSHOOT SOFTWARE LOGO                       "
        ;; Overseas Name
        dc.b "BUMBERSHOOT SOFTWARE LOGO                       "
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

        movea.l #$C00000, a0
        movea.l a0, a1
        addq    #4, a1

        ;; Load logo into VRAM normally
        ;;         move.w  #8f02, (a1)
        ;;         move.l  #$40200000, (a1)
        ;;         movea.l #logo, a2
        ;;         move.w  #((logoend-logo) / 4)-1,d0
        ;; @lp:    move.l  (a2)+, (a0)
        ;;         dbra    d0, @lp

        ;; Load logo into VRAM with BLAST PROCESSING
        move.w  #$8114, (a1)    ; Enable DMA
        move.w  #$8f02, (a1)    ; Word writes
        move.w  #$9300 + (((logoend-logo) >> 1) & $ff), (a1)
        move.w  #$9400 + ((logoend-logo) >> 9), (a1)
        move.w  #$9500 + ((logo >> 1) & $ff), (a1)
        move.w  #$9600 + ((logo >> 9) & $ff), (a1)
        move.w  #$9700 + ((logo >> 17) & $ff), (a1)
        move.w  #$4020, (a1)
        move.w  #$0080, $ff0000
        move.w  $ff0000, (a1)
@dma:   btst    #3, (a1)
        bne.s   @dma

        ;; Load some colors into VRAM
        move.l  #$c0000000, (a1)
        movea.l #pal, a2
        moveq   #7, d0
@lp2:   move.l  (a2)+, (a0)
        dbra    d0, @lp2

        ;; Lay out the logo, starting at (10, 1)
        move.l  #$40940003, (a1)
        moveq   #$1, d2         ; Tile counter
        moveq   #$18, d0        ; 25 rows
@row:   moveq   #$13, d1        ; 20 columns
@rlogo: move.w  d2, (a0)
        addq    #1, d2
        dbra    d1, @rlogo
        moveq   #$2b, d1        ; 44 blanks to start of next row
@rblnk: move.w  #$0000, (a0)
        dbra    d1, @rblnk
        dbra    d0, @row

        ;; Enable the display
        move.w  #$8144, (a1)

freeze: bra.s    freeze

        align   2
        include "logogfx.s"

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
        
