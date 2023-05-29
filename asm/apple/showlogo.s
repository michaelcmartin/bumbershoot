            MX      %00
            REL
            LNK     SHOW.LOGO.L
            EXT     SFX,SFXLEN,GFXDATA

START       LDA     #$00         ; Clear Super Hi-Res Screen
            STAL    $E12000
            LDA     #$7DC6
            LDX     #$2000
            TXY
            INY
            MVN     #$E1,#$E1

            SEP     #$20         ; A8 mode
            LDA     #$C0         ; Enter Super High-Res mode
            TSB     $C029

            LDX     #GFXDATA     ; Draw logo
            LDA     #^GFXDATA
            JSR     DECODERLE

            PHK                  ; Data bank = prog bank
            PLB
            LDY     #STEREO
            JSR     PLAYWAV

QUIT        JSL     $E100A8      ; GS/OS Call
            DA      $2029        ; QUIT
            ADRL    :ARGS
:ARGS       DA      0

*** Direct Page variables ***
            DUM         0
GFXPTR      DS      4            ; RLE decode source pointer
GFXCTR      DS      1            ; RLE decode unit counter
            DEND

DECODERLE   STX     GFXPTR
            STA     GFXPTR+2
            LDY     #$00
:BLOCK      REP     #$20         ; Collect start destination
            LDA     [GFXPTR],Y
            INY
            INY
            TAX
            SEP     #$20
            BEQ     :END         ; Destination zero = end decode
:LP         LDA     [GFXPTR],Y   ; Load length/type byte
            BMI     :RUN         ; Top bit set = run
            BNE     :COPY        ; Top bit clear, nonzero = copy
            INY                  ; Zero length = end of block
            BRA     :BLOCK
:RUN        INY
            AND     #$7F
            STA     GFXCTR
            LDA     [GFXPTR],Y   ; Load run value byte
            INY
:RUNLP      STAL    $E10000,X
            INX
            DEC     GFXCTR
            BNE     :RUNLP
            BRA     :LP
:COPY       INY
            STA     GFXCTR
:COPYLP     LDA     [GFXPTR],Y
            STAL    $E10000,X
            INX
            INY
            DEC     GFXCTR
            BNE     :COPYLP
            BRA     :LP
:END        RTS

            USE     gswav.s
