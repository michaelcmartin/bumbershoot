                 DSK   SimEvo8#FF2000
                 TYP   $FF
                 ORG   $2000

                 MX    %11

*** Monitor routines
COUT             =     $FDED
HOME             =     $FC58
PRODOS8          =     $BF00

*** Aliases we carve out of SimEvo's SCRATCH3 space
BORDER           =     SCRATCH3+15

*** Main program
START            JSR   HOME              ; Clear screen
                 LDA   #>TITLE_MSG       ; Display title
                 LDY   #$00
                 STA   :1+2
:1               LDA   TITLE_MSG,Y
                 BEQ   :2
                 JSR   COUT
                 INY
                 BNE   :1
                 INC   :1+2
                 BNE   :1
:2               BIT   $C010             ; Clear KB buffer
                 CLC                     ; Escape into 65816 mode
                 XCE
                 REP   #$10              ; 16-bit indices
                 LDX   #$0000
:3               INX                     ; Bump iteration counter
                 BIT   $C000             ; Wait for key
                 BPL   :3
                 BIT   $C010
                 STX   SCRATCH           ; Save iteration counter
                 SEP   #$10              ; Back to 8-bit everything
                 LDA   SCRATCH           ; Use iteration counter to seed PRNG
                 LDX   SCRATCH+1
                 JSR   SRND

                 JSR   INIT_GFX
                 JSR   INIT_BACTERIA
                 JSR   INIT_BUGS

MAINLP           LDA   $C000             ; Check for key
                 BPL   :STEP             ; No keypress, no problem
                 BIT   $C010             ; Acknowledge keypress
                 CMP   #$C7              ; Garden?
                 BEQ   :GARDEN
                 CMP   #$E7              ; Lowercase input?
                 BEQ   :GARDEN
                 CMP   #$9b              ; Pressed ESC?
                 BNE   :STEP
                 BEQ   :QUIT
:GARDEN          LDA   GARDEN
                 EOR   #$01
                 STA   GARDEN
:STEP            JSR   RUN_STEP
                 JMP   MAINLP

* Return to ProDOS
:QUIT            JSR   EXIT_GFX
                 SEC                     ; Back to emulation mode
                 XCE
                 JSR   PRODOS8
                 DB    $65
                 DA    :QARG
                 BRK
:QARG            DFB   4,0,0,0,0,0,0

*** Support routines and data

TITLE_MSG        ASC   8D,8D,"        "
                 INV   "                        "
                 ASC   8D,"        "
                 INV   "  SIMULATED  EVOLUTION  "
                 ASC   8D,"        "
                 INV   "                        "
                 ASC   8D,8D,8D,8D,"  ][gs edition by Michael Martin, 2026",8D,8D
                 ASC   "            Original program",8D
                 ASC   "          Michael Palmiter and",8D
                 ASC   "          Martin Gardner, 1989",8D,8D,8D,8D
                 ASC   "    Press G to toggle Garden of Eden",8D
                 ASC   "          Press Escape to quit",8D,8D,8D,8D,8D
                 ASC   "       "
                 INV   "  PRESS ANY KEY TO BEGIN  "
                 DFB   0

INIT_GFX         REP   #$30              ; 16-bit everything
                 LDX   #$7C60            ; Clear out last line and all mode lines and palettes
                 LDA   #$0000
:1               STAL  $E12000,X
                 INX
                 INX
                 CPX   #$8000
                 BNE   :1
                 LDA   #$0A              ; Just write the palette directly
                 STAL  $E19E02
                 LDA   #$A0
                 STAL  $E19E04
                 LDA   #$0FFF
                 STAL  $E19E06
                 LDA   #$1111            ; Draw the pool in the last line
                 LDX   #$7C65
                 LDY   #75
:2               STAL  $E12000,X
                 INX
                 INX
                 DEY
                 BNE   :2
                 LDX   #$7C5E            ; Now copy everything backwards to fill the screen
