        .outfile "diginmi.prg"
        .word   $0801
        .org    $0801
        .word   +,10
        .byte   $9e," 2062",0
*       .word   0

        .data   zp
        .org    $fb
        .space  ptr     2
        .space  count   1
        .space  nmidone 1

        .data
        .org    $c000
        .space  gfx_disable 1
        .space  gfx_sprites 1

        .alias  chrout  $ffd2
        .alias  getin   $ffe4
        .alias  plot    $fff0
        .alias  strout  $ab1e

        .text
        jmp     main

        .scope
nmi:    cmp     $dd0d           ; Clear interrupt right away
        dec     count           ; Quit immediately if it's not time
        bne     _done
        pha                     ; Only then save registers
        tya
        pha
        ldy     #$00            ; Fetch sample byte
        lda     (ptr),y
        beq     _endnmi         ; End playback at sound end
        and     #$0f            ; Send sample nybble to volume control
        sta     $d418
        lda     (ptr),y         ; Reload sample byte
        inc     ptr             ; Bump sample pointer without touching
        bne     +               ; the value in the accumulator. This
        inc     ptr+1           ; Lets us make sure that the pointer is
*       lsr                     ; valid before letting a re-entrant
        lsr                     ; update potentially decrease the count to
        lsr                     ; zero once again.
        lsr
        sta     count           ; Store the count nybble
_pop:   pla                     ; Restore registers
        tay
        pla
_done:  rti                     ; Back to system
        ;; Sample is done, halt timer interrupts and flag completion
_endnmi:
        lda     #$1f            ; Disable all CIA2 interrupts
        sta     $dd0d
        lda     #$00            ; Turn off timer A
        sta     $dd0e
        lda     $dd0d           ; Swallow any pending interrupts
        lda     #$47            ; Restore original NMI handler
        sta     $0318
        lda     #$fe
        sta     $0319
        lda     #$01            ; Mark playback as finished
        sta     nmidone
        bne     _pop
        .scend

        .scope
get_model:
        ;; Wait for top of frame
*       bit     $d011
        bmi     -
        ;; Trap at scanline 256
        sei
*       bit     $d011
        bpl     -
        ;; Wait for scanline 261 (last of old NTSC)
        lda     #<261
*       cmp     $d012
        bne     -
        ;; Wait 200 cycles to wait out any NTSC frames
        ldx     #$27
*       dex
        bne     -
        ;; If we're back at top, we're NTSC
        bit     $d011
        bmi     +
        ldx     #$01            ; 1 extra cycle/line
        bne     _done
        ;; Otherwise we are PAL
*       ldx     #$00            ; 0 extra cycles/line
_done:
        cli
        rts
        .scend

;;; We have spent just under 127 bytes total at this point. This is
;;; a good place to stash our sprite data, as a result; it guarantees
;;; all our cycle-critical code has stayed constrained to page 8, and
;;; it doesn't consume too much padding if the rest of the program
;;; grows or shrinks.

        .advance $0880

sprite: .byte   $00,$00,$00,$00,$00,$00,$00,$06,$00,$00,$7e,$00,$03,$fe,$00,$0f
        .byte   $86,$00,$0c,$7e,$00,$0f,$fe,$38,$0f,$86,$3c,$0c,$3e,$3e,$0c,$7e
        .byte   $37,$7c,$7e,$33,$fc,$3c,$33,$fc,$00,$36,$78,$00,$34,$00,$00,$f0
        .byte   $00,$01,$f0,$00,$01,$f0,$00,$00,$e0,$00,$00,$00,$00,$00,$00,$00

play_sound:
        sta     ptr             ; Initialize sound pointer
        sty     ptr+1
        lda     #$01            ; Start playback immediately
        sta     count
        lda     #$00            ; We are not done
        sta     nmidone
        jsr     reset_sid       ; Prepare the 8580 digiboost
        lda     #$ff
        sta     $d406
        sta     $d40d
        sta     $d414
        lda     #$49
        sta     $d404
        sta     $d40b
        sta     $d412
        lda     gfx_disable     ; Do we need to disable the graphics?
        beq     +
        lda     #$8b            ; If so, disable them
        sta     $d011
