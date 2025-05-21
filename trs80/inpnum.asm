        org     $6a00

        jr      start
invalid:
        call    s_print
        defm    "Please enter a positive number, or press BREAK to quit."
        defb    13,62,32,255
        jr      read

start:  call    s_print
        defm    "Enter a number below:"
        defb    13,62,32,255

read:   call    read_num
        jr      c,broken
        jr      z,invalid
        push    hl
        push    hl
        push    bc
        call    s_print
        defm    "Result has "
        defb    255
        ld      a,(index)
        add     '0'
        call    $33a
        call    s_print
        defm    " digits."
        defb    13
        defm    "Result in hex is: "
        defb    255
        pop     bc
        ld      a,c
        call    hexout
        pop     hl
        ld      a,h
        call    hexout
        pop     hl
        ld      a,l
        call    hexout
        ld      a,13
        call    $33a
        ret
broken:
        call    s_print
        defm    "No result; user pressed BREAK."
        defb    13,255
        ret

hexout: push    af
        rra
        rra
        rra
        rra
        call    hexout_4
        pop     af
hexout_4:
        and     15
        ld      c,a
        ld      b,0
        ld      hl,hexits
        add     hl,bc
        ld      a,(hl)
        call    $33a
        ret
hexits: defm    "0123456789ABCDEF"


read_num:
        ld      b,6             ; 6 character buffer
        ld      hl,input_buffer
        call    $05d9           ; KBLINE
        ret     c               ; Was BREAK pressed?

        ld      a,b
        ld      (index),a
        ld      d,h
        ld      e,l
        xor     a
        ld      c,a
        ld      h,a
        ld      l,a
rn_1:   call    CHLx10
        ld      a,(de)
        inc     de
        sub     '0'
        cp      10
        jr      nc,rn_2
        add     a,l
        ld      l,a
        ld      a,0
        adc     a,h
        ld      h,a
        ld      a,0
        adc     a,c
        ld      c,a
        djnz    rn_1
        ld      a,1
        or      a               ; Clear carry and zero bit
        ret
rn_2:   xor     a               ; Clear carry, set zero bit
        ret                     ; Because input was not legal

CHLx10: push    bc
        push    de
        ld      a,c
        ld      d,a
        ld      b,h
        ld      c,l
        add     hl,hl
        rla
        add     hl,hl
        rla
        add     hl,bc
        adc     a,d
        add     hl,hl
        rla
        pop     de
        pop     bc
        ld      c,a
        ret


s_print:
        pop     hl
        ld      a,(hl)
        inc     hl
        push    hl
        cp      $ff
        ret     z
        call    $33a
        jr      s_print

;;; Variables
	map	$
input_buffer # 6
index        # 1
