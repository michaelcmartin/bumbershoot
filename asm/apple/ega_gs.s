**********************************************************************
*   EGA demo screen for the Apple IIgs
*   Build with Ophis and Merlin 32:
*     $ ophis ../fonts/sinestra.s -o sinestra.bin
*     $ merlin32 ega_gs.s
**********************************************************************
              MX      %00              ; Full 16-bit mode
              REL
              LNK     ega#b30000.l

START         LDA     #$011F           ; Load 9 palettes
              LDX     #PALETTES
              LDY     #$9E00
              MVN     #^PALETTES,#$E1  ; and set data bank to #$E1

              STZ     $2000            ; Clear the screen
              LDA     #$7CFE
              LDX     #$2000
              TXY
              INY
              MVN     #$E1,#$E1

              SEP     #$20             ; A8 mode for main program logic

              LDA     #$C0             ; Enter Super High-Res mode
              TSB     $C029
              LDA     $C034            ; Load current border color
              AND     #$0F             ; Mask to only border color
              PHA                      ; Save to end of program
              LDA     #$0F             ; Set border color to black
              TRB     $C034

*** Select the control codes for each line: $80 for the top and
*** bottom 8, then 23 lines of 1-8 each. Two lines of 80-col
*** text, and the rest is 16-color graphics
              LDA     #$80
              LDX     #$0000
              LDY     #$0008
:1            STA     $9D00,X          ; Lines 0-7
              STA     $9DC0,X          ; Lines 192-199
              INX
              DEY
              BNE     :1

              LDA     #$01             ; .X is 8 here, which we want
:2            LDY     #23              ; 23 lines per block
:3            STA     $9D00,X
              INX
              DEY
              BNE     :3
              INC                      ; Next block has next palette
              CMP     #$09             ; Have we done all 8?
              BNE     :2               ; If not, next block

*** Draw the EGA grid
              LDY     #64              ; 64 boxes to draw
              LDX     #$05B1           ; Starting at (34, 9)
              LDA     #$11             ; And fill color 1
DRAW_GRID
              JSR     BOX              ; Draw one box
              CLC                      ; Advance to next color
              ADC     #$11
              CMP     #$99             ; Have we done all 8?
              BNE     :RIGHT           ; If so, move right
              REP     #$21             ; Otherwise move down. A16, CLC.
              TXA                      ; .X += (160*23) - (16*7)
              ADC     #$DF0
              TAX
              SEP     #$20
              LDA     #$11             ; And reset to color 1 for next row
              BRA     :NEXT
:RIGHT        PHA                      ; Stash 8-bit color
              REP     #$21             ; A16 and CLC
              TXA                      ; .X += 16 (move right)
              ADC     #$0010
              TAX
              SEP     #$20
              PLA                      ; Restore 8-bit color value
:NEXT         DEY                      ; Have we drawn all 64?
              BNE     DRAW_GRID        ; If not, back we go

*** Draw the header and footer text
              LDX     #$001B
              LDY     #HEADER
              JSR     DRAWSTR_80

              LDX     #$7828
              LDY     #FOOTER
              JSR     DRAWSTR_80

*** Label grid entries
              LDX     #$0A14
              LDA     #$00
LABELS        PHA
              LSR                      ; Extract high nybble
              LSR
              LSR
              LSR
              JSR     TOHEX
              JSR     DRAWCHAR_40
              LDA     1,S              ; Recover without popping
              AND     #$0F
              JSR     TOHEX
              JSR     DRAWCHAR_40
              LDA     1,S              ; Recover again
              AND     #$07             ; End of line?
              CMP     #$07
              REP     #$21             ; 16-bit accumulator for address sums
              BEQ     :4
              TXA                      ; Not end of line:
              ADC     #8               ; Move one box right
              BRA     :5
:4            TXA                      ; End of line:
              ADC     #$DE8            ; Move one box down and seven left
:5            TAX                      ; Pass back the address
              SEP     #$20             ; and return to 8-bit
              PLA                      ; Recover box index
              INC                      ; next index
              CMP     #64              ; All 64 done?
              BNE     LABELS           ; If not, continue

:6            BIT     $C000            ; Wait for keypress
              BPL     :6
              BIT     $C010

              PLA                      ; Recover border color
              TSB     $C034            ; And set it back to what it was

*** Back to GS/OS
              JSL     $E100A8          ; GS/OS QUIT call
              DA      $2029
              ADRL    :7
:7            DA      0                ; No parameters

*** Draw a bordered box with fill pattern .A(8) at screen address
*** .X(16).
BOX           PHY
              PHX
              PHX
              PHA
              LDA     #$FF
              LDY     #14
:1            STA     $2000,X
              STA     $2C80,X
              INX
              DEY
              BNE     :1
              LDA     #19
              PHA
:LINE         REP     #$21
              MX      %00
              LDA     3,S
              ADC     #160
              STA     3,S
              TAX
              SEP     #$20
              MX      %10
              LDA     #$FF
              STA     $2000,X
              STA     $200D,X
              LDA     2,S
              INX
              LDY     #$0C
:2            STA     $2000,X
              INX
              DEY
              BNE     :2
              LDA     1,S
              DEC     A
              STA     1,S
              BNE     :LINE
              PLA
              PLA
              PLX
              PLX
              PLY
              RTS

**********************************************************************
*     Text drawing routines
**********************************************************************
              DUM     0
