;;; ----- SOUND BLASTER SUPPORT ROUTINES -----
;;; These routines are intended to be easily lifted up and imported
;;; as bindings into other languages. These are the routines you'd
;;; most likely want to export.
;;;
;;; blast_reset: Initialize the Sound Blaster chip.
;;;   Arguments: AX = base address (probably 0x220)
;;;              BX = IRQ (probably 7, maybe 5)
;;;              DX = DMA channel (probably 1)
;;;     Returns: AX = 0 on failure, nonzero on success
;;;     Trashes: BX, DX
blast_reset:
        push    cx
        ;; Validate address; must be of form 0x02n0 for some n
        mov     cx, ax
        and     cx, 0xFF0F
        cmp     cx, 0x200
        jne     .bad
        ;; Validate IRQ; Must be in the range 2-7
        cmp     bx, 7
        ja      .bad
        cmp     bx, 2
        jb      .bad
        ;; Validate DMA channel; Must be in the range 1-3
        ;; (The Sound Blaster 16 is permitted to use the
        ;;  range from 5-7, but that's a sufficiently
        ;;  alternate code path that I do not wish to
        ;;  bother with it.)
        cmp     dx, 1
        jb      .bad
        cmp     dx, 3
        ja      .bad
        ;; If we made it this far, our config values are
        ;; safe, and we may store them.
        mov     [SOUNDBLASTER_BASE], ax
        add     ax, 6           ; 2x6h
        mov     [SOUNDBLASTER_RESET], ax
        add     ax, 4           ; 2xah
        mov     [SOUNDBLASTER_READ_DATA], ax
        add     ax, 2           ; 2xch
        mov     [SOUNDBLASTER_WRITE_DATA], ax
        add     ax, 2           ; 2xeh
        mov     [SOUNDBLASTER_DATA_AVAILABLE], ax
        mov     [SOUNDBLASTER_IRQ], bx
        mov     [SOUNDBLASTER_DMA], dx
        xor     ax, ax
        mov     [SOUNDBLASTER_SAMPLE_PLAYING], ax
        mov     al, 1
        mov     dx, [SOUNDBLASTER_RESET]
        out     dx, al
        push    dx
        mov     bx, 2
        call    tick_wait
        pop     dx
        xor     al, al
        out     dx, al
        mov     bx, 2
        call    tick_wait
        mov     dx, [SOUNDBLASTER_DATA_AVAILABLE]
        in      al, dx
        test    al, 0x80
        jz      .bad
        mov     dx, [SOUNDBLASTER_READ_DATA]
        in      al, dx
        cmp     al, 0xaa
        je      .ok
.bad:   xor     ax, ax
.ok:    pop     cx
        ret

;;; blast_register: send a byte to the Sound Blaster data port.
;;;      Arguments: AL = byte to send
;;;        Trashes: DX
blast_register:
        push    ax
        mov     dx, [SOUNDBLASTER_WRITE_DATA]
.lp     in      al, dx          ; Wait for data ready
        test    al, 0x80
        jnz     .lp
        pop     ax              ; Then send the byte
        out     dx, al
        ret

;;; blast_rate: configure sample playback rate.
;;;  Arguments: AX = target sample rate (4000-23000)
;;;    Returns: AX = 0 on error, AX nonzero on success
blast_rate:
        push    bx
        push    dx
        cmp     ax, 4000
        jb      .bad
        cmp     ax, 23000
        ja      .bad
        mov     bx, ax
        mov     al, 0x40
        call    blast_register
        mov     dx, 0x0f        ; DX:AX = 1,000,000
        mov     ax, 0x4240
        div     bx
        neg     al
        call    blast_register
        jmp     .ok
.bad:   xor     ax, ax
.ok:    pop     dx
        pop     bx
        ret

