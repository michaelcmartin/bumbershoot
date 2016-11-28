        cpu     286
        bits    16

        segment CODE

        global  CgaStart
        global  CgaEnd
        global  CgaPixel

CgaStart:
        mov     ax, 4
        int     10h
        retf

CgaEnd:
        mov     ax, 3
        int     10h
        retf

CgaPixel:
        push    bp
        mov     bp, sp
        mov     ax, [bp+10]
        test    ax, ax
        jl      .done
        cmp     ax, 320
        jae     .done
        mov     bx, [bp+8]
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
        xor     al, 0xff
        mov     bl, [bp+6]
        and     bl, 3
        shl     bl, cl
        and     al, byte [es:di]
        or      al, bl
        mov     byte [es:di], al
.done:  pop     bp
        retf    6
