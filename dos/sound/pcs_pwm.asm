;;; PC Speaker Pulse Width Modulation technique
;;;
;;; This routine demonstrates producing extremely high quality digital
;;; sound with the PC speaker by means of the Pulse Width Modulation
;;; technique.
;;;
;;; Despite the "cpu 8086" marker here, the fact that this code is
;;; firing timing interrupts at 16 kHz does mean that you will
;;; probably want a reasonably fast (12MHz+) machine. DOSBox's default
;;; 3000-cycles speed is fine.
        cpu     8086
        bits    16
        org     100h

counter equ     0x1234DC / 16000
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

        ;; Attach the PC Speaker to PIT Channel 2
        in      al, 0x61
        or      al, 3
        out     0x61, al

        ;; Reprogram PIT Channel 0 to fire IRQ0 at 16kHz
        cli
        mov     al, 0x34
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

        ;; Restore original timer
        cli
        mov     al, 0x34
        out     0x43, al
        xor     al, al
        out     0x40, al
        out     0x40, al
        sti
        ;; Restore original IRQ0
        lds     dx, [biostick]
        mov     ax, 0x2508
        int     21h
        ;; Turn off the PC speaker
        in      al, 0x61
        and     al, 0xfc
        out     0x61, al

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
        shr     ah, 1           ; Make it a 7-bit value
        mov     al, 0xb0        ; And program PIT Channel 2 to
        out     0x43, al        ; deliver a pulse that many
        mov     al, ah          ; microseconds long
        out     0x42, al
        xor     al, al
        out     0x42, al
        inc     si              ; Update pointer
        mov     [offset], si
        jmp     .intend         ; ... and jump to end of interrupt
.nosnd: mov     ax, 1           ; If we were past the end,
        mov     [done], ax      ; mark sound as done and fall through
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