;;; blast_sample: configure and initiate DMA to the Sound Blaster
;;;    Arguments: DX:AX = *ABSOLUTE* address of sample
;;;               BL    = Type of sample (0x14 = 8-bit LPCM)
;;;               CX    = size of the sound (0 = 64KB)
;;;      Trashes: AX, BX, CX, DX
;;;      WARNING: The whole transfer must all be part of the same
;;;               DMA page (that is, the top 4 bits of the absolute
;;;               address must never change).
;;;      WARNING: The Sound Blaster will trigger its IRQ when the
;;;               sound has been played. Acknowledging this IRQ is
;;;               the job of the caller.
;;;      WARNING: You must configure sample rate before calling this
;;;               function.
blast_sample:
        push    bx
        push    dx
        mov     bx, ax
        mov     dx, [SOUNDBLASTER_DMA]
        dec     cx
        mov     al, 4
        or      al, dl
        out     0x0a, al
        xor     al, al
        out     0x0c, al
        mov     al, 0x48
        or      al, dl
        out     0x0b, al
        mov     al, bl
        shl     dx, 1
        out     dx, al
        mov     al, bh
        out     dx, al
        pop     ax              ; Was DX as passed in
        push    dx
        shr     dl, 1
        add     dl, 0x7f
        cmp     dl, 0x80        ; DMA Channel 1 is 0x83 instead
        jnz     .notdma1
        mov     dl, 0x83
.notdma1:
        out     0x83, al
        pop     dx              ; Was [SOUNDBLASTER_DMA] * 2
        inc     dx
        mov     al, cl
        out     dx, al
        mov     al, ch
        out     dx, al
        mov     ax, [SOUNDBLASTER_DMA]
        out     0x0a, al
        pop     ax              ; Was BX
        call    blast_register
        mov     al, cl
        call    blast_register
        mov     al, ch
        call    blast_register
        ret

;;; blast_full_sample: play a standalone 8-bit LPCM sample
;;;    Arguments: ES:AX = address of sample
;;;               BX:CX = size of the sound
;;;      Trashes: AX, BX, CX, DX
;;;      WARNING: Assumes DS is sensible (which is to say, that
;;;               this is a .COM file, or else a small/compact
;;;               memory model).
blast_full_sample:
        ;; Abort if a sound is playing
        cmp     word [SOUNDBLASTER_SAMPLE_PLAYING], 0
        jne     .done
        ;; Store the arguments
        mov     [SOUNDBLASTER_SAMPLE_SIZE], cx
        mov     [SOUNDBLASTER_SAMPLE_SIZE+2], bx
        mov     dx, es
        call    absolute_address
        mov     [SOUNDBLASTER_SAMPLE_POINTER], ax
        mov     [SOUNDBLASTER_SAMPLE_POINTER+2], dx
        ;; Stash the original IRQ handler
        push    es
        mov     ax, 0x3508
        add     ax, [SOUNDBLASTER_IRQ]
        int     21h
        mov     [SOUNDBLASTER_ORIGINAL_IRQ], bx
        mov     [SOUNDBLASTER_ORIGINAL_IRQ+2], es
        mov     cx, [SOUNDBLASTER_IRQ]
        mov     bx, 1
.svlp:  shl     bx, 1
        loop    .svlp
        not     bx
        in      al, 0x21
        mov     [SOUNDBLASTER_ORIGINAL_IRQ_MASK], ax
        and     ax, bx
        out     0x21, al
        pop     es

        ;; Set the IRQ handler for this player
        mov     dx, .irqack
        mov     ax, 0x2508
        add     ax, [SOUNDBLASTER_IRQ]
        int     21h

        ;; Compute the size of the first block of sound: either the
        ;; whole sample, or up to the page boundary.
        mov     cx, [SOUNDBLASTER_SAMPLE_POINTER]
        add     cx, [SOUNDBLASTER_SAMPLE_SIZE]
        jc      .getfirst
        cmp     word [SOUNDBLASTER_SAMPLE_SIZE+2], 0
        je      .oneval
.getfirst:
        mov     cx, [SOUNDBLASTER_SAMPLE_POINTER]
        neg     cx
        jmp     .startsound
.oneval:
        mov     cx, [SOUNDBLASTER_SAMPLE_SIZE]
.startsound:
        mov     bl, 0x14
        mov     [SOUNDBLASTER_SAMPLE_PLAYING], bl
        mov     ax, [SOUNDBLASTER_SAMPLE_POINTER]
        mov     dx, [SOUNDBLASTER_SAMPLE_POINTER+2]
        ;; Before we send off the sample, advance the pointers and
        ;; sample size.
        sub     [SOUNDBLASTER_SAMPLE_SIZE], cx
        sbb     word [SOUNDBLASTER_SAMPLE_SIZE+2], 0
        add     [SOUNDBLASTER_SAMPLE_POINTER], cx
        adc     word [SOUNDBLASTER_SAMPLE_POINTER+2], 0
        call    blast_sample
