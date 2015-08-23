;;; CGALORES.ASM - Demonstration of the 160x100x16 mode on CGA systems.
;;; by Michael Martin, 2015, for the Bumbershoot Software blog

;;; This code is BSD-licensed; see the repository's general license
;;; for details

;;; This was written for the Netwide Assembler (www.nasm.us)
;;; To assemble, put this and cgalores.dat in the same directory
;;; and issue this command:
;;;     nasm -f bin -o cgalores.com cgalores.asm
;;;
;;; The result will run in DOSBox, but you need to change the line
;;;   machine=svga_s3
;;; to
;;;   machine=cga
;;; or you will get a garbled display. Running it on an actual VGA
;;; system may attempt to drive the screen at 140Hz, and is not
;;; recommended!

        ;; This is a .COM file, so, 16-bit real mode, starts at 100h
        ;; and no header
        cpu     8086
        bits    16
        org     100h

        ;; Main program is pretty self-explanatory
        call    set_cga_lores
        mov     si, screen_data
        call    draw_screen
        call    wait_for_key
        call    set_mode_3      ; Back to normal 80-column mode

        ;; Quit to DOS, error code 0
        mov     ax, 0x4c00
        int     21h

;;; Dumps 8000 bytes of screen data to the low-res screen.
;;;
;;; IN: [DS:SI]=the start of the 8000 bytes
;;; OUT: None. Trashes CX, SI, DI.
draw_screen:
        xor     di, di
        mov     cx, 8000
.lp:    inc     di
        movsb
.end:   loop    .lp
        ret

;;; Utility function to write a register on the CGA's CRT controller
;;; chip. The protocol is that you write the register index to port
;;; 3d4h and then the value to 3d5h.
;;;
;;; IN: AH = register index, AL = register value to write
;;; OUT: None. Trashes AX and DX.
write_cga_reg:
        mov     dx, 0x3d4
        push    ax
        mov     al, ah
        out     dx, al
        inc     dx
        pop     ax
        out     dx, al
        ret

;;; Sets the CGA low-res mode.
;;;
;;; IN: None.
;;; OUT: ES = graphics segment. Trashes AX, CX, DX, SI, DI.
set_cga_lores:
        call    set_mode_3
        mov     dx, 0x3d8       ; Disable video output, set 80col mode
        mov     al, 1
        out     dx, al
        mov     ax, 0x047f      ; Vertical total of 127.
        call    write_cga_reg
        mov     ax, 0x0664      ; Vertical displayed of 100.
        call    write_cga_reg
        mov     ax, 0x0770      ; Vertical sync position of 112 rows
        call    write_cga_reg   ;   (224 visible scanlines)
        mov     ax, 0x0901      ; Maximum scanline of 1 (2/char)
        call    write_cga_reg
        ;; Registers are configured, now set up memory by filling each
        ;; character position with black-on-black character 222
        ;; (background on left 4 pixels, foreground on right 4
        ;; pixels).
        mov     ax, 0xb800
        mov     es, ax
        mov     ax, 0x00de
        mov     cx, 8000
        xor     di, di
        rep     stosw
        ;; Now we re-enable video. BIOS sets it to 0x29, which makes
        ;; the high colorbit be blink. We leave bit 0x20 off, which
        ;; makes blink bit be the intensity bit for the background.
        mov     dx, 0x3d8
        mov     al, 9
        out     dx, al
        ret

;;; Sets 80-column text mode. This also clears the screen and undoes
;;; any horrific violence we did the CGA's registers.
;;;
;;; IN: None.
;;; OUT: None. Trashes AX.
set_mode_3:
        mov     ax, 0x03
        int     10h
        ret

;;; Wait for a key to be pressed. Uses the MS-DOS keyboard-read
;;; routine to do it. The only fun bit here is once we see a key we
;;; loop until we stop seeing keys, so that we don't eat only half of
;;; a special character like F1.
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

;;; Last but not least, our screen data itself. This is 8000 bytes of
;;; color data. Each byte represents two pixels, left to right, top to
;;; bottom. The high nybble is the even-numbered pixel, and the low
;;; nybble is the odd-numbered one. (This means that the image will be
;;; visible if you do a properly formatted text dump.)
screen_data:
        incbin  "cgalores.dat"
