;;; ----------------------------------------------------------------------
;;;   Digital audio on the C64: cycle-counting playback demo
;;;   Bumbershoot Software, 2022
;;;
;;;   This isn't really a great way to manage digital sound on the C64,
;;;   but it's the closest to techniques on other platforms. See the
;;;   file diginmi.s for a more appropriate implementation.
;;; ----------------------------------------------------------------------

        .outfile "digicycle.prg"
        .word   $0801
        .org    $0801
        .word   +,10
        .byte   $9e," 2062",0
*       .word   0

        .data   zp
        .org    $fb
        .space  ptr     2
        .space  count   1

        .text

        lda     #<sfx           ; Initialize sound pointer
        sta     ptr
        lda     #>sfx
        sta     ptr+1
        lda     #$01            ; Start playback immediately
        sta     count
        lda     #$8b            ; Disable graphics (and thus badlines)
        sta     $d011
        jsr     reset_sid       ; Prepare the 8580 digiboost
        lda     #$ff
        sta     $d406
        sta     $d40d
        sta     $d414
        lda     #$49
        sta     $d404
        sta     $d40b
        sta     $d412
        sei                     ; Disable clock interrupt

        ;; Cycle-counted loop for 8kHz playback. 123 cycles (PAL; NTSC
        ;; needs 128). Each byte's lower four bits are the PCM value,
        ;; and the upper four bits are the number of samples in a row
        ;; this value is, for a one-byte RLE scheme. A zero byte ends
        ;; the playback.
loop:   dec     count           ; 5
        bne     next0           ; 7
        ;; Branch: Process new data
        ldy     #$00            ; 9
        lda     (ptr),y         ; 14
        beq     finished        ; 16
        and     #$0f            ; 18
        sta     $d418           ; 22
        lda     (ptr),y         ; 27
        lsr                     ; 29
        lsr                     ; 31
        lsr                     ; 33
        lsr                     ; 35
        sta     count           ; 38
        clc                     ; 40
        lda     ptr             ; 43
        adc     #$01            ; 45
        sta     ptr             ; 48
        lda     ptr+1           ; 51
        adc     #$00            ; 53
        sta     ptr+1           ; 56
        ;; Delay for data-processing case
        ldx     #$0c            ; 58
*       dex
        bne     -               ; 117 (5*12-1)
        cmp     ptr             ; 120
        jmp     loop            ; 123
        ;; Branch: no new data, only delay
next0:  ldx     #$15            ; 10
*       dex
        bne     -               ; 114 (5*23-1)
        nop                     ; 116
        nop                     ; 118
        nop                     ; 120
        jmp     loop            ; 123
finished:
        cli                     ; Restore clock interrupt
        lda     #$9b            ; Restore graphics
        sta     $d011
        ;; Fall through into reset_sid

reset_sid:
        lda     #$00
        ldx     #$19
*       sta     $d3ff,x
        dex
        bne     -
        rts

sfx:
        .incbin "sample.bin"