:3               LDAL  $E120A0,X
                 STAL  $E12000,X
                 DEX
                 DEX
                 BPL   :3
                 SEP   #$30              ; Back to 8-bit everything
                 LDA   $C034             ; Collect border value
                 AND   #$0F
                 STA   BORDER
                 LDA   #$0F
                 TRB   $C034             ; Turn border black
                 LDA   #$C0
                 TSB   $C029             ; Enable Super High-Res Mode
                 RTS

EXIT_GFX         LDA   #$C0              ; Leave Super High-Res Mode
                 TRB   $C029
                 LDA   BORDER            ; Restore border color
                 TSB   $C034
                 RTS

                 MX    %00               ; This routine is pure 16-bit
SHR_ADDRESS      TYA                     ; Compute Y*320 + X, which equals...
                 XBA                     ; ... Y * 256...
                 STA   SCRATCH3
                 LSR                     ; ... + Y * 64...
                 LSR
                 ADC   SCRATCH3
                 STX   SCRATCH3          ; ... + X.
                 ADC   SCRATCH3
                 TAX
                 RTS

                 MX    %10               ; This routine is A8 X16
EATEN            =     SCRATCH3
PAINT_AND_EAT    PHA
                 LDA   #$22
                 CMPL  $E12005,X
                 BNE   :NOTFOOD
                 INC   EATEN
:NOTFOOD         PLA
                 STAL  $E12005,X
                 STAL  $E120A5,X
                 RTS

                 MX    %11               ; Back to project standard 8-bit

                 DUM   $12CA
NUMBUGS          DS    1
GARDEN           DS    1
RNDVAL           DS    4
SCRATCH          DS    16
SCRATCH2         DS    16
SCRATCH3         DS    16
BUG_X            DS    256               ; This should land exactly at $1300
BUG_Y            DS    256
BUG_AGE          DS    512               ; 256 * 2
BUG_HP           DS    512
BUG_DIR          DS    256
BUG_DNA          DS    1536              ; 256 * 6
                 DEND

INIT_BACTERIA    LDA   #100
                 STA   SCRATCH2
]1               LDA   #ARENA_HEIGHT
                 LDX   #$00
                 JSR   INTRND
                 LDA   INTRNDVAL
                 STA   SCRATCH2+2
                 LDA   #ARENA_WIDTH
                 LDX   #$00
                 JSR   INTRND
                 LDX   INTRNDVAL
                 LDY   SCRATCH2+2
                 JSR   DRAW_BACTERIUM
                 DEC   SCRATCH2
                 BNE   ]1
                 LDA   #$00
                 STA   GARDEN
                 RTS

INIT_BUGS        LDA   #$00
                 STA   NUMBUGS
]1               LDA   #ARENA_HEIGHT-2
                 LDX   #$00
                 JSR   INTRND
                 LDA   INTRNDVAL
                 LDX   NUMBUGS
                 STA   BUG_Y,X
                 LDA   #40
                 STA   BUG_HP,X
                 LDA   #$00
                 STA   BUG_HP+$100,X
                 STA   BUG_AGE,X
                 STA   BUG_AGE+$100,X
                 LDA   #ARENA_WIDTH-2
                 LDX   #$00
                 JSR   INTRND
                 LDA   INTRNDVAL
                 LDX   NUMBUGS
                 STA   BUG_X,X
                 JSR   DRAW_BUG
                 LDA   #$06
                 LDX   #$00
                 JSR   INTRND
                 LDA   INTRNDVAL
                 LDX   NUMBUGS
                 STA   BUG_DIR,X
                 LDA   #>BUG_DNA
                 STA   :DNAPAGE
]2               LDA   #10
                 LDX   #0
                 JSR   INTRND
                 LDA   INTRNDVAL
                 LDX   NUMBUGS
