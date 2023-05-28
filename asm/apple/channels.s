            MX      %00
            REL
            LNK     CHANNELS#B30000.L

START       PHK                        ; Set Data bank appropriately
            PLB

            SEP     #$20               ; 8-bit accumulator
            JSR     OPENCON

            LDX     #MSG1
            LDY     #MSG1LEN
            JSR     STROUT
            LDY     #MONOLEFT
            JSR     PLAYWAV

            LDX     #MSG2
            LDY     #MSG2LEN
            JSR     STROUT
            LDY     #MONORIGHT
            JSR     PLAYWAV

            LDX     #MSG3
            LDY     #MSG3LEN
            JSR     STROUT
            LDY     #STEREO
            JSR     PLAYWAV

QUIT        JSR     CLOSECON
            JSL     $E100A8            ; GS/OS DOS call
            DA      $2029              ; Quit
            ADRL    :ARGS
:ARGS       DA      0                  ; No args

OPENCON     JSL     $E100A8            ; GS/OS DOS call
            DA      $2010              ; Open
            ADRL    :ARGS
            LDX     :ARGS+2            ; Extract refnum
            STX     CONSOLE            ; Save it in the STROUT block
            RTS
:ARGS       DA      3,0
            ADRL    CONPATH
            DA      2                  ; Write access

CLOSECON    LDX     CONSOLE            ; Copy console device to output
            STX     :ARGS+2
            JSL     $E100A8            ; GS/OS DOS call
            DA      $2014              ; Close
            ADRL    :ARGS
            RTS
:ARGS       DA      1,0

STROUT                                 ; Blank line for :ARGS resolution
            STX     :ARGS+4
            STY     :ARGS+8
            JSL     $E100A8            ; GS/OS DOS call
            DA      $2013              ; Write
            ADRL    :ARGS
            RTS
:ARGS       DA      4
CONSOLE     DA      0                  ; To be filled in by OPENCON
            ADRL    MSG1
            ADRL    5,0

            USE     gswav.s            ; Include the wave player

CONPATH     STRL    '11/'
MSG1        ASC     'Wow! Digital sound!',0D,'Left Channel Playback',0D
MSG1LEN     EQU     *-MSG1

MSG2        ASC     'Right Channel Playback',0D
MSG2LEN     EQU     *-MSG2

MSG3        ASC     'Stereo Playback',0D
MSG3LEN     EQU     *-MSG3

SFX         PUTBIN  wow_gs.bin         ; Include the sound effect
SFXLEN      EQU     *-SFX
