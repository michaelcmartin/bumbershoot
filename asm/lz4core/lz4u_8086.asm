;;; ----------------------------------------------------------------------
;;;   Unframed LZ4 Decoder for 8086 processor (NASM syntax)
;;;   (c) Michael C. Martin, 2026. Available under MIT License.
;;; ----------------------------------------------------------------------

;;; lz4dec: Decompress a single unframed LZ4 block.
;;;   Compressed data in DS:SI
;;;   Destination buffer in ES:DI
;;;   Both pointers updated to one byte past last byte read/written
;;;   Trashes AX/CX/DX

lz4dec: push    bx
.lp:    lodsb
        mov     bl,al
        mov     cl,4
        shr     al,cl
        and     al,15
        jz      .bkref
        call    .rdlen
        rep     movsb
.bkref: lodsw
        test    ax,ax
        jz      .done
        mov     dx,di
        sub     dx,ax
        mov     al,bl
        and     al,15
        call    .rdlen
        add     cx,4
        xchg    dx,si
        mov     bx,ds
        mov     ax,es
        mov     ds,ax
        rep     movsb
        mov     ds,bx
        mov     si,dx
        jmp     .lp
.done:  pop     bx
        ret

.rdlen: xor     ah,ah
        mov     cx,ax
        cmp     cl,15
        jne     .rlend
.rllp:  lodsb
        add     cx,ax
        inc     al
        jz      .rllp
.rlend: ret