:DNAPAGE         EQU   *+2
                 STA   BUG_DNA,X
                 INC   :DNAPAGE
                 LDA   :DNAPAGE
                 CMP   #{BUG_DNA/256}+6
                 BNE   ]2
                 JSR   NORMALIZE_GENES
                 INC   NUMBUGS
                 CPX   #9
                 BNE   ]1
                 RTS

RUN_STEP
:TOTAL           =     SCRATCH2
                 LDX   #$00
:RUNLP           CPX   NUMBUGS
                 BNE   :DOBUG
                 JMP   :PLANKTON
:DOBUG           JSR   ERASE_BUG

* Choose a direction to go in. Shift the bug number to .Y here.
                 TXA
                 TAY

* Sum the gene weights.
                 LDA   #<BUG_DNA
                 STA   $FB
                 LDA   #>BUG_DNA         ; Reset bug DNA pointer
                 STA   $FC
                 LDA   #$00
                 STA   :TOTAL
                 STA   :TOTAL+1
]1               LDA   ($FB),Y
                 TAX
                 CLC
                 LDA   WGT_L,X
                 ADC   :TOTAL
                 STA   :TOTAL
                 LDA   WGT_H,X
                 ADC   :TOTAL+1
                 STA   :TOTAL+1
                 INC   $FC
                 LDA   $FC
                 CMP   #{BUG_DNA/256}+6
                 BNE   ]1

* Pick a value within the total weight.
                 TYA
                 PHA
                 LDA   :TOTAL
                 LDX   :TOTAL+1
                 JSR   INTRND
                 PLA
                 TAY

* Translate weighted value to relative direction.
                 LDA   #>BUG_DNA         ; Reset bug DNA pointer
                 STA   $FC
                 LDA   #$00
                 STA   :TOTAL
                 STA   :TOTAL+1
]1               LDA   ($FB),Y
                 TAX
                 CLC
                 LDA   WGT_L,X
                 ADC   :TOTAL
                 STA   :TOTAL
                 LDA   WGT_H,X
                 ADC   :TOTAL+1
                 STA   :TOTAL+1
                 SEC
                 LDA   :TOTAL
                 SBC   INTRNDVAL
                 LDA   :TOTAL+1
                 SBC   INTRNDVAL+1
                 BCS   :FOUND
                 INC   $FC
                 LDA   $FC
                 CMP   #{BUG_DNA/256}+5
                 BNE   ]1
:FOUND           LDA   $FC
                 SEC
                 SBC   #>BUG_DNA

* Apply relative direction to bug_dir.
                 CLC
                 ADC   BUG_DIR,Y
                 CMP   #$06
                 BCC   :DIROK
                 SEC
                 SBC   #$06
:DIROK           STA   BUG_DIR,Y

* Put the bug index back in .X.
                 TYA
                 TAX

* Move in direction and bounds check
                 LDA   BUG_DIR,X
                 TAY
                 LDA   BUG_X,X
                 CLC
                 ADC   XMV,Y
                 CMP   #$F0
                 BCC   :B1OK
                 LDA   #$00
:B1OK            CMP   #ARENA_WIDTH-3
                 BCC   :B2OK
                 LDA   #ARENA_WIDTH-3
:B2OK            STA   BUG_X,X
                 LDA   BUG_Y,X
                 CLC
                 ADC   YMV,Y
                 CMP   #$F0
                 BCC   :B3OK
                 LDA   #$00
:B3OK            CMP   #ARENA_HEIGHT-3
                 BCC   :B4OK
                 LDA   #ARENA_HEIGHT-3
:B4OK            STA   BUG_Y,X

* Bug aging
                 INC   BUG_AGE,X
                 BNE   :B5OK
                 INC   BUG_AGE+$100,X
:B5OK            LDA   BUG_AGE+$100,X    ; Cap bug age at 4,096
                 CMP   #$10
                 BMI   :B6OK
                 DEC   BUG_AGE+$100,X
