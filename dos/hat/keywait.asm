        cpu     8086
        bits    16

        segment CODE
        global  WaitForKey

        ;; This routine simply checks for a key to be pressed and
        ;; released, throwing out the result. Including this lets us
        ;; break our reliance on the Crt and Dos modules.
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
