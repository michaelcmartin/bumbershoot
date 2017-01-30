;;; PC Speaker 1-bit digital audio
;;;
;;; This routine demonstrates producing crackly but recognizable
;;; sound with the PC speaker by jamming the high bit of PCM data
;;; into the PC speaker state.
;;;
;;; Because of the 60-microsecond transition time of the PC speaker,
;;; very high transfer rates start making this work like multi-bit
;;; ADPCM. This effect is barely present at 16kHz, the speed we use
;;; in this test program.
;;;
;;; Despite the "cpu 8086" marker here, the fact that this code is
;;; firing timing interrupts at 16 kHz does mean that you will
;;; probably want a reasonably fast (12MHz+) machine. DOSBox's default
;;; 3000-cycles speed is fine.
        cpu     8086
        bits    16
        org     100h

counter equ     (0x1234DC / 16000) & 0xFFFE
        segment .bss
biostick: resb  4
dataptr: resb   4

        segment .text

        ;; Record the original BIOS timing routine
        mov     ax, 0x3508
        int     21h
        mov     [biostick], bx
        mov     bx, es
        mov     [biostick+2], bx

        ;; Load the data pointer for use by our sound code
        mov     ax, data
        mov     [dataptr], ax
        mov     ax, ds
        mov     [dataptr+2], ax

        ;; Replace IRQ0 with our sound code
        mov     dx, tick
        mov     ax, 0x2508
        int     21h

        ;; Reprogram PIT Channel 0 to fire IRQ0 at 16kHz
        cli
        mov     al, 0x36
        out     0x43, al
        mov     ax, counter
        out     0x40, al
        mov     al, ah
        out     0x40, al
        sti

        ;; Keep processing interrupts until it says we're done
mainlp: hlt
        mov     ax, [done]
        or      ax, ax
        jz      mainlp

        ;; Restore original IRQ0
        lds     dx, [biostick]
        mov     ax, 0x2508
        int     21h
        ;; And quit with success
        mov     ax, 0x4c00
        int     21h

        ;; *** IRQ0 TICK ROUTINE ***
tick:   push    ds              ; Save flags
        push    ax
        push    bx
        push    si
        lds     bx, [dataptr]   ; Load our data pointers
        mov     si, [offset]
        cmp     si, datasize    ; past the end?
        jae     .nosnd
        mov     ah, [ds:bx+si]  ; If not, load up the value
        rol     ah, 1           ; Move bit 7 to bit 1
        rol     ah, 1
        and     ah, 2           ; And mask out everything else
        in      al, 0x61        ; Or that with the state of port 0x61
        and     al, 0xFC        ; (setting the PC speaker's target
        or      al, ah          ; state to the sample's high bit)
        out     0x61, al
        inc     si              ; Update pointer
        mov     [offset], si
        jmp     .intend         ; ... and jump to end of interrupt
        ;; If we get here, we're past the end of the sound.
.nosnd: mov     ax, [done]      ; Have we already marked it done?
        jnz     .intend         ; If so, nothing left to do
        mov     ax, 1           ; Otherwise, mark it done...
        mov     [done], ax
        mov     al, 0x36        ; ... and slow the timer back down
        out     0x43, al        ; to 18.2 Hz
        xor     al, al
        out     0x40, al
        out     0x40, al
.intend:
        mov     ax, [subtick]   ; Add microsecond count to the counter
        add     ax, counter
        mov     [subtick], ax
        jnc     .nobios         ; If carry, it's time for a BIOS call
        mov     bx, biostick    ; Point DS:BX at our saved address...
        pushf                   ; and PUSHF/CALL FAR to simulate an
        call    far [ds:bx]     ; interrupt
        jmp     .fin
.nobios:
        mov     al, 0x20        ; If not, then acknowledge the IRQ
        out     0x20, al
.fin:
        pop     si              ; Restore stack and get out
        pop     bx
        pop     ax
        pop     ds
        iret

        segment .data
done:   dw      0
offset: dw      0
subtick: dw     0
data:   incbin "wow.raw"        ; Up to 64KB of 16 kHz 8-bit unsigned LPCM
dataend:
datasize equ dataend - data
