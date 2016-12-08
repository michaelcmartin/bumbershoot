        cpu     8086
        bits    16
        org     100h

counter equ     0x1234DC / 16000
        segment .bss
biostick: resb  4
dataptr: resb   4

        segment .text

        mov     ax, 0x3508
        int     21h
        mov     [biostick], bx
        mov     bx, es
        mov     [biostick+2], bx

        mov     ax, data
        mov     [dataptr], ax
        mov     ax, ds
        mov     [dataptr+2], ax

        mov     dx, tick
        mov     ax, 0x2508
        int     21h

        in      al, 0x61
        or      al, 3
        out     0x61, al

        cli
        mov     al, 0x34
        out     0x43, al
        mov     ax, counter
        out     0x40, al
        mov     al, ah
        out     0x40, al
        sti

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
        ;; Restore original IRQ1
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

tick:   push    ds
        push    ax
        push    bx
        push    si
        lds     bx, [dataptr]
        mov     si, [offset]
        cmp     si, datasize
        jae     .nosnd
        mov     ah, [ds:bx+si]
        shr     ah, 1
        mov     al, 0xb0
        out     0x43, al
        mov     al, ah
        out     0x42, al
        xor     al, al
        out     0x42, al
        inc     si
        mov     [offset], si
        jmp     .intend
.nosnd: mov     ax, 1
        mov     [done], ax
.intend:
        mov     ax, [subtick]
        add     ax, counter
        mov     [subtick], ax
        jnc     .nobios
        mov     bx, biostick
        pushf
        call    far [ds:bx]
        jmp     .fin
.nobios:
        mov     al, 0x20
        out     0x20, al
.fin:
        pop     si
        pop     bx
        pop     ax
        pop     ds
        iret

        segment .data
done:   dw      0
offset: dw      0
subtick: dw     0
data:   incbin "wow.raw"
dataend:
datasize equ dataend - data