:B6OK            LDA   #$FF
                 DEC   BUG_HP,X
                 CMP   BUG_HP,X
                 BNE   :B7OK
                 DEC   BUG_HP+$100,X

* Bug starves?
:B7OK            LDA   BUG_HP+$100,X
                 BMI   :DIES
                 BNE   :LIVES
                 LDA   BUG_HP,X
                 BNE   :LIVES
:DIES            DEC   NUMBUGS
                 LDY   NUMBUGS
                 JSR   COPY_BUG
                 DEX
                 JMP   :NEXT
:LIVES           LDA   NUMBUGS           ; Do not reproduce if pop 255
                 CMP   #$FF
                 BEQ   :DONE
                 SEC
                 LDA   BUG_AGE,X         ; Bug must be 800 units old at least
                 SBC   #<800
                 LDA   BUG_AGE+$100,X
                 SBC   #>800
                 BMI   :DONE
                 SEC
                 LDA   BUG_HP,X          ; Bug must have at least 1000 hp
                 SBC   #<1000
                 LDA   BUG_HP+$100,X
                 SBC   #>1000
                 BMI   :DONE
* Bug reproduces
                 LSR   BUG_HP+$100,X
                 ROR   BUG_HP,X
                 LDA   #$00
                 STA   BUG_AGE,X
                 STA   BUG_AGE+$100,X
                 TXA
                 PHA                     ; Stash current bug number
                 TAY
                 LDX   NUMBUGS
                 JSR   COPY_BUG
                 LDA   #$06              ; Mutate younger twin
                 LDX   #$00
                 JSR   INTRND
                 LDX   NUMBUGS
                 LDA   #>BUG_DNA
                 CLC
                 ADC   INTRNDVAL
                 STA   *+5               ; Modify high byte of next insn
                 INC   BUG_DNA,X
                 JSR   NORMALIZE_GENES
                 LDA   #$06              ; Mutate elder twin
                 LDX   #$00
                 JSR   INTRND
                 PLA                     ; Restore elder twin index
                 TAX
                 LDA   #>BUG_DNA
                 CLC
                 ADC   INTRNDVAL
                 STA   *+5
                 DEC   BUG_DNA,X
                 JSR   NORMALIZE_GENES
                 INC   NUMBUGS
                 JSR   DRAW_BUG
                 DEX                     ; Reprocess first child
                 JMP   :NEXT
:DONE            JSR   DRAW_BUG
:NEXT            INX
                 JMP   :RUNLP

* Replenish plankton
:PLANKTON        LDA   #ARENA_WIDTH
                 LDX   #$00
                 JSR   INTRND
                 LDA   INTRNDVAL
                 PHA
                 LDA   #ARENA_HEIGHT
                 LDX   #$00
                 JSR   INTRND
                 LDY   INTRNDVAL
                 PLA
                 TAX
                 JSR   DRAW_BACTERIUM
                 LDA   GARDEN            ; Replenish Garden of Eden if active
                 BEQ   :NOGARD
                 LDA   #$14
                 LDX   #$00
                 JSR   INTRND
                 CLC
                 LDA   INTRNDVAL
                 ADC   #$28
                 PHA
                 LDA   #$14
                 LDX   #$00
                 JSR   INTRND
                 CLC
                 LDA   INTRNDVAL
                 ADC   #$50
                 TAY
                 PLA
                 TAX
                 JSR   DRAW_BACTERIUM
:NOGARD          RTS

*** Copies a bug from .Y to .X. .A is trashed.
COPY_BUG         LDA   #>BUG_X
                 STA   :CPAGE1
                 STA   :CPAGE2
]1               LDA   BUG_X,Y
:CPAGE1          =     *-1
:CPAGE2          =     *+2
                 STA   BUG_X,X
                 INC   :CPAGE1
                 INC   :CPAGE2
                 LDA   :CPAGE2
                 CMP   #{BUG_DNA/256}+6
                 BNE   ]1
                 RTS

