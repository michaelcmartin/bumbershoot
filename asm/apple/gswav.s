************************************
*    Apple IIgs Waveform Player    *
*    Bumbershoot Software, 2023    *
************************************

***************************************
* PLAYWAV: Plays an 8kHz sound effect *
*    Wave data at SFX                 *
*    Wave length is SFXLEN            *
*    Data bank has I/O mapped in      *
*    Call with 8-bit .A and 16-bit .I *
***************************************
            MX    %10
PLAYWAV     SEI               ; Disable interrupts
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
:PLAY       LDAL  :STEREO,X
            INX
            CMP   #$FF
            BEQ   :WAIT
            TAY
            LDAL  :STEREO,X
            INX
            JSR   :SETREG
            BRA   :PLAY

:WAIT       SEI               ; Atomic access to DOC
:1          LDA   $C03C       ; Loop until DOC not busy
            BMI   :1
            LDX   #$A0        ; Read control byte
            STX   $C03E
            LDA   $C03D       ; Throw out trash value
            LDA   $C03D       ; Read real value
            CLI               ; Re-enable interrupts again
            AND   #$01        ; Halted?
            BEQ   :WAIT       ; If not, go back to check status again
            RTS               ; If so, back to caller

* Write value in .A to DOC register .Y
:SETREG     PHA
:2          LDA   $C03C
            BMI   :2          ; Loop until DOC not busy
            STY   $C03E       ; Set address
            PLA
            STA   $C03D       ; Write value
            RTS

*******************************************************************
* Stereo playback registers. Synchronize channels 0 and 1 and set *
* them to left/right channels respectively. Then point them both  *
* at the first 32KB of sound RAM and have them play back at 8kHz. *
*******************************************************************
:STEREO     HEX   A0,05,A1,15,E1,02
            HEX   00,12,01,12,20,00,21,00,40,FF,41,FF
            HEX   80,00,81,00,C0,3F,C1,3F,A0,04
            HEX   FF
