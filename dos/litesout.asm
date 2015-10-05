        cpu     8086
        org     0x100
        bits    16

        mov     ax, 0x0003      ; 80-column text
        int     10h
        mov     ax, 0xb800      ; Set up ES
        mov     es, ax
        call    draw_screen
        call    srand
        ;; hide cursor
        mov     ax, 0x0103
        mov     cx, 0x2000
        int     10h
start:  call    clear_status
        mov     si, gen
        call    draw_string

        mov     cx, 10000
        mov     bl, 25
puzlp:  call    rand
        and     ax, 0xfff       ; Make sure quotient fits in AL
        div     bl
        mov     al, ah
        add     al, 'A'
        call    make_move
        loop    puzlp

        call    clear_status
        mov     si, insns
        call    draw_string
        call    draw_string
        call    draw_string

main:   call    read_key
        cmp     ax, 27          ; ESCAPE
        je      end
        cmp     ax, 0x3b00      ; F1
        je      start
        and     ax, 0xffdf      ; force to uppercase
        cmp     ax, 'A'
        jb      main
        cmp     ax, 'Y'
        ja      main
        call    make_move
        call    player_wins
        je      victory
        jmp     main

victory:
        call    clear_status
        mov     si, winmsg
        call    draw_string
        call    draw_string
again:  call    read_key
        and     ax, 0xffdf      ; toupper
        cmp     ax, 'Y'
        je      start
        cmp     ax, 'N'
        jne     again
end:    mov     ax, 0x0003      ; Resetting the gfx
        int     10h             ; also restores the cursor
        mov     dx, bye
        mov     ah, 0x09
        int     21h
        ret

draw_screen:
	mov	si, .logo
	mov	di, 3*160+70
	mov	cx, 11
	rep	movsw
        xor     bp, bp
        mov     di, 6*160+60
        mov     ah, 0x07
.lp:    mov     si, [.board+bp]
        cmp     si, 0
        jz      .done
        mov     cx, 21
.lp2:   lodsb
        stosw
        loop    .lp2
        add     di, 160-21*2
        add     bp, 2
        jmp     .lp
.done:  mov     ax, 0x0841
        mov     cx, 25
.letlp: call    letter_loc
        mov     [es:di], ax
        inc     ax
        loop    .letlp
        ret

.logo	db	'L',0x08,'I',0x07,'G',0x0F,'H',0x0F,'T',0x0F,'S',0x0F,' ',0x0F,'O',0x0F,'U',0x0F,'T',0x07,'!',0x08
.board: dw      .top, .let, .mid, .let, .mid, .let, .mid
        dw      .let, .mid, .let, .bot, 0
.top:   db      0xC9, 0xCD, 0xCD, 0xCD, 0xD1, 0xCD, 0xCD, 0xCD, 0xD1, 0xCD, 0xCD, 0xCD, 0xD1, 0xCD, 0xCD, 0xCD, 0xD1, 0xCD, 0xCD, 0xCD, 0xBB
.let:   db      0xBA, 0x20, 0x20, 0x20, 0xB3, 0x20, 0x20, 0x20, 0xB3, 0x20, 0x20, 0x20, 0xB3, 0x20, 0x20, 0x20, 0xB3, 0x20, 0x20, 0x20, 0xBA
.mid:   db      0xC7, 0xC4, 0xC4, 0xC4, 0xC5, 0xC4, 0xC4, 0xC4, 0xC5, 0xC4, 0xC4, 0xC4, 0xC5, 0xC4, 0xC4, 0xC4, 0xC5, 0xC4, 0xC4, 0xC4, 0xB6
.bot:   db      0xC8, 0xCD, 0xCD, 0xCD, 0xCF, 0xCD, 0xCD, 0xCD, 0xCF, 0xCD, 0xCD, 0xCD, 0xCF, 0xCD, 0xCD, 0xCD, 0xCF, 0xCD, 0xCD, 0xCD, 0xBC

;; IN:  AL contains target letter, A-Y.
;; OUT: DI contains offset for ES.
letter_loc:
        push    ax
        xor     ah, ah
        sub     al, 'A'
        mov     di, 7*160+64
