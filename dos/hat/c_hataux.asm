        cpu     386
        bits    16

        segment _TEXT class=CODE

        global  _cga_start
        global  _cga_end
        global  _hat_slab
        global  _wait_for_key
        global  _get_msdos_time

_cga_start:
        mov     ax, 4
        int     10h
        ret

_cga_end:
        mov     ax, 3
        int     10h
        ret

_hat_slab:
        push    bp
        mov     bp, sp
        push    es
        push    di
        mov     ax, [bp+4]
        test    ax, ax
        jl      .done
        cmp     ax, 320
        jae     .done
        mov     bx, [bp+6]
        test    bx, bx
        jl      .done
        cmp     bx, 200
        jae     .done
        xor     di, di
        shr     bx, 1
        jnc     .even
        mov     di, 0x2000
        ;; BX is now y div 2. Add (BX << 4) and (BX << 6) and (AX >> 2) to DI to get the mask.
.even:  shl     bx, 4
        add     di, bx
        shl     bx, 2
        add     di, bx
        mov     cx, ax
        shr     ax, 2
        add     di, ax
        ;; DI now has the offset from b800.
        and     cx, 3
        neg     cl
        add     cl, 3
        shl     cl, 1
        ;; CL now holds the number of places we need to shift our pixel mask.
        mov     ax, 0xb800
        mov     es, ax
        ;; ES now points to the screen.
        mov     al, 3
        shl     al, cl
        mov     dx, ax
        or      al, byte [es:di]
        mov     byte [es:di], al
        ;; Now we need to draw a black line straight down from here to the end of the screen.
        xor     dl, 0xff
.blklp: test    di, 0x2000
        jz      .even2
        add     di, 80
.even2: xor     di, 0x2000
        mov     bx, di
        and     bx, 0x1fff
        cmp     bx, 0x1f40
        jae     .done
        mov     al, dl
        and     al, byte [es:di]
        mov     byte [es:di], al
        jmp     .blklp
.done:  pop     di
        pop     es
        pop     bp
        ret

_wait_for_key:
        mov     ah, 0x06
        mov     dl, 0xff
        int     21h
        jz      _wait_for_key
.wait_for_no_key:
        mov     ah, 0x06
        mov     dl, 0xff
        int     21h
        jnz     .wait_for_no_key
        ret

_get_msdos_time:
        mov     ah, 0x2c
        int     21h
        xor     eax, eax
        mov     al, dh
        mov     bl, 100
        mul     bl
        xor     dh, dh
        add     ax, dx
        mov     ebx, eax
        xor     eax, eax
        mov     al, cl
        mov     edx, 6000
        mul     edx
        add     ebx, eax
        xor     eax, eax
        mov     al, ch
        mov     edx, 360000
        mul     edx
        add     ebx, eax
        mov     ax, bx
        shr     ebx, 16
        mov     dx, bx
        ret
        