.lp:    hlt
        cmp     word [SOUNDBLASTER_SAMPLE_PLAYING], 0
        jne     .lp
        ;; Restore original IRQ
        mov     ax, [SOUNDBLASTER_ORIGINAL_IRQ_MASK]
        out     0x21, al
        mov     ax, 0x2508
        add     ax, [SOUNDBLASTER_IRQ]
        push    ds
        lds     dx, [SOUNDBLASTER_ORIGINAL_IRQ]
        int     21h
        pop     ds
.done:  ret

.irqack:
        push    dx
        push    cx
        push    bx
        push    ax
        ;; Is this a real interrupt?
        cmp     word [SOUNDBLASTER_SAMPLE_PLAYING], 0
        jz      .idone          ; If not, just ack int and return
        ;; Load address of next sample component
        mov     ax, [SOUNDBLASTER_SAMPLE_POINTER]
        mov     dx, [SOUNDBLASTER_SAMPLE_POINTER+2]
        ;; How much is left to play?
        cmp     word [SOUNDBLASTER_SAMPLE_SIZE+2], 0
        je      .lastpage
        ;; More than 64KB left, so size is "0" and we advance
        ;; pointer and size a page each
        xor     cx, cx
        inc     word [SOUNDBLASTER_SAMPLE_POINTER+2]
        dec     word [SOUNDBLASTER_SAMPLE_SIZE+2]
        jmp     .sized
 .lastpage:
        mov     cx, [SOUNDBLASTER_SAMPLE_SIZE]
        or      cx, cx
        je      .fin            ; If 0 left, we're done!
        ;; Otherwise we'll be done next time
        mov     word [SOUNDBLASTER_SAMPLE_SIZE], 0
.sized: mov     bl, 0x14        ; 8-bit PCM
        call    blast_sample
        jmp     .ack
        ;; Mark the playback complete
.fin:   mov     word [SOUNDBLASTER_SAMPLE_PLAYING], 0
        ;; Acknowledge interrupt to the soundblaster
.ack:   mov     dx, [SOUNDBLASTER_DATA_AVAILABLE]
        in      al, dx
        ;; Acknowledge interrupt to interrupt controller
.idone: mov     al, 0x20
        out     0x20, al
        ;; Restore registers, return from interrupt
        pop     ax
        pop     bx
        pop     cx
        pop     dx
        iret

;;; ----- INTERNAL SUPPORT ROUTINES -----
;;; These routines are required by the Sound Blaster support routines
;;; but probably are not of use to clients of the library as a whole.

        segment .bss
        SOUNDBLASTER_BASE               resb    2
        SOUNDBLASTER_IRQ                resb    2
        SOUNDBLASTER_DMA                resb    2
        SOUNDBLASTER_RESET              resb    2
        SOUNDBLASTER_READ_DATA          resb    2
        SOUNDBLASTER_WRITE_DATA         resb    2
        SOUNDBLASTER_DATA_AVAILABLE     resb    2
        SOUNDBLASTER_SAMPLE_PLAYING     resb    2
        SOUNDBLASTER_ORIGINAL_IRQ       resb    4
        SOUNDBLASTER_ORIGINAL_IRQ_MASK  resb    2
        SOUNDBLASTER_SAMPLE_POINTER     resb    4
        SOUNDBLASTER_SAMPLE_SIZE        resb    4

        segment .text
;;; absolute_address: Compute the absolute address of DX:AX.
;;;        Arguments: DX holds the segment, AX the offset.
;;;          Returns: DX holds the page, AX the page's offset.
absolute_address:
        push    bx
        push    cx
        xor     bx, bx
        mov     cx, 4
.lp:    clc
        rcl     dx, 1
        rcl     bx, 1
        loop    .lp
        ;; CX is 0 now, so that means that
        ;; CX:AX is the offset part of the address and
        ;; BX:DX is the segment as an absolute address (* 16)
        add     ax, dx          ; Do a 32-bit add...
        adc     bx, cx
        mov     dx, bx          ; ... and put the hiword in DX
        pop     cx
        pop     bx
        ret

;;; tick_wait: Wait for the specified number of ticks of the system timer.
;;; Arguments: BX holds the number of ticks to wait.
tick_wait:
        push    ax
        push    bx
        push    cx
        push    dx
        xor     ax, ax
        int     0x1a
        add     bx, dx
.lp:    xor     ax, ax
        int     0x1a
        cmp     dx, bx
        jne     .lp
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
