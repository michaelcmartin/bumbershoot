;;; ----------------------------------------------------------------------
;;;   SHA-256 Implementation for the 6502
;;;
;;;   Copyright (c) 2019 Michael C. Martin.
;;;
;;;   Redistribution and use in source and binary forms, with or without
;;;   modification, are permitted provided that the following conditions
;;;   are met:
;;;
;;;   1. Redistributions of source code must retain the above copyright
;;;      notice, this list of conditions and the following disclaimer.
;;;
;;;   2. Redistributions in binary form must reproduce the above
;;;      copyright notice, this list of conditions and the following
;;;      disclaimer in the documentation and/or other materials provided
;;;      with the distribution.
;;;
;;;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;;;   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;;;   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
;;;   FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
;;;   COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
;;;   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
;;;   BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
;;;   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;;;   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;;   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
;;;   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;;   POSSIBILITY OF SUCH DAMAGE.
;;; ----------------------------------------------------------------------
;;;   A few details of this implementation are C64 specific, but the core
;;;   two functions should work on any 6502 chip with sufficient memory
;;;   available. There is no use of self-modifying code and all use of
;;;   the zero page is purely for improving the size and speed of the
;;;   resulting code. The zero page locations chosen and the interface
;;;   therewith are tuned to a C64 system running its normal BASIC and
;;;   KERNAL.
;;;
;;;   Data exposed by the API (all possible platforms):
;;;     - sha256_result:  Holds the hash-in-progress and the final result
;;;                       after all blocks are consumed. 32 bytes.
;;;     - sha256_chunk:   Fill this memory with the block to hash just
;;;                       before the call to sha256_update. It is the
;;;                       responsibility of the caller to properly pad
;;;                       the final block in a stream. 64 bytes.
;;;
;;;   Functions exposed by the API (all possible platforms):
;;;     - sha256_init:    Set sha256_result to the initial hash state.
;;;     - sha256_update:  Update sha256_result based on the block in
;;;                       sha256_chunk.
;;;
;;;   Functions exposed by the API (C64-specific):
;;;     - sha256_prep_zp: Caches BASIC's zero-page memory to free it up
;;;                       for use by these routines. Call it exactly once
;;;                       before touching sha256_chunk or calling
;;;                       sha256_update.
;;;     - sha256_restore_zp: Undoes the actions of sha256_prep_zp. Call
;;;                       after finishing a hash and before returning to
;;;                       BASIC.
;;; ----------------------------------------------------------------------
;;;   Also, in case it is not completely obvious on its face:
;;;
;;;   THIS CODE IS A STUNT. IT IS CORRECT, BUT ENTIRELY IMPRACTICAL.
;;;
;;;   Its execution speed on long messages is approximately 5.6 seconds
;;;   per kilobyte, or 13.5 minutes to check the contents of a full
;;;   C64 floppy disk. As an alternative to using this program, the
;;;   author strongly advises the using a modern and peer-reviewed
;;;   implementation of SHA-2 such as sha256sum on programs and disk
;;;   images directly to validate the contents before imaging, and to
;;;   rely on simpler algorithms such as CRC32 or even simple checksums
;;;   to ensure that an image was properly transferred to period media.
;;; ----------------------------------------------------------------------
        .scope
        .text
        ;; Copy out the entire part of the zero page BASIC relies on
        ;; so that we can have our math storage all use it.
        ;; No arguments. Trashes .A, .Y.
        ;; Call this before loading anything into sha256_chunk.
sha256_prep_zp:
        ldy     #$8e
*       lda     $01, y
        sta     _zp_cache, y
        dey
        bne     -
        rts

        ;; Restore BASIC's zero page memory to the way we found it
        ;; when we called sha256_prep_zp.
        ;; No arguments. Trashes .A, .Y.
sha256_restore_zp:
        ldy     #$8e
*       lda     _zp_cache, y
        sta     $01, y
        dey
        bne     -
        rts

        ;; Begin a new SHA-256 hash. It is safe to call this even when
        ;; the zero page has not been prepped.
        ;; No arguments. Trashes .A, .Y.
sha256_init:
        ldy     #$1f
*       lda     _hash_initial, y
        sta     sha256_result, y
        dey
        bpl     -
        rts

        ;; Consume the 512-bit block in sha256_chunk and update the
        ;; hash in sha256_result accordingly. It is the responsibility
        ;; of the caller to ensure that the final block is properly
        ;; padded.
        ;; Argument is the 64 bytes in sha256_chunk. Trashes all
        ;; registers.
sha256_update:
        ;; Initialize workspace
        ldy     #$1f
*       lda     sha256_result,y
        sta     _workspace+_a,y
        dey
        bpl     -
        lda     #$00
_round: sta     _lp
        cmp     #$40
        bcs     _extend
        jmp     _extended