*** Motion tables for each gene
XMV              DFB   $00,$02,$02,$00,$FE,$FE
YMV              DFB   $02,$01,$FF,$FE,$FF,$01
*** Low and high bytes of the gene weights. This is actually
*** two 14-byte tables that overlap.
WGT_H            DFB   $00,$00,$00,$00,$00,$00,$00,$00
WGT_L            DFB   $01,$02,$04,$08,$10,$20,$40,$80
                 DFB   $00,$00,$00,$00,$00,$00

*** Simplifies the genome of bug x. There will be at least
*** one gene with the value 0, and no genes of value less
*** than zero or greater than 13. This will ensure that the
*** weighted sum when generating behavior will always fit
*** within 16 bits.
NORMALIZE_GENES  PHA
                 TYA
                 PHA
                 TXA
                 TAY                     ; Move bug index to Y
                 LDA   #<BUG_DNA
                 STA   $FB
                 LDA   #>BUG_DNA
                 STA   $FC
* Find minimum gene value
                 LDA   ($FB),Y
                 LDX   #5
]1               INC   $FC
                 CMP   ($FB),Y
                 BMI   :OK
                 LDA   ($FB),Y
:OK              DEX
                 BNE   ]1
                 STA   $FD               ; Minimum gene value
* Restore pointer and normalize
                 LDA   #>BUG_DNA
                 STA   $FC
                 LDX   #6
]1               LDA   ($FB),Y
                 SEC
                 SBC   $FD
                 CMP   #13
                 BCC   :OK2
                 LDA   #13
:OK2             STA   ($FB),Y
                 INC   $FC
                 DEX
                 BNE   ]1
* Restore original register values
                 TYA
                 TAX
                 PLA
                 TAY
                 PLA
                 RTS

* Feeds bug X. bug_hp increases by 40, and caps at 1500.
FEED_BUG         PHA
                 LDA   BUG_HP,X
                 CLC
                 ADC   #40
                 STA   BUG_HP,X
                 BCC   :OK
                 INC   BUG_HP+$100,X
:OK              LDA   BUG_HP,X
                 SEC
                 SBC   #<1500
                 LDA   BUG_HP+$100,X
                 SBC   #>1500
                 BMI   :BUG_HUNGRY
                 LDA   #<1500
                 STA   BUG_HP,X
                 LDA   #>1500
                 STA   BUG_HP+$100,X
:BUG_HUNGRY      PLA
                 RTS

*** 16-bit multiplication function. 2-byte arguments go in
*** the MUL1 and MUL2 arguments. The 4-byte result is in
*** MUL1 after the call.
MULT16
MUL1             EQU   SCRATCH
MUL2             EQU   SCRATCH+4
:MUL1B           EQU   SCRATCH+6
:REG             EQU   SCRATCH+8

                 LDA   MUL1              ; Back up mul1 since that space
                 STA   :MUL1B            ; is reused as our result
                 LDA   MUL1+1
                 STA   :MUL1B+1
                 LDA   #$00
                 STA   MUL1
                 STA   MUL1+1
                 STA   MUL1+2
                 STA   MUL1+3
                 STY   :REG
                 LDY   #$10
]1               ASL   MUL1
                 ROL   MUL1+1
                 ROL   MUL1+2
                 ROL   MUL1+3
                 ASL   MUL2
                 ROL   MUL2+1
                 BCC   :Z
                 CLC
                 LDA   :MUL1B
                 ADC   MUL1
                 STA   MUL1
                 LDA   :MUL1B+1
                 ADC   MUL1+1
                 STA   MUL1+1
                 LDA   MUL1+2
                 ADC   #$00
                 STA   MUL1+2
                 LDA   MUL1+3
                 ADC   #$00
                 STA   MUL1+3
:Z               DEY
                 BNE   ]1
                 LDY   :REG
                 RTS

