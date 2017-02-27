;;; ======================================================================
;;;   PROTOMUS Music Driver for the C64
;;;
;;;  This is a very old playroutine that I wrote when I was first
;;;  relearning assembly language and the C64. It works, but if you're
;;;  looking for a playroutine in this day and age you should probably
;;;  not be using this!
;;; ----------------------------------------------------------------------
;;;  A ProtoMus song is made of three voice tracks, one for each of the
;;;  SID's voices. A track is a series of NOTES and COMMAND CODES. Each
;;;  tick, if a note is not playing, a voice will consume all of its
;;;  COMMAND CODES until it reaches a NOTE to play, and then it will
;;;  play that note.
;;;
;;;  The waveform and envelope are set by COMMAND CODES, and so is the
;;;  RELEASE LENGTH. All notes end the RELEASE LENGTH number of ticks
;;;  before their duration expires, to give the Release phase of the
;;;  volume envelope a chance to operate.
;;;
;;;  A NOTE is two bytes long; the first is which note to play (in half-
;;;  step intervals between $00 and $5F, with $30 as Middle C) and the
;;;  second of which is the number of ticks the note lasts. This number
;;;  must be longer than the RELEASE LENGTH.
;;;
;;;  COMMAND CODES are varying lengths and all have the high bit set in
;;;  their first byte:
;;;
;;;    $80 $XX:     Rest for $XX clock ticks.
;;;    $81 $LL $HH: Jump to location $HHLL in track ($0000 is beginning of
;;;                 song). All tracks must end with this command code.
;;;    $82 $WW $SS: Set wave type($WW) and release length ($SS)
;;;    $83 $AD $SR: Set A/D/S/R
;;;    $84 $LL $HH: Set pulse width for square waves
;;; ----------------------------------------------------------------------
;;;  ProtoMus exports the following functions:
;;;
;;;   music_init:  Initializes the frequency tables. Call this before
;;;                any other ProtoMus routine.
;;;   music_reset: Clears the SID.
;;;   song_init:   Put a song descriptor pointer in .AX and this will
;;;                initialize the voice data.  A song descriptor is
;;;                three pointers in a row, one to each voice track.
;;;   music_tick:  Call this routine once every clock tick to play the
;;;                music.
;;;   music_done:  Call this when your music work is done.
;;; ----------------------------------------------------------------------
;;;  ProtoMus uses $fb-$fe for scratch pointer space. You will also need
;;;  to set a sensible origin for the .data segment before including this
;;;  file, as it maintains its internal state within.
;;;
;;;  No persistent data is stored in the $fb-$fd space so callers are
;;;  free to overwrite or reuse the locations once the function is done.
;;;  However, if you call music_tick from an interrupt routine, don't
;;;  forget to back up and restore those values yourself!
;;; ----------------------------------------------------------------------

.scope

;;; Zero Page aliases for pointer indirection
.alias  _src    $fb
.alias  _dest   $fd

.data
;;; Voice data is in the following format:
;;; Byte 0:    SID offset to control registers
;;; Bytes 1-2: Base address of the song track
;;; Bytes 3-4: Current music pointer
;;; Byte 5:    Waveform (low bit off)
;;; Byte 6:    1 = ADS cycle, 0 = R cycle
;;; Byte 7:    Stacatto constant: R cycle begins this many cycles before
;;;            end of note
;;; Byte 8:    Voice timer.  Note goes to R cycle or ends when this hits 0.

.space  _voice_1_data 9
.space  _voice_2_data 9
.space  _voice_3_data 9
.space  _voice_data   9
.space  _this_voice   2

.space  _fq_lo  96
.space  _fq_hi  96
.text
;;; ---------------- music_init --------------------

music_init:
        ;; Init memory
        lda     #$00
        tax
*       sta     _voice_1_data, x
        inx
        cpx     #38
        bne     -
        lda     #$07
        sta     _voice_2_data
        lda     #$0e
        sta     _voice_3_data
        ;; Init SID
        jsr     music_reset
        lda     #$0f
        sta     $d418
        ;; Create the note data: fall through to _create_tables

_create_tables:
        ldx     #11
_init:  lda     _high_ntsc, x
        sta     _fq_hi+84, x
        lda     _low_ntsc, x
        sta     _fq_lo+84, x
        lda     $02a6           ; Nonzero if PAL
        beq     _step
        lda     _high_pal, x
        sta     _fq_hi+84, x
        lda     _low_pal, x
        sta     _fq_lo+84, x
_step:  dex
        bpl     _init

        ;; Now we have the top octave loaded, and can do the rest with division
        ldx     #83
_lp:    lda     _fq_hi+12, x
        lsr
        sta     _fq_hi, x
        lda     _fq_lo+12, x
        ror
        sta     _fq_lo, x
        dex
        bne     _lp
        stx     _fq_hi
        stx     _fq_lo
        rts


;;; ---------------- music_done --------------------

music_done:
        ;; Is actually just music_reset

;;; ---------------- _reset --------------------

music_reset:
        ;; reset SID chip
        ldx     #$19
        lda     #$00
*       sta     $d3ff,x
        dex
        bne     -
        rts

;;; ---------------- song_init --------------------

song_init:
        sta     _src
        stx     _src+1
        ldx     #$07
        lda     #$00
