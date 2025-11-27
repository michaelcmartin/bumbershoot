;;;----------------------------------------------------------------------
;;;  8-Bit Sega BIOS
;;;  Bumbershoot Software, 2025
;;;
;;; Include this file at the top of your program. It will define a
;;; number of useful routines and wire up basic handling for the Pause
;;; and Reset buttons, controller reads, and frame counting. It also
;;; provides symbolic names for all ports.
;;;
;;; Before including this file, define either SG1000 or SMS to select
;;; which console you intend to support. SMS support clears the full
;;; RAM, defines additional ports, and fully configures the standard
;;; mapper and all VDP registers for Mode 4 operation.
;;;
;;; When assembling for the SMS, you may also define RASTERINT to
;;; expand the IRQ handler. This should only be done if you intend
;;; to rely on raster effects through VDP register 11; otherwise
;;; you are spending ROM and RAM space for checks that will never
;;; succeed. Note that mid-screen raster interrupts will still
;;; update the vdp_status register.
;;;
;;; The following restarts and routines are defined:
;;;
;;; RST $08: set_vdp_register. Set VDP register H to L. Trashes A.
;;; RST $10: write_vram. Write byte in A to VRAM location DE.
;;; RST $18: blit_vram: Copy BC bytes from HL (WRAM) to DE (VRAM).
;;;          Trashes ABC, HL points to byte past last byte written.
;;; RST $20: fill_vram: Write BC copies of A to DE. Trashes BC.
;;; RST $28: read_vram: Read value from HL (VRAM) to A.
;;; RST $30: read_vblk: Copy BC bytes from HL (VRAM) to DE (WRAM).
;;;          Trashes ABC, DE points to byte past last byte written.
;;;
;;; prep_vram_read:  Configures the VDP to read from the address in HL.
;;;                  If the display is active, there must be an
;;;                  intervening instruction between the call to this
;;;                  routine and actual IN instruction. Preserves regs.
;;; prep_vram_write: Configures the VDP to write to the address in DE.
;;;                  No special timing requirements. Preserves regs.
;;;
;;; All these routines must be called with IRQ disabled but may safely
;;; be run during active display. The VDP also must not be mid-command.
;;;
;;; The following ports are predefined: PSGPORT, VDPDATA, VDPSTAT,
;;; VDPADDR, IOPORT1, IOPORT2.
;;;
;;; The following global variables are defined:
;;;
;;; irqvec: If nonzero, call this function on each VBLANK interrupt.
;;; rastervec: Defined only when RASTERINT is defined. If nonzero, call
;;;         this function on any interrupt that isn't VBLANK.
;;; frames: 16-bit frame count, updated each VDP interrupt.
;;; joy1:   Latest polled value from controller 1. NOT the same as
;;;         IOPORT1's value; Controller 2 data is masked off and bits are
;;;         active-high.
;;; joy1_pressed: As per joy1, but 1 bits are only set on rising edge.
;;; joy2/joy2_pressed: as above, but for controller 2. Bit positions are
;;;         adjusted to match joy1's values. The RESET button is offered
;;;         on bit $40.
;;; paused: Toggles between 1 and 0 depending on the NMI signal, which is
;;;         assumed to be connected to a pause button.
;;; vdp_status: Cached value of the VDP status register, sampled on VDP
;;;             interrupt.
;;;
;;; The irqvec and rastervec functions are called with the shadow
;;; registers swapped in, but if you use IX or IY. you must preserve and
;;; restore those on the stack yourself or risk them being trashed from
;;; the perspective of the main program.
;;;----------------------------------------------------------------------

ifdef SG1000
elseifdef SMS
	;; SMS-specific control equates
MEMENAB	equ	$3e
DATADIR	equ	$3f
LITGUNV	equ	$7e
LITGUNH	equ	$7f
else
	error "Must define SG1000 or SMS before including SEGA8BIOS.ASM"
endif

	;; Universal control equates
PSGPORT	equ	$7f
VDPDATA	equ	$be
VDPSTAT	equ	$bf
VDPADDR	equ	$bf
IOPORT1	equ	$dc
IOPORT2	equ	$dd

	org	$0000
	map	$c000

irqvec       #  2
frames       #  2
joy1         #  1
joy2         #  1
joy1_pressed #  1
joy2_pressed #  1
paused       #  1
vdp_status   #  1
ifdef RASTERINT
rastervec    #  2
endif

	di
	im	1
ifdef SG1000
	ld	sp,$c400
else
	ld	sp,$dff8
endif
	jr	read_vblk.main

;; Set some restarts for convenient VDP operations. Interrupts should be
;; disabled for all of these, but you do not need to be in VBLANK.
;;
	ds	$08-$,$ff
set_vdp_register:
	ld	a,l
	out	(VDPADDR),a
	ld	a,h
	or	$80
	jr	read_vblk.set_vdp_register_cont
	ds	$10-$,$ff
write_vram:
	call	prep_vram_write
	out	(VDPDATA),a
	ret
	ds	$18-$,$ff
blit_vram:
	call	prep_vram_write
	jp	read_vblk.blit_vram_cont
	ds	$20-$,$ff
