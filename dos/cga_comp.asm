;;; CGALORES.ASM - Demonstration of the 160x100x16 mode on CGA systems.
;;; by Michael Martin, 2015, for the Bumbershoot Software blog

;;; This code is BSD-licensed; see the repository's general license
;;; for details

;;; This was written for the Netwide Assembler (www.nasm.us)
;;; To assemble, put this and cgalores.dat in the same directory
;;; and issue this command:
;;;     nasm -f bin -o cga_comp.com cga_comp.asm
;;;
;;; The result will run in DOSBox, but you need to change the line
;;;   machine=svga_s3
;;; to
;;;   machine=cga
;;; or you will get a stippled monochrome display instead.

        ;; This is a .COM file, so, 16-bit real mode, starts at 100h
        cpu     8086
        org     100h
        bits    16

        ;; Enter CGA Composite artifact color mode
        mov     ax, 0x0006
        int     10h
        mov     al, 0x1a
        mov     dx, 0x3d8
        out     dx, al

        ;; Create our sample display
        call    draw_bars

        ;; Cycle through the 15 foreground options.
        ;; NOTE: This is CGA-specific; VGA systems will ignore this
        ;; and just make you hit a key 16 times to quit
        mov     cx, 15
loop:   mov     al, cl
        mov     dx, 0x3d9
        out     dx, al
        call    wait_for_key
        loop    loop

        ;; Back to 80-column color text mode
        mov     ax, 3
        int     10h
        ret


draw_bars:
        ;; Draw the even scanlines
        xor     di, di
        call    .halfframe

        ;; Now draw the odd scanlines by altering the base offset and
        ;; falling through
        mov     di, 0x2000

.halfframe:
        cld
        mov     ax, 0xb800
        mov     es, ax
        xor     ax, ax
        add     di, 0x140       ; Skip first 8 scanlines
        mov     dx, 16
.lp:    mov     cx, 240         ; 6 scanlines per bar
        rep     stosw
        add     ax, 0x1111      ; next color
        dec     dx
        jnz     .lp

        ret

wait_for_key:
        mov     ah, 06h
        mov     dl, 0xff
        int     21h
        jz      wait_for_key
.wait_for_no_key:
        mov     ah, 06h
        mov     dl, 0xff
        int     21h
        jnz     .wait_for_no_key
        ret
