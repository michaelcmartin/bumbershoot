;;; Let's play the C-major scale on an the PC speaker!
;;;  freqs = [220 * 2**(c/12.0) for c in range (3, 16)]
;;;  fnums = [1193181 / freq for freq in freqs]

        cpu     8086
        bits    16
        org     100h

        mov     si, scale
notelp: lodsw
        or      ax, ax
        je      done

        call    speakerOn

        mov     bx, 7
        call    waitTicks

        call    speakerOff

        mov     bx, 2
        call    waitTicks
        jmp     notelp

        ;; Quit to DOS
done:   mov     ax, 0x4c00
        int     21h

        ;; Waits for BX ticks of the 18.2 Hz system timer.
waitTicks:
        xor     ax, ax
        int     0x1a
        add     bx, dx
.lp:    xor     ax, ax
        int     0x1a
        cmp     dx, bx
        jne     .lp
        ret

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

speakerOff:
        in      al, 0x61
        and     al, 0xfc
        out     0x61, al
        ret

scale:  dw      4560, 4063, 3619, 3416, 3043, 2711, 2415, 2280, 0
