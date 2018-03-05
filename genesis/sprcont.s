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
        dc.b "SPRITE AND JOYSTICK TEST                        "
        ;; Overseas Name
        dc.b "SPRITE AND JOYSTICK TEST                        "
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
        bra     main

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

        include "text.s"
        include "joystick.s"

main:   move.l  #sinestra, -(sp)
        bsr     LoadFont

        move.l  #(CRAM_WRITE << 16), (sp)
        bsr     SetVRAMPtr
        move.l  #$00000eee, $c00000

        move.l  #headers, (sp)
        bsr.s   DrawStrings

        move.w  #$8144, $c00004

        moveq   #$0, d7
        lea     upstr(pc), a3
mainlp: move.l  VRAM_CONTROL(pc), a0
@v1:    move.w  (a0), d0
        btst    #3, d0          ; Wait for no VBLANK
        bne.s   @v1
@v2:    move.w  (a0), d0
        btst    #3, d0          ; Wait for VBLANK
        beq.s   @v2
        ;; Clear the control display
        move.l  #(VRAM_WRITE << 16) | ($C000+128*11), (sp)
        bsr     SetVRAMPtr
        moveq   #$0,d0
        subq.l  #4,a0           ; VRAM_DATA
        move.w  #64*5-1,d1
@clr:   move.w  d0,(a0)
        dbra    d1, @clr

        ;; Now display the controls that are active
        lea     button_table(pc), a2
        bsr     ReadJoy1
        move.w  d0, d2
        moveq   #$7, d3
@dlp:   moveq   #0, d4
        move.w  (a2)+, d4
        lsr     #1, d2
        bcc.s   @dnxt
        add.l   a3, d4
        move.l  d4, (sp)
        bsr.s   DrawString
@dnxt:  dbra    d3, @dlp

        ;; Back to main loop
        addq.b  #1, d7
        bra     mainlp

DrawString:
        move.l  4(sp), a0
        move.w  (a0)+, d0
        move.l  a0, -(sp)
        move.w  #0, -(sp)
        move.w  d0, -(sp)
        bsr     WriteStr
        addq.l  #8, sp
        rts

DrawStrings:
        move.l  4(sp), a0
@lp:    move.w  (a0), d0
        beq.s   @done
        move.l  a0, -(sp)
        bsr.s   DrawString
        addq.l  #4, sp
        move.l  d0, a0
        bra.s   @lp
@done:  rts

sinestra:
        include "sinestra.s"

headers:
        align   2
        dc.w    $c000 + 128*2 + 14
        dc.b    "SPRITE AND CONTROLLER TEST",0
        align   2
        dc.w    $c000 + 128*26 + 14
        dc.b    "BUMBERSHOOT SOFTWARE, 2018",0
        align   2
        dc.w    $0000
upstr:  dc.w    $c000 + 128*11 + 22
        dc.b    "UP",0
        align   2
dnstr:  dc.w    $c000 + 128*15 + 20
        dc.b    "DOWN",0
        align   2
lfstr:  dc.w    $c000 + 128*13 + 10
        dc.b    "LEFT",0
        align   2
rtstr:  dc.w    $c000 + 128*13 + 30
        dc.b    "RIGHT",0
        align   2
a_str:  dc.w    $c000 + 128*13 + 48
        dc.b    "A",0
        align   2
b_str:  dc.w    $c000 + 128*13 + 52
        dc.b    "B",0
        align   2
c_str:  dc.w    $c000 + 128*13 + 56
        dc.b    "C",0
        align   2
ststr:  dc.w    $c000 + 128*13 + 60
        dc.b    "START",0
        align   2
button_table:
        dc.w    upstr-upstr,dnstr-upstr,lfstr-upstr,rtstr-upstr
        dc.w    a_str-upstr,b_str-upstr,c_str-upstr,ststr-upstr
