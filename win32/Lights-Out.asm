        ;; Lights Out! for Windows 32-bit.
        ;; Needs to be linked against kernel32.lib but otherwise requires no runtime.
        ;; Build commands (paths may need to be adjusted on your system):
        ;;     nasm -f win32 Lights-Out.asm
        ;;     link /subsystem:console /nodefaultlib /entry:start Lights-Out.obj "c:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Lib\Kernel32.Lib"

        GLOBAL  _start                  ; Where we start
        ;; Screen Buffer creation and configuration
        EXTERN  _CreateConsoleScreenBuffer@20, _GetConsoleScreenBufferInfo@8
        EXTERN  _SetConsoleScreenBufferSize@8, _SetConsoleWindowInfo@12
        EXTERN  _SetConsoleActiveScreenBuffer@4, _SetConsoleTitleW@4
        ;; Screen Buffer routines
        EXTERN  _FillConsoleOutputCharacterW@20, _FillConsoleOutputAttribute@20
        EXTERN  _GetConsoleCursorInfo@8, _SetConsoleCursorInfo@8
        EXTERN  _SetConsoleCursorPosition@8, _SetConsoleTextAttribute@8
        EXTERN  _ReadConsoleInputW@16, _ReadConsoleOutputAttribute@20
        EXTERN  _WriteConsoleW@20, _WriteConsoleOutputW@20
        ;; Other kernel functions we'll need
        EXTERN  _GetStdHandle@4, _CloseHandle@4, _ExitProcess@4
        EXTERN  _GetTickCount@0

        section .bss
apibuf  resb    64              ; Buffer for use by API calls
hStdIn  resd     1
hStdOut resd     1
hScreen resd     1
cursor  resd     2
frame   resd     1

        section .text
_start: call    init
        call    draw_screen
.game_start:
        call    clear_status
        mov     esi, gen
        call    draw_string
        mov     dword [frame], 10000
        mov     bl, 25
.puzlp: call    rand
        and     ax, 0xfff       ; Make sure quotient fits in AL
        div     bl
        mov     al, ah
        add     al, 'A'
        and     eax, 0xff
        call    make_move
        sub     dword [frame], 1
        jnz     .puzlp

        call    clear_status
        mov     esi, insns
        call    draw_string
        call    draw_string
        call    draw_string
.lp:    call    read_key
        cmp     eax, 27         ; Escape
        je      .finis
        cmp     eax, 0x70       ; F1
        je      .game_start
        cmp     eax, 'A'
        jb      .lp
        cmp     eax, 'Z'
        jae     .lp
        call    make_move
        call    player_wins
        jne     .lp
        ;; Victory!
        call    clear_status
        mov     esi, winmsg
        call    draw_string
        call    draw_string
.again: call    read_key
        cmp     ax, 'Y'
        je      .game_start
        cmp     ax, 'N'
        jne     .again

.finis: call    uninit
        mov     eax, [hStdOut]
        mov     [hScreen], eax
        mov     ecx, byelen
        mov     edx, bye
        call    write_string
        push    dword 0
        call    _ExitProcess@4

init:   push    -11
        call    _GetStdHandle@4
        mov     [hStdOut], eax
        push    -10
        call    _GetStdHandle@4
        mov     [hStdIn], eax
        call    srand
        ;; Create the new screen
        push    dword 0
        push    dword 1           ; CONSOLE_TEXTMODE_BUFFER
        push    dword 0
        push    dword 3           ; SHARE_FILE_READ | SHARE_FILE_WRITE
        push    dword 0xc0000000  ; GENERIC_READ | GENERIC_WRITE
        call    _CreateConsoleScreenBuffer@20
        cmp     eax, -1           ; Did we get back INVALID_HANDLE_VALUE?
        je      .error
        cmp     eax, 0            ; How about NULL?
        je      .error
        mov     [hScreen], eax
        push    apibuf
        push    eax
        call    _GetConsoleScreenBufferInfo@8
        test    eax, eax
        jz      .fail
        ;; We succeeded, so the words at offsets 18 and 20 are the maximum width/height of our window
        ;; Make sure our dimensions can accommodate at least 80x25...
        cmp     word [apibuf+18], 80
        jae     .w_ok
        mov     word [apibuf+18], 80
.w_ok:  cmp     word [apibuf+20], 25
        jae     .h_ok
        mov     word [apibuf+20], 25
