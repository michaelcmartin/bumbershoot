;;; ----------------------------------------------------------------------
;;;   Unframed LZ4 Decoder for 8080 processor
;;;   (c) Michael C. Martin, 2026. Available under MIT License.
;;; ----------------------------------------------------------------------

;;; lz4dec: Decompress a single unframed LZ4 block.
;;;    HL: Pointer to compressed data
;;;    DE: Pointer to destination buffer
;;;    On output, HL and DE point one byte past the final byte read/written
;;;    Trashes ABC
lz4dec: mov     a,m
        inx     h
        push    psw
        rrc
        rrc
        rrc
        rrc
        ani     15
        jz      .bkref
        call    .rdlen
.lp1:   mov     a,m
        stax    d
        inx     h
        inx     d
        dcx     b
        mov     a,c
        ora     b
        jnz     .lp1
.bkref: mov     c,m
        inx     h
        mov     b,m
        inx     h
        mov     a,c
        ora     b
        jz      .done
        pop     psw
        ani     15
        push    h
        push    psw
        mov     h,d
        mov     l,e
        mov     a,l
        sub     c
        mov     l,a
        mov     a,h
        sbb     b
        mov     h,a
        pop     psw
        xthl
        call    .rdlen
        xthl
        inx     b
        inx     b
        inx     b
        inx     b
.lp2:   mov     a,m
        stax    d
        inx     h
        inx     d
        dcx     b
        mov     a,c
        ora     b
        jnz     .lp2
        pop     h
        jmp     lz4dec
.done:  pop     psw
        ret
.rdlen: mvi     b,0
        mov     c,a
        cpi     15
        rnz
.lp:    mov     a,m
        inx     h
        push    psw
        add     c
        jnc     .ok
        inr     b
.ok:    mov     c,a
        pop     psw
        inr     a
        jz      .lp
        ret