fill_vram:
	call	prep_vram_write
	push	de
	ld	d,a
	jp	read_vblk.fill_vram_cont
	ds	$28-$,$ff
read_vram:
	call	prep_vram_read
	nop
	in	a,(VDPDATA)
	ret
	ds	$30-$,$ff
read_vblk:
	call	prep_vram_read
	jp	.read_vblk_cont

	ds	$38-$,$ff
;;; $0038: IRQ handler
	ex	af,af'
	exx
	in	a,(VDPSTAT)		; Read status word
	ld	(vdp_status),a
	jp	.irq_cont

;;; Remaining implementations of restart functions

.set_vdp_register_cont:
	out	(VDPADDR),a
	ret

.blit_vram_cont:
	ld	a,(hl)
	out	(VDPDATA),a
	inc	hl
	dec	bc
	ld	a,b
	or	c
	jr	nz,.blit_vram_cont
	ret

.fill_vram_cont:
	ld	a,d
	out	(VDPDATA),a
	dec	bc
	ld	a,b
	or	c
	jr	nz,.fill_vram_cont
	pop	de
	ret

.read_vblk_cont:
	in	a,(VDPDATA)
	ld	(de),a
	inc	de
	dec	bc
	ld	a,b
	or	c
	jr	nz,.read_vblk_cont
	ret

;;; $0066: NMI handler
	ds	$66-$,$ff
	push	af			; Toggle "Paused" value
	ld	a,(paused)
	xor	$01
	ld	(paused),a
	pop	af
	retn

;;; Remaining implementation of reset handler

.main:	in	a,(VDPSTAT)		; Reset VDP command word
ifdef	SG1000
	ld	hl,$0180		; Disable display
	rst	set_vdp_register
else
	ld	de,.vreginit		; Initialize all VDP registers
	ld	h,0
	ld	b,11
1	ld	a,(de)
	ld	l,a
	rst	set_vdp_register
	inc	h
	inc	de
	djnz	1B
endif
	ld	a,$9f
.psglp:	out	(PSGPORT),a		; Silence PSG
	add	$20
	jr	nc,.psglp
	xor	a			; Clear work RAM
	ld	hl,$c000
	ld	de,$c001
	ld	(hl),a
ifdef SG1000
	ld	bc,$03ff		; 1KB work RAM on SG-1000
	ldir
else
	ld	bc,$1ff7		; 8KB work RAM (-8 bytes)
	ldir
	xor	a			; Reset ROM mapper
	ld	($fffc),a
	ld	($fffd),a
	inc	a
	ld	($fffe),a
	inc	a
	ld	($ffff),a
endif
	xor	a			; Clear VRAM
	ld	d,a
	ld	e,a
	ld	bc,$4000
	rst	fill_vram
ifdef SMS
	xor	a			; Clear CRAM
	ld	de,$8000
	ld	bc,32
	rst	fill_vram
endif
	jp	main

ifdef SMS
	;; Initial values of VDP registers
.vreginit:
	defb	$36,$80,$ff,$ff,$ff,$ff,$fb,$f0,$00,$00,$ff
endif

;;; Remaining implementation of IRQ handler

.irq_cont:
ifdef RASTERINT
	bit	7,a
	jr	nz,.vblnk
	ld	hl,(rastervec)		; Load raster IRQ handler
	ld	a,h			; Is it zero?
	or	l
	call	nz,1F			; If not, call it
	jr	.end			; Either way, done.
endif
.vblnk:	ld	hl,(frames)
	inc	hl
	ld	(frames),hl
	ld	hl,(joy1)		; Move last input to HL
	in	a,(IOPORT2)		; Read new inputs into DE
	xor	$ff			; and switch them to active-high
	ld	d,a
	in	a,(IOPORT1)
	xor	$ff
	ld	e,a
	and	$3f			; Get port 1 input data
	ld	(joy1),a
	ld	b,a			; Compute freshly-pressed buttons
	xor	l
	and	b
	ld	(joy1_pressed),a
	ex	de,hl			; Swap new inputs into HL
	add	hl,hl			; ... and shift left 2 so port 2 is
	add	hl,hl			;     entirely in H
	ld	a,h			; Repeat earlier logic with port 2
	and	$7f
	ld	(joy2),a
	ld	b,a
	xor	d
	and	b
	ld	(joy2_pressed),a
	ld	hl,(irqvec)		; Load main program IRQ handler
	ld	a,h			; Is it zero?
	or	l
	call	nz,1F
.end	exx				; Restore main program registers
	ex	af,af'
	ei				; and return from IRQ
	reti
1	jp	(hl)

;;; Remaining support routines, used by restarts but available to main program

;; Set VRAM write address to DE. Preserves registers.
prep_vram_write:
	push	af
	ld	a,e
	out	(VDPADDR),a
	ld	a,d
	or	$40
	out	(VDPADDR),a
	pop	af
	ret

;; Set VRAM read address to HL. Preserves registers. Consumes 20 cycles after
;; the command: execute at least one more instruction after the call before
;; reading the data port.
prep_vram_read:
	push	af
	ld	a,l
	out	(VDPADDR),a
	ld	a,h
	out	(VDPADDR),a
	pop	af
	ret