.h_ok:  push    dword [apibuf+18]
        push    dword [hScreen]
        call    _SetConsoleScreenBufferSize@8
        test    eax, eax
        jz      .fail
        ;; Now set the window size to 80x25.
        mov     dword [apibuf], 0x00000000
        mov     dword [apibuf+4], 0x0018004f
        push    apibuf
        push    dword 1
        push    dword [hScreen]
        call    _SetConsoleWindowInfo@12
        test    eax, eax
        jz      .fail
        ;; And now shrink the buffer down to 80x25.
        push    0x00190050
        push    dword [hScreen]
        call    _SetConsoleScreenBufferSize@8
        test    eax, eax
        jz      .fail
        push    dword [hScreen]
        call    _SetConsoleActiveScreenBuffer@4
        test    eax, eax
        jz      .fail
        push    head
        call    _SetConsoleTitleW@4
        push    cursor
        push    dword [hScreen]
        call    _GetConsoleCursorInfo@8
        mov     dword [cursor+4], 0
        push    cursor
        push    dword [hScreen]
        call    _SetConsoleCursorInfo@8
        ;; Clear screen to low-intensity white spaces.
        push    apibuf
        push    dword 0
        push    dword 2000
        push    dword 0x20
        push    dword [hScreen]
        call    _FillConsoleOutputCharacterW@20
        push    apibuf
        push    dword 0
        push    dword 2000
        push    dword 0x07
        push    dword [hScreen]
        call    _FillConsoleOutputAttribute@20
        ret

.fail:  push    dword [hScreen]
        call    _CloseHandle@4
.error: mov     ecx, initlen
        mov     edx, initerr
        call    write_string
        push    dword 1
        call    _ExitProcess@4

uninit: mov     dword [cursor+4], 0
        push    cursor
        push    dword [hScreen]
        call    _SetConsoleCursorInfo@8
        mov     eax, 7
        call    set_color
        push    dword [hStdOut]
        call    _SetConsoleActiveScreenBuffer@4
        push    dword [hScreen]
        call    _CloseHandle@4
        ret

        section .data
initerr dw      __utf16__("Could not initialize console!"), 13, 10
initlen equ     ($-initerr)/2
bye:    dw      __utf16__("Thanks for playing!"),13,10
        dw      __utf16__("  -- Michael Martin, 2016"),13,10
byelen  equ     ($-bye)/2
head:   dw      __utf16__("Lights-Out!"),0

        section .text

draw_screen:
        ;; Draw logo
        mov     [apibuf], dword 0x00030023
        mov     [apibuf+4], dword 0x0003004f
        push    apibuf          ; writtenRect
        push    dword 0         ; srcStart
        push    dword 0x1000b   ; srcSize
        push    dword title     ; character Data
        push    dword [hScreen]
        call    _WriteConsoleOutputW@20
        ;; Draw board
        mov     eax, 7
        call    set_color
        mov     ebx, 0x6001e    ; (30, 6)
        mov     esi, board
.lp:    mov     eax, ebx
        call    set_loc
        mov     edx, [esi]
        mov     ecx, 21
        call    write_string
        add     esi, 4
        add     ebx, 0x10000
        cmp     dword [esi], 0
        jne     .lp
        ;; Write the letters
        mov     eax, 0x08
        call    set_color
        mov     eax, 0x00200020
        mov     dword [apibuf], eax
        mov     dword [apibuf+4], eax
        mov     ebx, 'A'
.lp2:   mov     eax, ebx
        call    letter_loc
        sub     eax, 1
        call    set_loc
        mov     byte [apibuf+2], bl
        mov     ecx, 3
        mov     edx, apibuf
        call    write_string
        add     ebx, 1
        cmp     ebx, 'Z'
        jne     .lp2
        ret

        section .data
title:  dw      'L',0x08,'I',0x07,'G',0x0F,'H',0x0F,'T',0x0F,'S',0x0F,' ',0x0F,'O',0x0F,'U',0x0F,'T',0x07,'!',0x08
board:  dd      .top, .let, .mid, .let, .mid, .let, .mid, .let, .mid, .let, .bot, 0
.top:   dw      0x2554, 0x2550, 0x2550, 0x2550, 0x2564, 0x2550, 0x2550, 0x2550, 0x2564, 0x2550, 0x2550, 0x2550, 0x2564, 0x2550, 0x2550, 0x2550, 0x2564, 0x2550, 0x2550, 0x2550, 0x2557
.let:   dw      0x2551, 0x20, 0x20, 0x20, 0x2502, 0x20, 0x20, 0x20, 0x2502, 0x20, 0x20, 0x20, 0x2502, 0x20, 0x20, 0x20, 0x2502, 0x20, 0x20, 0x20, 0x2551
.mid:   dw      0x255F, 0x2500, 0x2500, 0x2500, 0x253C, 0x2500, 0x2500, 0x2500, 0x253C, 0x2500, 0x2500, 0x2500, 0x253C, 0x2500, 0x2500, 0x2500, 0x253C, 0x2500, 0x2500, 0x2500, 0x2562
.bot:   dw      0x255A, 0x2550, 0x2550, 0x2550, 0x2567, 0x2550, 0x2550, 0x2550, 0x2567, 0x2550, 0x2550, 0x2550, 0x2567, 0x2550, 0x2550, 0x2550, 0x2567, 0x2550, 0x2550, 0x2550, 0x255D

        section .text
