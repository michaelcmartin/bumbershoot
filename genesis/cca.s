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
mirror_ready:
        ds  1
reset_requested:                ; Bit 0 = reset requested (START was pressed)
        ds  1                   ; Bit 1 = reset needs acknowledgement
                                ;         (START needs to be released)
        align 2

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
        bsr     BumbershootTitle
        bsr     srnd
        bsr     InitFakeCGA
        bsr     CCAInit
        bsr     SetupFM

        ;; Now that we've set up the VRAM intially, VRAM shall only be
        ;; touched inside the VBLANK interrupt.
        movea.l #$00c00004, a0
        move.w  #$8164, (a0)    ; Enable VBLANK interrupt
        move.w  #$2500, sr      ; Unmask interrupt level 6

mainlp: bsr     tick_rnd
        bsr     CCAStep
        bsr     CCARender
        bra     mainlp

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
        rte

VBL:    movem.l d0-d2/a0-a1, -(sp)
        bsr     ReadJoy1
        movea.l #$00c00000, a0
        lea     scroll_pos, a1
        move.l  #$81648f02, 4(a0) ; Word write, no DMA
        ;; VSRAM WRITE to $0000 (Vertical scroll table)
        move.l  #$40000010, 4(a0)
        move.w  (a1), d1
        btst    #0, d0
        beq.s   .noup
        subq    #1, d1
.noup:  btst    #1, d0
        beq.s   .nodn
        addq    #1, d1
.nodn:  move.w  d1, (a0)
        move.w  d1, (a0)
        move.w  d1, (a1)
        ;; VRAM WRITE to $AC00 (Horizontal scroll table)
        move.l  #$6c000002, 4(a0)
        addq    #2, a1
        move.w  (a1), d1
        btst    #2, d0
        beq.s   .nolt
        addq    #1, d1
.nolt:  btst    #3, d0
        beq.s   .nort
        subq    #1, d1
.nort:  move.w  d1, (a0)
        move.w  d1, (a0)
        move.w  d1, (a1)
        ;; Process the START button and reset_requested
        move.b  reset_requested, d1
        btst    #7, d0
        bne.s   .start_pressed
        ;; START released. we can start respecting STARTs again.
        bclr    #1, d1
        bra.s   .start_processed
.start_pressed:
        btst    #1, d1          ; Is this the last reset's press?
        bne.s   .start_processed
        bset    #0, d1
.start_processed:
        move.b  d1, reset_requested
        ;; Check if we need to blit a layer
        move.b  mirror_ready, d0
        bne.s   .dma
.done:  movem.l (sp)+, d0-d2/a0-a1
        rte
.dma:   move.l  #$40000083, d1  ; Target DMA for first blit
        move.l  #$9640977f, d2  ; Source RAM for first blit
        subq    #1, d0          ; Is this the first blit?
        bne.s   .first
        move.l  #$60000083, d1  ; If not, adjust target and source
        move.l  #$9650977f, d2  ; addresses as needed
.first: move.b  d0, mirror_ready ; Either way, save new blits-remaining.
        ;; Now enable DMA, load in length and source addresses.
        ;; This assumes 512-byte alignment for each blit source, which we
        ;; do in fact have.
        move.l  #$81749300, 4(a0)
        move.l  #$94109500, 4(a0)
        move.l  d2, 4(a0)
        move.l  d1, 4(a0)
        bra     .done

        include "ccatitle.s"
        include "ccamain.s"
        include "joystick.s"
        include "xorshift.s"
        include "fakecga.s"
        include "simplefm.s"
        include "8k_dac.s"
        include "lz4dec.s"
        include "logo.s"