.lp:    cmp     al, 4
        jbe     .ok
        add     di, 320
        sub     al, 5
        jmp     .lp
.ok:    shl     ax, 1
        shl     ax, 1
        shl     ax, 1
        add     di, ax
        pop     ax
        ret

letter_flip:
        push    di
        push    ax
        push    cx
        call    letter_loc
        sub     di, 1
        mov     cx, 3
.lp:    mov     al, [es:di]
        xor     al, 0x47        ; Toggle 0x08 and 0x4F
        mov     [es:di], al
        add     di, 2
        loop    .lp
        pop     cx
        pop     ax
        pop     di
        ret

try_loc:
        mov     al, [es:di]
        cmp     al, 'A'
        jb      .nope
        cmp     al, 'Y'
        ja      .nope
        call    letter_flip
.nope:  ret

make_move:
        call    letter_flip
        call    letter_loc
        sub     di, 8
        call    try_loc
        add     di, 16
        call    try_loc
        sub     di, 328
        call    try_loc
        add     di, 640
        call    try_loc
        ret

        ;; Sets ZF if the player has won.
player_wins:
        mov     ax, 0x0041
        xor     dx, dx
        mov     cx, 25
.lp:    call    letter_loc
        or      dx, [es:di]
        inc     ax
        loop    .lp
        cmp     dh, 0x08
        ret

clear_status:
        mov     ax, 0x0720
        mov     di, 21*160
        mov     cx, 240
        rep     stosw
        ret

;; IN:  SI: points to location word, then attribute byte, then zero-terminated string.
;; OUT: SI: points just past the zero. Line up multiple messages and call draw_string repeatedly.
draw_string:
        lodsw
        mov     di, ax
        lodsb
        mov     ah, al
.lp:    lodsb
        stosw
        cmp     al, 0
        jne     .lp
        ret

gen:    dw      22*160+48
        db      0x0a, "Please wait, generating puzzle...", 0x00
insns:  dw      21*160+60
        db      0x07, "Press letters to move", 0x00
        dw      22*160+58
        db      0x07, "Press F1 for new puzzle", 0x00
        dw      23*160+62
        db      0x07, "Press ESCAPE to end", 0x00
winmsg: dw      21*160+56
        db      0x07, "Congratulations, you win!", 0x00
        dw      23*160+64
        db      0x07, "Play again (Y/N)?", 0x00
bye:    db      "Thanks for playing!",13,10,"  -- Michael Martin, 2015",13,10,'$'

srand:  push    ax
        push    cx
        push    dx
        xor     ax, ax
        int     0x1a
        mov     [rand.seed], dx
        mov     [rand.seed+2], cx
        pop     dx
        pop     cx
        pop     ax
        ret

rand:   push    dx
        mov     ax, [.seed]
        mov     dx, .mult_h
        mul     dx
        push    ax
        mov     ax, [.seed+2]
        mov     dx, .mult_l
        mul     dx
        push    ax
        mov     ax, [.seed]
        mov     dx, .mult_l
        mul     dx
        mov     [.seed], ax
        pop     ax
        add     dx, ax
        pop     ax
        add     dx, ax
        mov     [.seed+2], dx
        add     [.seed], word .inc_l
        adc     [.seed+2], word .inc_h
        mov     al, [.seed+1]
        mov     ah, [.seed+2]
        pop     dx
        ret

.seed:  dd      12345

        .mult_l equ     0x660d
        .mult_h equ     0x0019
        .inc_l  equ     0xf35f
        .inc_h  equ     0x3c6e

;; read_key: waits for a key to be pressed, returns it in AX.
;; OUT: either AH = 00, AL = character   -OR-  AL = 00, AH = extended key code.
;; F1 = 3B00, ESC = 001b
read_key:
        push    dx
.lp:    mov     ah, 06h
        mov     dl, 0xff
        int     21h
        je      .lp
        cmp     al, 00h
        je      .extended
        xor     ah, ah
        pop     dx
        ret
.extended:
        mov     ah, 06h
        mov     dl, 0xff
        int     21h
        mov     ah, al
        xor     al, al
        pop     dx
        ret