read_key:
        push    apibuf+60
        push    dword 1
        push    apibuf
        push    dword [hStdIn]
        call    _ReadConsoleInputW@16
        cmp     dword [apibuf+60], 0
        je      read_key
        cmp     word [apibuf], 1                ; Is it a key event?
        jne     read_key
        cmp     dword [apibuf+4], 0             ; Is it a key press?
        je      read_key
        xor     eax, eax
        mov     ax, word [apibuf+10]            ; Read virtual key
        ret

;;; Compute the location for a letter specified in AL.
;;; Output value is in EAX.
letter_loc:
        push    edx
        mov     edx, 0x70020
        and     eax, 0xff
        sub     eax, 'A'
.lp:    cmp     eax, 4
        jbe     .ok
        add     edx, 0x20000
        sub     eax, 5
        jmp     .lp
.ok     shl     eax, 2
        add     eax, edx
        pop     edx
        ret

make_move:
        call    letter_loc
        mov     edi, eax
        sub     edi, 1
        call    try_flip
        sub     edi, 4
        call    try_flip
        add     edi, 8
        call    try_flip
        sub     edi, 0x00020004
        call    try_flip
        add     edi, 0x00040000
        ;; call    try_flip
        ;; ret

try_flip:
        mov     eax, edi
        call    get_color
        cmp     ax, 0x08
        je      .ok
        cmp     ax, 0x4F
        jne     .nope
.ok:    xor     ax, 0x47        ; Swap 0x08 and 0x4f
        push    apibuf
        push    edi
        push    dword 3
        push    eax
        push    dword [hScreen]
        call    _FillConsoleOutputAttribute@20
.nope:  ret

player_wins:
        mov     ebx, 'A'
        xor     esi, esi
.lp:    mov     eax, ebx
        call    letter_loc
        call    get_color
        or      esi, eax
        inc     ebx
        cmp     ebx, 'Z'
        jne     .lp
        cmp     esi, 0x08
        ret

;;; Set console attribute to the value in AX.
set_color:
        and     eax, 0xffff
        push    eax
        push    dword [hScreen]
        call    _SetConsoleTextAttribute@8
        ret

;;; Read console attribute at location EAX (result in AX).
get_color:
        push    apibuf
        push    eax
        push    dword 1
        push    apibuf+4
        push    dword [hScreen]
        call    _ReadConsoleOutputAttribute@20
        mov     eax, dword [apibuf+4]
        and     eax, 0xffff
        ret

;;; Move the cursor to the location EAX (high word Y, low word X)        .
set_loc:
        push    eax
        push    dword [hScreen]
        call    _SetConsoleCursorPosition@8
        ret

;;; Write ECX characters from string at EDX to console.
write_string:
        push    dword 0
        push    apibuf+60
        push    ecx
        push    edx
        push    dword [hScreen]
        call    _WriteConsoleW@20
        ret

clear_status:
        push    apibuf
        push    dword 0x00130000
        push    dword 240
        push    dword 0x20
        push    dword [hScreen]
        call    _FillConsoleOutputCharacterW@20
        ret

;;; Draw a fancy string.
;;; The format for fancy strings is:
;;;     DWORD: Location
;;;     WORD:  Color
;;;     WORD:  Size
;;;     WORD * { Size }: String
;;; IN: ESI is a pointer to the fancy string.
;;; OUT: ESI points just past the end of it.
draw_string:
        mov     eax, [esi]
        call    set_loc
        mov     ax, word [esi+4]
        call    set_color
        mov     cx, word [esi+6]
        and     ecx, 0xffff
        add     esi, 8
        mov     edx, esi
        add     esi, ecx
        add     esi, ecx
        call    write_string
        ret

        section .data
gen:    dd      0x00140018
        dw      0x0a, (.end-.start)/2
.start  dw      __utf16__("Please wait, generating puzzle...")
.end:
insns:  dd      0x0013001e
        dw      0x07, (.e1-.s1)/2
.s1:    dw      __utf16__("Press letters to move")
.e1:    dd      0x0014001d
        dw      0x07, (.e2-.s2)/2
.s2:    dw      __utf16__("Press F1 for new puzzle")
.e2:    dd      0x0015001f
        dw      0x07, (.e3-.s3)/2
.s3:    dw      __utf16__("Press ESCAPE to end")
.e3:
winmsg: dd      0x0013001c
        dw      0x07, (.e1-.s1)/2
.s1:    dw      __utf16__("Congratulations, you win!")
.e1:    dd      0x00150020
        dw      0x07, (.e2-.s2)/2
.s2:    dw      __utf16__("Play again (Y/N)?")
.e2:

;;; Random number support
        section .bss
rndSeed resd    1

        section .text
srand:  call    _GetTickCount@0
        mov     [rndSeed], eax
        ret

rand:   push    edx
        mov     eax, [rndSeed]
        mov     edx, 0x19660d
        mul     edx
        add     eax, 0x3c6ef35f
        mov     [rndSeed], eax
        shr     eax, 8
        and     eax, 0xffff
        pop     edx
        ret
