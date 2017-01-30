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
        push    cx
        push    dx
        xchg    al, ah          ; Register first
        mov     dx, 0x0388
        out     dx, al
        ;; Read status 6 times after address for delay
        mov     cx, 6
.lp1:   in      al, dx
        loop    .lp1

        xchg    al, ah          ; Put data back in AL
        inc     dx
        out     dx, al
        ;; Read status 35 times after data for delay
        mov     cx, 35
.lp2:   in      al, dx
        loop    .lp2
        pop     dx
        pop     cx
        pop     ax
        ret

resetAdlib:
        xor     ax, ax
.lp:    call    writeAdlib
        inc     ah
        or      ah, ah
        jnz     .lp
        ret

scale:  dw      0x3158, 0x3183, 0x31b2, 0x31cc, 0x3204, 0x3244, 0x328b, 0x32b1, 0x0000