_extend:
        sec
        sbc     #$3c
        and     #$3f
        tax
        jsr     _ld_acc1_ws
        ldy     #$07
        jsr     _ror_acc1
        jsr     _ld_acc2_acc1
        jsr     _ror_acc1_8
        ldy     #$03
        jsr     _ror_acc1
        jsr     _xor_acc2_acc1
        jsr     _ld_acc1_ws
        ldy     #$03
        jsr     _lsr_acc1
        jsr     _xor_acc2_acc1
        lda     _lp
        and     #$3f
        tax
        jsr     _add_ws_acc2
        txa
        sec
        sbc     #$08
        and     #$3f
        tax
        jsr     _ld_acc1_ws
        jsr     _ror_acc1_8
        jsr     _ror_acc1_8
        ldy     #$01
        jsr     _ror_acc1
        jsr     _ld_acc2_acc1
        ldy     #$02
        jsr     _ror_acc1
        jsr     _xor_acc2_acc1
        jsr     _ld_acc1_ws
        jsr     _ror_acc1_8
        lda     #$00
        sta     _acc1
        ldy     #$02
        jsr     _lsr_acc1
        jsr     _xor_acc2_acc1
        lda     _lp
        sec
        sbc     #$1c
        and     #$3f
        tax
        jsr     _ld_acc1_ws
        jsr     _add_acc2_acc1
        lda     _lp
        and     #$3f
        tax
        jsr     _add_ws_acc2
_extended:
        ldx     #_e
        jsr     _ld_acc1_ws
        ldy     #$06
        jsr     _ror_acc1
        jsr     _ld_acc2_acc1
        ldy     #$05
        jsr     _ror_acc1
        jsr     _xor_acc2_acc1
        jsr     _ror_acc1_8
        ldy     #$06
        jsr     _ror_acc1
        jsr     _xor_acc2_acc1
        ldx     #_h
        jsr     _add_ws_acc2
        ldx     #_e
        jsr     _ld_acc1_ws
        ldx     #_f
        jsr     _and_acc1_ws
        jsr     _ld_acc2_acc1
        ldy     #$03
*       lda     _workspace+_e, y
        eor     #$ff
        sta     _acc1, y
        dey
        bpl     -
        ldx     #_g
        jsr     _and_acc1_ws
        jsr     _xor_acc2_acc1
        ldx     _lp                     ; Round index * 4
        clc
        lda     _round_constants+3,x
        adc     _acc2+3
        sta     _acc2+3
        lda     _round_constants+2,x
        adc     _acc2+2
        sta     _acc2+2
        lda     _round_constants+1,x
        adc     _acc2+1
        sta     _acc2+1
        lda     _round_constants,x
        adc     _acc2
        sta     _acc2
        txa
        and     #$3f
        tax
        jsr     _ld_acc1_ws
        jsr     _add_acc2_acc1
        ldx     #_h
        jsr     _add_ws_acc2
        ldy     #$03
        clc
*       lda     _workspace+_h, y
        adc     _workspace+_d, y
        sta     _workspace+_d, y
        dey
        bpl     -
        ldx     #_a
        jsr     _ld_acc1_ws
        ldy     #$02
        jsr     _ror_acc1
        jsr     _ld_acc2_acc1
        jsr     _ror_acc1_8
        ldy     #$03
        jsr     _ror_acc1
        jsr     _xor_acc2_acc1
        jsr     _ror_acc1_8
        ldy     #$01
        jsr     _ror_acc1
        jsr     _xor_acc2_acc1
        ldx     #_h
        jsr     _add_ws_acc2
        ldx     #_b
        jsr     _ld_acc1_ws
        ldx     #_a
        jsr     _and_acc1_ws
        jsr     _ld_acc2_acc1
        jsr     _ld_acc1_ws
        ldx     #_c
        jsr     _and_acc1_ws
        jsr     _xor_acc2_acc1
        jsr     _ld_acc1_ws
        ldx     #_b
        jsr     _and_acc1_ws
        jsr     _xor_acc2_acc1
        ldx     #_h
        jsr     _ld_acc1_ws
        jsr     _add_acc2_acc1
        ; ACC2 is now the post-shift value for a. Do shift and save
        ; it out.
        ldy     #$1b
*       lda     _workspace+_a, y
        sta     _workspace+_a+4, y
        dey
        bpl     -
        ldx     #_a
        jsr     _ld_ws_acc2
        lda     _lp
        clc
        adc     #$04
        beq     _done
        jmp     _round
_done:  ldy     #$1c
*       clc
        lda     sha256_result+3, y
        adc     _workspace+_a+3, y
        sta     sha256_result+3, y
        lda     sha256_result+2, y
        adc     _workspace+_a+2, y
        sta     sha256_result+2,y
        lda     sha256_result+1, y
        adc     _workspace+_a+1, y
        sta     sha256_result+1, y
        lda     sha256_result, y
        adc     _workspace+_a, y
        sta     sha256_result, y
        dey
        dey
        dey
        dey
        bpl     -
        rts

        ;; 32-bit big-endian arithmetic operations for use by
        ;; sha256_update. Most of these operate on the two 32-bit
        ;; accumulator locations, ACC1 and ACC2. The remaining
        ;; information, which includes both the message block
        ;; "w" and the eight working cells "a" through "h" are
        ;; stored within a 96-byte area called the workspace.
        ;; All of these functions trash .A and .Y, and all routines
        ;; that access or modify the workspace take the index
        ;; of the workspace variable in .X.
        ;;
        ;; Function names are all of the form OP_DEST_SRC. If
        ;; no source is named, the source is the value in .Y.

        ;; Load ACC1 from workspace offset .X
