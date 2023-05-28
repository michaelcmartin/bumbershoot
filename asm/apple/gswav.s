************************************
*    Apple IIgs Waveform Player    *
*    Bumbershoot Software, 2023    *
************************************

***************************************
* PLAYWAV: Plays an 8kHz sound effect *
*    Wave data at SFX                 *
*    Wave length is SFXLEN            *
*    .Y is address of control codes   *
*    Call with 8-bit .A and 16-bit .I *
***************************************
            MX    %10
PLAYWAV     SEI               ; Disable interrupts
            LDAL  $E0C03C     ; Put sound GLU in RAM mode
            ORA   #$60        ; and auto-increment mode
            STAL  $E0C03C
            LDA   #$00        ; Write to first 32KB of RAM
            STAL  $E0C03E
            STAL  $E0C03F
            LDX   #$0000      ; And copy the wave data into it
:LOAD       LDAL  SFX,X
            STAL  $E0C03D
            INX
            CPX   #SFXLEN
            BNE   :LOAD

            LDAL  $E0C03C       ; Switch to DOC registers
            AND   #$9F
            STAL  $E0C03C

* Load the DOC registers from our init table
            TYX
:PLAY       LDA:  0,X         ; On data bank page, not direct!
            INX
            CMP   #$FF
            BEQ   :WAIT
            TAY
            LDA:  0,X         ; On data bank page, not direct!
            INX
            JSR   :SETREG
            BRA   :PLAY

:WAIT       SEI               ; Atomic access to DOC
:1          LDAL  $E0C03C     ; Loop until DOC not busy
            BMI   :1
            LDA   #$A0        ; Read control byte
            STAL  $E0C03E
            LDAL  $E0C03D     ; Throw out trash value
            LDAL  $E0C03D     ; Read real value
            CLI               ; Re-enable interrupts again
            AND   #$01        ; Halted?
            BEQ   :WAIT       ; If not, go back to check status again
            RTS               ; If so, return to caller

* Write value in .A to DOC register .Y
:SETREG     PHA
:2          LDAL  $E0C03C
            BMI   :2          ; Loop until DOC not busy
            TYA
            STAL  $E0C03E     ; Set address
            LDA   #$00
            STAL  $E0C03F
            PLA
            STAL  $E0C03D     ; Write value
            RTS

*******************************************************************
* Stereo playback registers. Synchronize channels 0 and 1 and set *
* them to left/right channels respectively. Then point them both  *
* at the first 32KB of sound RAM and have them play back at 8kHz. *
*******************************************************************
STEREO      HEX   A0,05,A1,15,E1,02
            HEX   00,12,01,12,20,00,21,00,40,FF,41,FF
            HEX   80,00,81,00,C0,3F,C1,3F,A0,04
            HEX   FF

MONOLEFT    HEX   A0,03,E1,02
            HEX   00,12,20,00,40,FF,80,00,C0,3F
            HEX   A0,02
            HEX   FF

MONORIGHT   HEX   A0,13,E1,02
            HEX   00,12,20,00,40,FF,80,00,C0,3F
            HEX   A0,12
            HEX   FF