*       sta     _voice_1_data,x
        sta     _voice_2_data,x
        sta     _voice_3_data,x
        dex
        bne     -

        ldy     #$00
        lda     (_src),y
        sta     _voice_1_data+1
        sta     _voice_1_data+3
        iny
        lda     (_src),y
        sta     _voice_1_data+2
        sta     _voice_1_data+4
        iny
        lda     (_src),y
        sta     _voice_2_data+1
        sta     _voice_2_data+3
        iny
        lda     (_src),y
        sta     _voice_2_data+2
        sta     _voice_2_data+4
        iny
        lda     (_src),y
        sta     _voice_3_data+1
        sta     _voice_3_data+3
        iny
        lda     (_src),y
        sta     _voice_3_data+2
        sta     _voice_3_data+4
        lda     #$01
        sta     _voice_1_data+8
        sta     _voice_2_data+8
        sta     _voice_3_data+8
        rts

;; ---------------- music_tick --------------------

music_tick:
        dec     _voice_1_data+8
        bne     +
        lda     #<_voice_1_data
        ldx     #>_voice_1_data
        jsr     _update_voice
*       dec     _voice_2_data+8
        bne     +
        lda     #<_voice_2_data
        ldx     #>_voice_2_data
        jsr     _update_voice
*       dec     _voice_3_data+8
        bne     +
        lda     #<_voice_3_data
        ldx     #>_voice_3_data
        jsr     _update_voice
_tick_done:
*       rts

_update_voice:
        ;; back up voice base
        sta     _this_voice
        stx     _this_voice+1
        ;; Copy data to local copy
        sta     _src
        stx     _src+1
        lda     #<_voice_data
        sta     _dest
        lda     #>_voice_data
        sta     _dest+1
        ldy     #$00
*       lda     (_src),y
        sta     (_dest),y
        iny
        cpy     #$09
        bne     -

        lda     _voice_data+6   ; Voice?
        beq     _true_update_voice

        lda     _voice_data+7   ; Voice stacatto constant
        sta     _voice_data+8
        lda     _voice_data+5   ; Initiate release cycle
        ldx     _voice_data
        sta     $d404,x
        dec     _voice_data+6
        jmp     _update_done

_true_update_voice:
        ldy     #$00
        lda     _voice_data+3
        sta     _src
        lda     _voice_data+4
        sta     _src+1
        lda     (_src),y
        bmi     _special

        ;; Normal note
        tax                     ; Put note in X register
        iny
        ;; Calculate duration, subtracting stacatto constant
        lda     (_src),y
        sec
        sbc     _voice_data+7
        sta     _voice_data+8
        jsr     _set_ptr

        ;; Now that we're done with reading (_src) we can use .Y again.
        ldy     _voice_data
        lda     _fq_lo,x
        sta     $d400, y
        lda     _fq_hi,x
        sta     $d401, y
        lda     _voice_data+5
        ora     #$01
        sta     $d404, y
        inc     _voice_data+6
        jmp     _update_done

_special:
        iny              ; Advance pointer
        and     #$7F     ; clear MSB to get command code; put it in .X
        tax
        bne     _not_rest
        ;; 0x80: Rest for ticks = one-byte arg
        lda     #$00
        sta     _voice_data+6
        lda     (_src),y
        sta     _voice_data+8

        jsr     _set_ptr
        jmp     _update_done
_not_rest:
        dex
        bne     _not_goto
        clc
        lda     (_src),y
        adc     _voice_data+1
        sta     _voice_data+3
        iny
        lda     (_src),y
        adc     _voice_data+2
        sta     _voice_data+4
        jmp     _true_update_voice
_not_goto:
        dex
        bne     _not_ws
        lda     (_src), y
        sta     _voice_data+5
        iny
        lda     (_src), y
        sta     _voice_data+7
        jsr     _set_ptr
        jmp     _true_update_voice
_not_ws:
        dex
        bne     _not_adsr
        ldx     _voice_data
        lda     (_src),y
        sta     $d405,x
        iny
        lda     (_src),y
        sta     $d406,x
        jsr     _set_ptr
        jmp     _true_update_voice
_not_adsr:
        dex
        bne     _not_pw
        ldx     _voice_data
        lda     (_src),y
        sta     $d402,x
        iny
        lda     (_src),y
        sta     $d403,x
        jsr     _set_ptr
        jmp     _true_update_voice
_not_pw:
        ;; Unknown
_update_done:
        ;; Copy data from local copy
        lda     #<_voice_data
        sta     _src
        lda     #>_voice_data
        sta     _src+1
        lda     _this_voice
        sta     _dest
        lda     _this_voice+1
        sta     _dest+1
        ldy     #$00
*       lda     (_src),y
        sta     (_dest),y
        iny
        cpy     #$09
        bne     -
        rts

; updates music pointer (total bytes executed in .Y)
_set_ptr:
        tya
        sec                     ; Extra increment to kick to next note
        adc     _voice_data+3
        sta     _voice_data+3
        lda     #$00
        adc     _voice_data+4
        sta     _voice_data+4
        rts


; ---------------- Note data --------------------
; Only the top octave's frequencies are stored. The remainder are
; computed by music_init through successive division by two.

; Frequencies for 6581 SID chip (NTSC)
_high_ntsc:
.byte   $7e,$86,$8e,$96,$9f,$a8,$b3,$bd,$c8,$d4,$e1,$ee

_low_ntsc:
.byte   $97,$1e,$18,$8b,$7e,$fa,$06,$ac,$f3,$e6,$8f,$f8

; Frequencies for 6581 SID chip (PAL)
_high_pal:
.byte   $83,$8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8

_low_pal:
.byte   $68,$38,$80,$45,$90,$68,$d6,$e3,$98,$00,$24,$10
.scend
