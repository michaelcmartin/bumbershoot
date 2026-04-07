;;; ----------------------------------------------------------------------
;;;   Unframed LZ4 Decoder for Motorola 6809 chip
;;;   (c) Michael C. Martin, 2024. Available under MIT license.
;;;   This code assembles under the asm6809 assembler available at:
;;;     https://www.6809.org.uk/asm6809/
;;; ----------------------------------------------------------------------

;;; LZ4DEC: Decompress buffer.
;;;     U: Source buffer
;;;     Y: Destination buffer
;;; To avoid namespace pollution, all internal labels are anomymized.
;;; Here are symbolic names for them:
;;;     1: COPY. Processes copy/string data.
;;;     2: BKREF. Processes backreferences in compressed data.
;;;     3: Internal loop for BKREF
;;;     4: Function epilog for LZ4DEC
;;;     5: LZRDLEN. Helper function to consume the quasi-unary length
;;;                 data from the compressed stream.
;;;     6: Internal loop for LZRDLEN
;;;     7: Function epilog for LZRDLEN.
LZ4DEC  LDB     ,U+                     ; Load lengths byte
        PSHS    B                       ; Save it for reprocessing
        LSRB                            ; Shift right 4 to get literals
        LSRB                            ;    length nybble
        LSRB
        LSRB
        BEQ     2F                      ; Are there any at all?
        BSR     5F                      ; If so, read that length...
1       LDA     ,U+                     ; ... and copy that many from src
        STA     ,Y+                     ;     to dest
        LEAX    -1,X
        BNE     1B
2       LDD     ,U                      ; Is the backref offset zero?
        BEQ     4F                      ; If so, we're done.
        LDB     ,U+                     ; If not, consume it as little-endian
        LDA     ,U+
        STD     ,--S                    ; And push it on the stack
        LDB     2,S                     ; Reload the lengths byte
        ANDB    #$0F                    ; Isolate the backref length
        BSR     5F                      ; and read the rest of it
        TFR     Y,D                     ; Copy our dest pointer to D
        SUBD    ,S                      ; Subtract backref amount
        STU     ,S                      ; And replace it with orig src ptr
        TFR     D,U                     ; Our new src ptr is the backref ptr
        LEAX    4,X                     ; Add 4 to length to get real length
3       LDA     ,U+                     ; And then do the copy
        STA     ,Y+
        LEAX    -1,X
        BNE     3B
        LDU     ,S++                    ; Restore original source pointer
        LEAS    1,S                     ; Discard lengths byte
        BRA     LZ4DEC                  ; On to next block
4       LEAS    1,S                     ; Discard lengths byte again
        RTS

        ;; Internal helper function. B holds initial 4-bit length, and this
        ;; routine reads any extra length bytes out of U and puts the final
        ;; length in the X register.
        ;; Advances U appropriately. Trashes D.
5       CLRA
        TFR     D,X
        CMPB    #$0f                    ; Multi-byte length?
        BNE     7F
6       LDB     ,U+                     ; Read next length byte
        ABX                             ; Add it to X
        INCB                            ; Was it #$FF?
        BEQ     6B
7       RTS