*       lda     #$1f            ; Disable any original NMI interrupts
        sta     $dd0d
        lda     #$00            ; Stop timer A
        sta     $dd0e
        lda     $dd0d           ; Swallow any leftover interrupts
        lda     #<nmi           ; Redirect NMI handler
        sta     $0318
        lda     #>nmi
        sta     $0319
        lda     #$81            ; Enable Timer A NMI
        sta     $dd0d
        lda     #123            ; Configure timer (123 = PAL)
        sta     $dd04
        lda     #$00
        sta     $dd05
        lda     #$01            ; start timer A
        sta     $dd0e
*       lda     nmidone         ; Wait until the playback is done
        beq     -               ; (it will deconfigure itself)
        lda     #$9b            ; Re-enable graphics
        sta     $d011
        ;; Fall through to reset_sid
reset_sid:
        lda     #$00
        ldx     #$19
*       sta     $d3ff,x
        dex
        bne     -
        rts

main:   lda     #$0e            ; Blue background, light blue border
        sta     $d020
        lda     #$06
        sta     $d021
        lda     #<menu_text     ; Display main menu text
        ldy     #>menu_text
        jsr     strout
        ;; Initialize menu options
        ldx     #$00
        stx     gfx_disable
        inx
        stx     gfx_sprites
        jsr     update_menu
        ;; Initialize sprites
        ldx     #$00
        ldy     #$00
        lda     #$20
*       sta     $d000,y
        iny
        pha
        ; lda   #$3c
        lda     #$d8
        sta     $d000,y
        iny
        lda     sprite_colors,x
        sta     $d027,x
        lda     #sprite/64
        sta     $7f8,x
        pla
        clc
        adc     #$28
        inx
        cpx     #$08
        bne     -
        lda     #$c0
        sta     $d010
        lda     #$00
        sta     $d017
        sta     $d01c
        sta     $d01d
        lda     #$ff
        sta     $d015
        ;; TODO: Set up 16-sprite IRQ
loop:   jsr     getin
        cmp     #'1
        bne     not1
        lda     #<wow_sfx
        ldy     #>wow_sfx
        jsr     play_sound
        jmp     loop
not1:   cmp     #'2
        bne     not2
        lda     #<bumbershoot_sfx
        ldy     #>bumbershoot_sfx
        jsr     play_sound
        jmp     loop
not2:   cmp     #'3
        bne     not3
        lda     gfx_disable
        eor     #$01
        sta     gfx_disable
        jsr     update_menu
        jmp     loop
not3:   cmp     #'4
        bne     not4
        lda     gfx_sprites
        eor     #$01
        sta     gfx_sprites
        jsr     update_menu
        ;; TODO: Update interrupts/sprite enable
        jmp     loop
not4:   cmp     #'5
        bne     loop
        ;; If five is selected, we quit the program.
        lda     #$00
        sta     $d015           ; Disable sprites
        ;; TODO: Disable spritey interrupts
        lda     #$93            ; Clear screen
        jmp     chrout          ; and then quit

        .scope
update_menu:
        ldy     #$1e
        ldx     #$0c
        clc
        jsr     plot
        lda     gfx_disable
        jsr     _boolout
        ldy     #$1e
        ldx     #$0d
        clc
        jsr     plot
        lda     gfx_sprites
        ;; Fall through into _boolout
_boolout:
        beq     _no
        lda     #<on_text
        ldy     #>on_text
        bne     _go
_no:    lda     #<off_text
        ldy     #>off_text
_go:    jmp     strout
        .scend

menu_text:
        .byte   147,13,13,13,13,13,13
        .byte   "         ",5,18,169," C64 PCM SOUND DEMO ",127,146
        .byte   154,13,13,13,"     1. WOW! DIGITAL SOUND!",13
        .byte   "     2. BUMBERSHOOT SONG",13,13
        .byte   "     3. TOGGLE VIC-II DISABLE ",13
        .byte   "     4. TOGGLE VIC-II SPRITES ",13,13
        .byte   "     5. QUIT",13,13,13
        .byte   "       ",5,127,18," PRESS NUMBER TO SELECT ",146,169,154,0

off_text:
        .byte   152,"<OFF>",154,0
on_text:
        .byte   5,"<ON >",154,0

sprite_colors:
        .byte   0,1,2,3,4,5,7,8,9,10,11,12,13,14,15,0,1,2,3,4,5,7

wow_sfx:
        .incbin "wow_rle.bin"

bumbershoot_sfx:
        .incbin "bumbershoot_rle.bin"
        ; .byte 0
