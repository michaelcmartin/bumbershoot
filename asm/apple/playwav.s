            MX    %00
            REL
            LNK   WOW.L

            EXT   SFX,SFXLEN

START       SEP   #$20        ; 8-bit accumulator
            LDA   #$E0        ; Data bank points to I/O region
            PHA
            PLB

            LDA   #$C0        ; Super High-Res mode
            TSB   $C029       ; (leave Finder up)

            SEI               ; Disable interrupts
            LDA   $C03C       ; Put sound GLU in RAM mode
            ORA   #$60        ; and auto-increment mode
            STA   $C03C
            LDA   #$00        ; Write to first 32KB of RAM
            STA   $C03E
            STA   $C03F
            LDX   #$0000      ; And copy the wave data into it
:LOAD       LDAL  SFX,X
            STA   $C03D
            INX
            CPX   #SFXLEN
            BNE   :LOAD

            LDA   $C03C       ; Switch to DOC registers
            AND   #$9F
            STA   $C03C

* Load the DOC registers from our init table
            SEP   #$10        ; 8 bit registers
            LDX   #$00
PLAY        LDAL  STEREO,X
            INX
            CMP   #$FF
            BEQ   WAIT
            TAY
            LDAL  STEREO,X
            INX
            JSR   SETREG
            BRA   PLAY

WAIT        SEI
:1          LDA   $C03C       ; Loop until DOC not busy
            BMI   :1
            LDX   #$A0
            STX   $C03E
            LDA   $C03D
            LDA   $C03D
            CLI
            AND   #$01        ; Halted?
            BEQ   WAIT

QUIT        JSL   $E100A8     ; GS/OS DOS call
            DA    $2029       ; Quit
            ADRL  :ARGS
:ARGS       DA    0           ; No args

SETREG      PHA
:1          LDA   $C03C
            BMI   :1          ; Loop until DOC not busy
            STY   $C03E
            PLA
            STA   $C03D
            RTS

STEREO      HEX   A0,05,A1,15,E1,02
            HEX   00,12,01,12,20,00,21,00,40,FF,41,FF
            HEX   80,00,81,00,C0,3F,C1,3F,A0,04
            HEX   FF
