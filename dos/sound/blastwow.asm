        cpu     8086
        bits    16
        org     100h

        segment .text

        ;; TODO: Parse Address, IRQ, DMA channel from BLASTER
        mov     dx, msg1
        mov     ah, 9h
        int     21h
        mov     ax, cs
        call    printhex
        mov     ah, 2
        mov     dl, ':'
        int     21h
        mov     ax, data
        call    printhex
        mov     ah, 9h
        mov     dx, msg2
        int     21h
        mov     ax, datasize
        call    printhex
        mov     ah, 9h
        mov     dx, msg3
        int     21h
        mov     ax, cs
        shl     ax, 1
        shl     ax, 1
        shl     ax, 1
        shl     ax, 1
        add     ax, data
        add     ax, datasize
        jc      twopage
        mov     ah, 9h
        mov     dx, onepagemsg
        int     21h
        mov     ax, datasize
        jmp     done
twopage mov     bx, datasize
        sub     bx, ax
        mov     ah, 9h
        mov     dx, twopagemsg1
        int     21h
        mov     ax, bx
        call    printhex
        mov     ah, 9h
        mov     dx, msg3
        int     21h
done:   mov     ax, 0x220       ; Address 220
        mov     bx, 7           ; IRQ 7
        mov     dx, 1           ; DMA 1
        call    blast_reset
        or      ax, ax
        jnz     ok
        mov     ah, 9
        mov     dx, sb_err
        int     21h
        pop     ax
        jmp     finish
ok:     mov     ax, 16000
        call    blast_rate
        mov     al, 0xd1        ; Speaker on
        call    blast_register
        push    cs
        pop     es
        mov     ax, data
        xor     bx, bx
        mov     cx, datasize
        call    blast_full_sample
finish: mov     ax, 0x4c00
        int     21h

data:   incbin "wow.raw"
dataend:
datasize equ dataend-data

msg1:   db      "16kHz audio data at $"
msg2:   db      '.',13,10,"Audio size is 0x$"
msg3:   db      '.',13,10,'$'
onepagemsg: db  "Audio data fits on one page.",13,10,'$'
twopagemsg1: db "Audio data spans two pages. First DMA size is 0x$"
sb_err: db      "Could not detect Sound Blaster.",13,10,'$'
sb_ok:  db      "Sound Blaster detected OK!",13,10,'$'

printhex:
        mov     bx, ax
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        call    hexit
        mov     bx, ax
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        call    hexit
printhex_8:
        mov     bx, ax
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        shr     bx, 1
        call    hexit
        mov     bx, ax
        ; Fall through to hexit
hexit:  push    ax
        mov     ah, 2
        and     bx, 0x0f
        mov     dl, byte [.xits + bx]
        int     21h
        pop     ax
        ret
.xits:  db      "0123456789ABCDEF"

%include "blaster.asm"
