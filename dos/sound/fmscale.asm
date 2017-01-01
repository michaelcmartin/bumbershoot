        cpu     8086
        bits    16
        org     100h

        call    resetAdlib
        mov     ax, 0x2001
        call    writeAdlib
        mov     ax, 0x4010
        call    writeAdlib
        mov     ax, 0x60F4
        call    writeAdlib
        mov     ax, 0x8077
        call    writeAdlib
        mov     ax, 0x2301
        call    writeAdlib
        mov     ax, 0x4300
        call    writeAdlib
        mov     ax, 0x63F4
        call    writeAdlib
        mov     ax, 0x8377
        call    writeAdlib

        mov     si, scale
notelp: lodsw
        or      ax, ax
        je      done
        push    ax
        mov     ah, 0xA0
        call    writeAdlib
        pop     ax
        mov     al, ah
        mov     ah, 0xB0
        push    ax
        call    writeAdlib

        mov     bx, 7
        call    waitTicks

        pop     ax
        and     al, 0xDF
        call    writeAdlib

        mov     bx, 2
        call    waitTicks
        jmp     notelp

        ;; Quit to DOS
done:   call    resetAdlib
        mov     ax, 0x4c00
        int     21h

;;; microsleep: busywaits a set number of (almost) microseconds.
;;;  Arguments: BX = number of ticks of the 1.193182 Mhz PIT timer
;;;    Trashes: AX, BX, DX
microsleep:
        pushf
        cli
        mov     al, 0x04
        out     0x43, al
        in      al, 0x40
        mov     dl, al
        in      al, 0x40
        mov     dh, al
.lp:    mov     al, 0x04
        out     0x43, al
        in      al, 0x40
        mov     ah, al
        in      al, 0x40
        xchg    ah, al
        sub     ax, dx
        neg     ax
        cmp     ax, bx
        jb      .lp
        popf
        ret

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

        ;; Write AL into Adlib register AH. This includes delays to ensure
        ;; that timing constraints are respected even if the function is
        ;; called back to back.
writeAdlib:
        push    ax
        mov     al, ah
        mov     dx, 0x0388
        out     dx, al
        mov     bx, 4
        push    dx
        call    microsleep
        pop     dx
        pop     ax
        inc     dx
        out     dx, al
        mov     bx, 21
        call    microsleep
        ret

resetAdlib:
        xor     ax, ax
.lp:    push    ax
        call    writeAdlib
        pop     ax
        inc     ah
        or      ah, ah
        jnz     .lp
        ret

scale:  dw      0x3158, 0x3183, 0x31b2, 0x31cc, 0x3204, 0x3244, 0x328b, 0x32b1, 0x0000