_ld_acc1_ws:
        lda     _workspace, x
        sta     _acc1
        lda     _workspace+1, x
        sta     _acc1+1
        lda     _workspace+2, x
        sta     _acc1+2
        lda     _workspace+3, x
        sta     _acc1+3
        rts

        ;; Add ACC2 to workspace offset .X
_add_ws_acc2:
        clc
        lda     _acc2+3
        adc     _workspace+3, x
        sta     _workspace+3, x
        lda     _acc2+2
        adc     _workspace+2, x
        sta     _workspace+2, x
        lda     _acc2+1
        adc     _workspace+1, x
        sta     _workspace+1, x
        lda     _acc2
        adc     _workspace, x
        sta     _workspace, x
        rts

        ;; Load workspace offset .X from ACC2
_ld_ws_acc2:
        lda     _acc2
        sta     _workspace, x
        lda     _acc2+1
        sta     _workspace+1, x
        lda     _acc2+2
        sta     _workspace+2, x
        lda     _acc2+3
        sta     _workspace+3, x
        rts

        ;; Load ACC2 from ACC1
_ld_acc2_acc1:
        ldy     #$03
*       lda     _acc1,y
        sta     _acc2,y
        dey
        bpl     -
        rts

        ;; XOR ACC1 into ACC2
_xor_acc2_acc1:
        ldy     #$03
*       lda     _acc1,y
        eor     _acc2,y
        sta     _acc2,y
        dey
        bpl     -
        rts

        ;; AND workspace offset .X into ACC1
_and_acc1_ws:
        lda     _workspace,x
        and     _acc1
        sta     _acc1
        lda     _workspace+1,x
        and     _acc1+1
        sta     _acc1+1
        lda     _workspace+2,x
        and     _acc1+2
        sta     _acc1+2
        lda     _workspace+3,x
        and     _acc1+3
        sta     _acc1+3
        rts

        ;; ADD ACC1 into ACC2
_add_acc2_acc1:
        ldy     #$03
        clc
*       lda     _acc1,y
        adc     _acc2,y
        sta     _acc2,y
        dey
        bpl     -
        rts

        ;; Shift ACC1 right .Y places
_lsr_acc1:
        lsr     _acc1
        ror     _acc1+1
        ror     _acc1+2
        ror     _acc1+3
        dey
        bne     _lsr_acc1
        rts

        ;; Rotate ACC1 right .Y places
_ror_acc1:
        lda     _acc1
        lsr
        ror     _acc1+1
        ror     _acc1+2
        ror     _acc1+3
        ror     _acc1
        dey
        bne     _ror_acc1
        rts

        ;; Rotate ACC1 right 8 places
_ror_acc1_8:
        ldy     _acc1+3
        lda     _acc1+2
        sta     _acc1+3
        lda     _acc1+1
        sta     _acc1+2
        lda     _acc1
        sta     _acc1+1
        sty     _acc1
        rts

        ;; Initial hash value: first 32 bits of the fractional parts
        ;; of the square roots of the first 8 primes
_hash_initial:
        .dwordbe        $6a09e667, $bb67ae85, $3c6ef372, $a54ff53a
        .dwordbe        $510e527f, $9b05688c, $1f83d9ab, $5be0cd19

        ;; Round constants: first 32 bits of the fraction parts of
        ;; the cube roots of the first 64 primes
_round_constants:
        .dwordbe        $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5
        .dwordbe        $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5
        .dwordbe        $d807aa98, $12835b01, $243185be, $550c7dc3
        .dwordbe        $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174
        .dwordbe        $e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc
        .dwordbe        $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da
        .dwordbe        $983e5152, $a831c66d, $b00327c8, $bf597fc7
        .dwordbe        $c6e00bf3, $d5a79147, $06ca6351, $14292967
        .dwordbe        $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13
        .dwordbe        $650a7354, $766a0abb, $81c2c92e, $92722c85
        .dwordbe        $a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3
        .dwordbe        $d192e819, $d6990624, $f40e3585, $106aa070
        .dwordbe        $19a4c116, $1e376c08, $2748774c, $34b0bcb5
        .dwordbe        $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3
        .dwordbe        $748f82ee, $78a5636f, $84c87814, $8cc70208
        .dwordbe        $90befffa, $a4506ceb, $bef9a3f7, $c67178f2

        .data
        .space  sha256_result    32
        .space  _zp_cache       $8e

        .data zp
sha256_chunk:
        .space  _workspace       96
        .space  _acc1             4
        .space  _acc2             4
        .space  _lp               1
        ;; Aliases for the offsets for reaching the workspace variables
        .alias  _a               64
        .alias  _b               68
        .alias  _c               72
        .alias  _d               76
        .alias  _e               80
        .alias  _f               84
        .alias  _g               88
        .alias  _h               92
.scend
