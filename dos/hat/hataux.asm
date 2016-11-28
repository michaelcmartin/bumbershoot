        cpu     286
        bits    16

        segment CODE

        global  CgaStart
        global  CgaEnd
        global  HatSlab
        global  WaitForKey

CgaStart:
        mov     ax, 4
        int     10h
        ret

CgaEnd:
        mov     ax, 3
        int     10h
        ret

HatSlab:
        push    bp
        mov     bp, sp
        mov     ax, [bp+6]
        test    ax, ax
        jl      .done
        cmp     ax, 320
        jae     .done
        mov     bx, [bp+4]
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
.done:  pop     bp
        ret     4

WaitForKey:
        mov     ah, 0x06
        mov     dl, 0xff
        int     21h
        jz      WaitForKey
.wait_for_no_key:
        mov     ah, 0x06
        mov     dl, 0xff
        int     21h
        jnz     .wait_for_no_key
        ret
        