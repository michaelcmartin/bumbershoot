            MX      %00
            REL
            LNK     PLAY.WOW#B30000.L

START       SEP     #$20               ; 8-bit accumulator
            LDA     #$E0               ; Data bank points to I/O region
            PHA
            PLB

            LDA     #$C0               ; Super High-Res mode
            TSB     $C029              ; (leave Finder up)

            JSR     PLAYWAV            ; Play the sound

QUIT        JSL     $E100A8            ; GS/OS DOS call
            DA      $2029              ; Quit
            ADRL    :ARGS
:ARGS       DA      0                  ; No args

            USE     gswav.s            ; Include the wave player

SFX         PUTBIN  wow_gs.bin         ; Include the sound effect
SFXEND

SFXLEN      EQU     SFXEND-SFX
