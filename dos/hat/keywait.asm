        cpu     8086
        bits    16

        segment CODE
        global  WaitForKey

WaitForKey:
.wait_for_key:
        mov     ah, 0x06
        mov     dl, 0xff
        int     21h
        jz      .wait_for_key
.wait_for_no_key:
        mov     ah, 0x06
        mov     dl, 0xff
        int     21h
        jnz     .wait_for_no_key
        retf
