;;; Programming the PC Speaker the normal way
;;;
;;; Plays the C Major scale by setting approprate frequencies on the
;;; Programmable Interrupt Timer's channel 2.
;;;
;;; Target frequencies were computed by selecting from the values
;;; computed by these list comprehensions:
;;;
;;;  freqs = [220 * 2**(c/12.0) for c in range (3, 16)]
;;;  fnums = [int(1193181 / freq) for freq in freqs]
        cpu     8086
        bits    16
        org     100h

        mov     si, scale       ; Initialize pointer
notelp: lodsw                   ; Get next note
        or      ax, ax          ; Is it zero?
        jz      done            ; If so, we're done

        call    speakerOn       ; Play the tone

        mov     bx, 7           ; wait 120 ms or so
        call    waitTicks

        call    speakerOff      ; followed by 35 ms of silence

        mov     bx, 2
        call    waitTicks
        jmp     notelp          ; and loop back

        ;; Quit to DOS
done:   mov     ax, 0x4c00
        int     21h

;;; waitTicks - Waits for BX ticks of the 18.2 Hz system timer.
;;; Trashes AX, BX, and DX.
waitTicks:
        xor     ax, ax          ; Get tick count
        int     0x1a
        add     bx, dx          ; Add BX to it to get target
.lp:    xor     ax, ax          ; ... then spin until it matches
        int     0x1a
        cmp     dx, bx
        jne     .lp
        ret

;;; speakerOn - Turn on the PC speaker at a frequency of
;;;             0x1234DC / AX Hz. Low bit of AX is masked
;;;             out.
;;; Trashes AX.
speakerOn:
        and     ax, 0xfffe
        push    ax
        cli
        mov     al, 0xb6
        out     0x43, al
        pop     ax
        out     0x42, al
        mov     al, ah
        out     0x42, al
        in      al, 0x61
        mov     al, ah
        or      al, 3
        out     0x61, al
        sti
        ret

;;; speakerOff - silences the PC Speaker.
;;; Trashes AX.
speakerOff:
        in      al, 0x61
        and     al, 0xfc
        out     0x61, al
        ret

;;; Note data: The C major scale starting at middle-C.
scale:  dw      4560, 4063, 3619, 3416, 3043, 2711, 2415, 2280, 0