ROW_COUNT     DFB     0
CHAR_ROW      DFB     0
STR_PTR       DS      3
              DEND

DRAWSTR_80    PHY
              STY     STR_PTR
              PHK                      ; String pointers are in the program bank
              PLA
              STA     STR_PTR+2
              LDY     #$0000
:1            LDA     [STR_PTR],Y
              BMI     :DONE
              JSR     DRAWCHAR_80
              INY
              BRA     :1
:DONE         PLY
              RTS

CHARADDR      REP     #$20
              AND     #$FF
              ASL                      ; X = A * 8
              ASL
              ASL
              TAX
              SEP     #$20
              RTS

DRAWCHAR_80   PHX
              PHY
              TXY
              JSR     CHARADDR
              LDA     #$08
              STA     ROW_COUNT
:1            LDAL    FONT,X
              STA     CHAR_ROW
              JSR     :DECODE_BYTE
              JSR     :DECODE_BYTE
              REP     #$20
              TYA
              CLC
              ADC     #158
              TAY
              SEP     #$20
              INX
              DEC     ROW_COUNT
              BNE     :1
              PLY
              PLX
              INX
              INX
              RTS
:DECODE_BYTE  LDA     #$00
              ASL     CHAR_ROW
              BCC     :2
              ORA     #$C0
:2            ASL     CHAR_ROW
              BCC     :3
              ORA     #$30
:3            ASL     CHAR_ROW
              BCC     :4
              ORA     #$0C
:4            ASL     CHAR_ROW
              BCC     :5
              ORA     #$03
:5            STA     $2000,Y
              INY
              RTS

DRAWCHAR_40   PHX
              PHY
              TXY
              JSR     CHARADDR
              LDA     #$08
              STA     ROW_COUNT
:1            LDAL    FONT,X
              STA     CHAR_ROW
              JSR     :DECODE_BYTE
              JSR     :DECODE_BYTE
              JSR     :DECODE_BYTE
              JSR     :DECODE_BYTE
              REP     #$20
              TYA
              CLC
              ADC     #156
              TAY
              SEP     #$20
              INX
              DEC     ROW_COUNT
              BNE     :1
              PLY
              PLX
              INX
              INX
              INX
              INX
              RTS
:DECODE_BYTE  LDA     #$FF
              ASL     CHAR_ROW
              BCC     :2
              AND     #$0F
:2            ASL     CHAR_ROW
              BCC     :3
              AND     #$F0
:3            PHA
              AND     $2000,Y
              STA     $2000,Y
              PLA
              EOR     #$FF
              AND     #$EE
              ORA     $2000,Y
              STA     $2000,Y
              INY
              RTS

TOHEX         CLC
              ADC     #$30
              CMP     #$3A
              BCC     :1
              SBC     #$39
:1            RTS

*** Palette 0: For our 640x480 mode, black-red-green-white
PALETTES      DA      $0000,$0F00,$00F0,$0FFF,$0000,$0F00,$00F0,$0FFF
              DA      $0000,$0F00,$00F0,$0FFF,$0000,$0F00,$00F0,$0FFF
*** Palettes 1-8: The full EGA palette, in order, in indices
*** 1-8 in each palette. Color 0 is always black and 15 is
*** always 75% gray.
              DA      $0000,$0000,$000A,$00A0,$00AA,$0A00,$0A0A,$0AA0
              DA      $0AAA,$0000,$0000,$0000,$0000,$0000,$0FFF,$0CCC
              DA      $0000,$0005,$000F,$00A5,$00AF,$0A05,$0A0F,$0AA5
              DA      $0AAF,$0000,$0000,$0000,$0000,$0000,$0DDE,$0CCC
              DA      $0000,$0050,$005A,$00F0,$00FA,$0A50,$0A5A,$0AF0
              DA      $0AFA,$0000,$0000,$0000,$0000,$0000,$0BBD,$0CCC
              DA      $0000,$0055,$005F,$00F5,$00FF,$0A55,$0A5F,$0AF5
              DA      $0AFF,$0000,$0000,$0000,$0000,$0000,$099C,$0CCC
              DA      $0000,$0500,$050A,$05A0,$05AA,$0F00,$0F0A,$0FA0
              DA      $0FAA,$0000,$0000,$0000,$0000,$0000,$077B,$0CCC
              DA      $0000,$0505,$050F,$05A5,$05AF,$0F05,$0F0F,$0FA5
              DA      $0FAF,$0000,$0000,$0000,$0000,$0000,$055A,$0CCC
              DA      $0000,$0550,$055A,$05F0,$05FA,$0F50,$0F5A,$0FF0
              DA      $0FFA,$0000,$0000,$0000,$0000,$0000,$0339,$0CCC
              DA      $0000,$0555,$055F,$05F5,$05FF,$0F55,$0F5F,$0FF5
              DA      $0FFF,$0000,$0000,$0000,$0000,$0000,$011E,$0CCC

HEADER        INV     'FLEXING ON IBM PC GRAPHICS IN 1986 WHILE WE STILL CAN'
              DFB     255
FOOTER        INV     '80-COLUMN TEXT WITH ALL 64 EGA COLORS!!!'
              DFB     255

*** Font table. This is uses C64 screen code order, but by a happy
*** coincidence, that happens to perfectly match Apple II inverse
*** text order, so the INV directive will handle any conversions.
FONT          PUTBIN  sinestra.bin
