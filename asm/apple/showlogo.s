            MX    %00
            REL
            LNK   SHOW.LOGO.L
            EXT   SFX,SFXLEN,GFXDATA

START       LDA   #$00                ; Clear Super Hi-Res Screen
            STAL  $E12000
            LDA   #$7DC6
            LDX   #$2000
            TXY
            INY
            MVN   #$E1,#$E1

            SEP   #$20                ; A8 mode
            LDA   #$C0                ; Enter Super High-Res mode
            TSB   $C029

            LDX   #GFXDATA            ; Draw logo
            LDA   #^GFXDATA
            JSR   DECODERLE

            PHK                       ; Data bank = prog bank
            PLB
            LDY   #STEREO
            JSR   PLAYWAV

QUIT        JSL   $E100A8             ; GS/OS Call
            DA    $2029               ; QUIT
            ADRL  :ARGS
:ARGS       DA    0

DECODERLE   PHB                       ; Save original bank
            PHK                       ; Shift to code bank for self-mod
            PLB
            STAL  :1+3                ; Place bank in the four
            STAL  :2+3                ; instructions that need them
            STAL  :3+3
            STAL  :4+2
:BLOCK      REP   #$20                ; Collect start destination
:1          LDAL  0,X
            INX
            INX
            TAY
            SEP   #$20
            BEQ   :END                ; Destination zero = end decode
:LP         LDA   #$00                ; set high byte to 0
            XBA
:2          LDAL  0,X                 ; Load length/type byte
            BMI   :RUN                ; Top bit set = run
            BNE   :COPY               ; Top bit clear, nonzero = copy
            INX                       ; Zero length = end of block
            BRA   :BLOCK
:RUN        INX
            PHX
            AND   #$7F
            PHA
:3          LDAL  0,X                 ; Load run value byte
            TYX
            STAL  $E10000,X
            INY
            PLA
            DEC
            DEC
            MVN   #$E1,#$E1
            PLX
            INX
            BRA   :LP
:COPY       INX
            DEC
:4          MVN   #$00,#$E1
            BRA   :LP
:END        PLB
            RTS

            USE   gswav.s