* SRND and RND: seed and update prng. 16-bit result in rndval.
* Seed randomizer with .AX in both values. Calling RDTIM
* ($FFDE) is a good way to get values for .AX.
SRND             ORA   #$01
                 STA   RNDVAL+2
                 STA   RNDVAL
                 STX   RNDVAL+3
                 STX   RNDVAL+1
                 RTS

RND
:X               EQU   RNDVAL+2
:Y               EQU   RNDVAL
                 LDA   :X                ; :X ^= :X << 5
                 LDY   :X+1
                 LDX   #$05
:LP              ASL
                 ROL   :X+1
                 DEX
                 BNE   :LP
                 EOR   :X
                 STA   :X
                 TYA
                 EOR   :X+1
                 STA   :X+1
                 LDY   :X                ; :X ^= :X >> 3
                 LDX   #$03              ; .A already has :X+1
:LP2             LSR
                 ROR   :X
                 DEX
                 BNE   :LP2
                 EOR   :X+1
                 STA   :X+1
                 TYA
                 EOR   :X
                 STA   :X
                 LDA   :Y                ; PUSH :Y
                 PHA
                 LDA   :Y+1
                 PHA
                 LSR                     ; (:X, :Y) = (:Y, :Y ^ (:Y >> 1) ^ :X)
                 ROR   :Y
                 EOR   :X+1
                 STA   :Y+1
                 PLA
                 STA   :X+1
                 EOR   :Y+1
                 STA   :Y+1
                 PLA
                 TAX
                 EOR   :Y
                 EOR   :X
                 STA   :Y
                 STX   :X
                 RTS

*** INTRND: Returns a value between 0 and (.AX - 1) in INTRNDVAL.
INTRNDVAL        EQU   MUL1+2
INTRND           STA   MUL1
                 STX   MUL1+1
                 JSR   RND
                 LDA   RNDVAL
                 STA   MUL2
                 LDA   RNDVAL+1
                 STA   MUL2+1
                 JMP   MULT16

*** SimEvoCore callbacks

** Dimensions of the usable screen
ARENA_WIDTH      =     150
ARENA_HEIGHT     =     100

DRAW_BACTERIUM   PHA                     ; Preserve all registers
                 PHX
                 REP   #$30              ; 16-bit mode for RTS
                 JSR   SHR_ADDRESS
                 SEP   #$20              ; Back to 8-bit memory
                 LDA   #$22              ; Draw green
                 STAL  $E12005,X         ; in two adjacent rows
                 STAL  $E120A5,X
                 SEP   #$10              ; Back to 8-bit everything
                 PLX                     ; Restore registers we trashed
                 PLA
                 RTS

ERASE_BUG        PHA
                 LDA   #$11
                 STA   PAINT_COLOR
                 BNE   PAINT_BUG

DRAW_BUG         PHA
                 LDA   #$33
                 STA   PAINT_COLOR
* Fall through into PAINT_BUG

PAINT_BUG        PHY
                 PHX
                 LDY   BUG_Y,X
                 LDA   BUG_X,X
                 TAX
                 REP   #$30
                 JSR   SHR_ADDRESS
                 SEP   #$20
                 LDY   #$03
                 STZ   EATEN
PAINT_COLOR      =     *+1
]1               LDA   #$00
                 JSR   PAINT_AND_EAT
                 INX
                 JSR   PAINT_AND_EAT
                 INX
                 JSR   PAINT_AND_EAT
                 REP   #$20
                 TXA
                 CLC
                 ADC   #318
                 TAX
                 SEP   #$20
                 DEY
                 BNE   ]1
                 SEP   #$10
                 PLX                     ; Restore bug number in .X
                 PLY
                 LDA   EATEN
                 BEQ   :DONE
]1               JSR   FEED_BUG
                 DEC   EATEN
                 BNE   ]1
:DONE            PLA
                 RTS
