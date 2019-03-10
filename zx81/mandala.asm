;;; --------------------------------------------------------------------------
;;;   MANDALA CHECKERS/CHOPPER CHECKERS
;;;
;;;   Inspired and informed by the programs of the same name in "51 Game
;;;   Programs for the Timex Sinclair 1000 and 1500", Tim Hartnell, 1982
;;;
;;;   Redesigned and implemented by Michael Martin, 2019
;;; --------------------------------------------------------------------------
        org     $4090

        ;; ROM routines and locations
        defc    KEYBOARD=$02bb          ; Scan keyboard
        defc    DECODE=$07bd            ; Convert scancode to character
        defc    LOCADDR=$0918           ; Set cursor location
        defc    CLS=$0a2a               ; Clear screen

        ;; Skip the page-sensitive data block
        jr      main
;;; --------------------------------------------------------------------------
;;;   PAGE-SENSITIVE DATA BLOCK
;;;
;;;   These arrays need to be indexed arbitrarily, and the code that does so
;;;   ignores carry bits. As a result, these arrays must not cross page
;;;   boundaries. They are 96 bytes and are stored at $4092, so this is fine.
;;; --------------------------------------------------------------------------
        ;; Tile graphics for the two game modes
mandala_tiles:
        defb    0,0,130,129,2,1,136,136
        defb    0,0,7,132,135,4,136,136
chopper_tiles:
        defb    0,0,132,7,134,6,136,136
        defb    0,0,129,130,6,134,136,136

        ;; 8x8 board, stored in row-major order.
board:
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        defb    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;;; --------------------------------------------------------------------------
;;;   main: Main program loop.
;;; --------------------------------------------------------------------------
main:
        call    init
        call    human_move
        call    draw
        ret

;;; --------------------------------------------------------------------------
;;;   init: User sets game mode, and the board, score, and graphics tiles are
;;;         all initialized appropriately.
;;;
;;;   OUTPUT: modifies instructions within its own code and within the "draw"
;;;           routine to represent changes in game mode.
;;;   TRASHES: ABCDEHL
;;;   DEPENDENCIES: Falls through to "draw". Do not define any functions
;;;                 between "init" and "draw".
;;; --------------------------------------------------------------------------

init:   call    CLS
        ld      hl, mode_select_msg
        call    print_at
modelp: call    get_key
        cp      a, 29                   ; Selected (1)?
        jr      z, gotmode_0
        cp      a, 30                   ; Selected (2)?
        jr      nz, modelp
        ;; Selected (2)
        ld      de, chopper_init
        ld      hl, chopper_tiles
        jr      mode_done
gotmode_0:
        ;; Selected (1)
        ld      de, mandala_init
        ld      hl, mandala_tiles
mode_done:
        ld      (mode_0+1), de
        ld      (mode_1+1), hl
        call    CLS
        ld      hl, board
mode_0: ld      de, mandala_init
        ld      a,$1c                   ; Character for "0"
        ld      (human_score),a
        ld      (computer_score),a
        ld      c, 16
init_0: ld      b, 4
        ld      a,(de)
init_1: push    af
        and     a, 3
        add     a, a
        ld      (hl),a
        pop     af
        inc     hl
        srl     a
        srl     a
        djnz    init_1
        inc     de
        dec     c
        jr      nz, init_0
        ;; Fall through to draw

;;; --------------------------------------------------------------------------
;;;   draw: Display board and score
;;;   TRASHES: ABCDEHL
;;; --------------------------------------------------------------------------

draw:   ld      hl,scores_msg
        call    print_at
        ;; Printing the scores also homes the cursor, so we're ready
        ;; to print the board
        call    draw_letter_bar
        call    draw_bar
        ld      hl, board
        ld      c, 8
draw_0: ld      a,156                   ; CODE "[0]"
        add     c
        rst     $10
        push    af
        ld      a, 128
        rst     $10
draw_1: ld      b, 8
draw_2: ld      a, (tile_offset)
        add     a, (hl)
        inc     hl
mode_1: ld      de, mandala_tiles
        add     a,e
        ld      e,a
        ld      a, (de)
        rst     $10
        inc     de
        ld      a, (de)
        rst     $10
        djnz    draw_2
        ld      a, (tile_offset)
        xor     a, 8
        ld      (tile_offset), a
        jr      nz, draw_3
        ;; Prepare for second character row in this board row
        ld      a,128
        rst     $10
        pop     af
        rst     $10
        ld      a,$76
        rst     $10
        ld      a,128
        rst     $10
        rst     $10
        ld      a,l
        sub     a,8
        ld      l,a
        jr      draw_1
draw_3: ld      a,128
        rst     $10
        rst     $10
        ld      a,$76
        rst     $10
        dec     c
        jr      nz, draw_0
        call    draw_bar
        ;; Fall through to draw_letter_bar
draw_letter_bar:
        ld      a,128
        rst     $10
        rst     $10
        ld      b,8
draw_letter_bar_0:
        rst     $10
        ld      a,174                    ; CODE "[I]"
        sub     b
        rst     $10
        ld      a,128
        djnz    draw_letter_bar_0
        rst     $10
        rst     $10
        ld      a,$76
        rst     $10
        ret
draw_bar:
        ld      b, 20
        ld      a, 128
draw_bar_0:
        rst $10
        djnz    draw_bar_0
        ld      a, $76
        rst     $10
        ret

;;; --------------------------------------------------------------------------
;;;   human_move: Execute the human player's turn
;;; --------------------------------------------------------------------------

human_move:
        ld      hl,move_prompt_msg
        call    print_at
        call    parse_square
        ld      b,a
        call    read_square             ; Source square our piece?
        cp      2
        jr      nz,human_move
        push    bc
        ld      a,22                    ; CODE "-"
        rst     $10
        call    parse_square
        pop     bc
        ld      c,a
        call    read_square             ; Target square blank?
        and     a,a
        jr      nz,human_move
        ;; Initial brain-dead implementation: no validity checking
        ld      a,c
        call    read_square
        ld      (hl),2
        ld      a,board & 255
        add     b
        ld      l,a
        ld      (hl),0
        ld      a,b
        sub     c
        jr      nc,human_move_0
        neg
human_move_0:
        cp      a,7
        ret     z
        cp      a,9
        ret     z
        ld      a,b
        add     c
        srl     a
        add     a,board & 255
        ld      l,a
        ld      (hl),0
        ld      hl,human_score
        inc     (hl)
        ret

;;; --------------------------------------------------------------------------
;;;   parse_square: Read and echo a board location from the keyboard
;;;     RETURNS: board index in A
;;;     TRASHES: BCDEHL
;;; --------------------------------------------------------------------------

parse_square:
        call    get_key
        cp      a,38                    ; CODE "A"
        jr      c,parse_square
        cp      a,46                    ; CODE "I"
        jr      nc,parse_square
        rst     $10
        sub     38
        ld      b,a
        push    bc
parse_square_0:
        call    get_key
        cp      a,29                    ; CODE "1"
        jr      c,parse_square_0
        cp      a,37                    ; CODE "9"
        jr      nc,parse_square_0
        rst     $10
        neg
        add     36
        add     a,a
        add     a,a
        add     a,a
        pop     bc
        or      b
        ret

;;; --------------------------------------------------------------------------
;;;   read_square: Locate and check a position on the board
;;;    ARGUMENT: A holds the index to read.
;;;    OUTPUT:   A holds the value at that square.
;;;              HL holds the address of that square.
;;; --------------------------------------------------------------------------
read_square:
        ld      h,board >> 8
        add     a,board & 255
        ld      l,a
        ld      a,(hl)
        ret

;;; --------------------------------------------------------------------------
;;;   print:    Output a string
;;;   print_at: Output a string at a named screen location
;;;
;;;   ARGUMENT: String in HL. When calling print_at, the first two bytes of
;;;             the string are the location code in a format acceptable to
;;;             the LOCADDR routine: first byte is ($21-column), second byte
;;;             is ($18-row). The cursor may be repositioned mid-string with
;;;             an $FE byte followed by a new two-byte location code. The
;;;             string is terminated with $FF.
;;;   TRASHES:  ABCDEHL. A will always be $FF, and HL will point just past
;;;             the string that was printed.
;;; --------------------------------------------------------------------------

print_at:
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        push    hl
        call    LOCADDR
        pop     hl
print:  ;; Entry point if we don't start with a relocate
        ld      a,(hl)
        inc     hl
        cp      a,$ff
        ret     z
        cp      a,$fe
        jr      z,print_at
        rst     $10
        jr      print

;;; --------------------------------------------------------------------------
;;;   get_key: Blocking read from keyboard
;;;
;;;   RETURNS: Character code in A
;;;   TRASHES: BCDEHL
;;; --------------------------------------------------------------------------
get_key:
        call    KEYBOARD
        inc     l
        jr      nz, get_key
gk_0:   call    KEYBOARD
        inc     l
        jr      z, gk_0
        dec     l
        ld      b, h
        ld      c, l
        call    DECODE
        ld      a, (hl)
        ret

;;; --------------------------------------------------------------------------
;;;   DATA BLOCK
;;; --------------------------------------------------------------------------

        ;; Tertiary loop variable for "draw" routine
tile_offset:
        defb    8

        ;; Initial board state for Mandala and Chopper
mandala_init:
        defb    $ee,$ce,$bb,$33,$ee,$cc,$3b,$73
        defb    $ce,$dc,$33,$77,$cc,$dd,$73,$77
chopper_init:
        defb    $ee,$ee,$bb,$bb,$ee,$ee,$33,$33
        defb    $cc,$cc,$77,$77,$dd,$dd,$77,$77

        ;; Opening prompt for mode select
mode_select_msg:
        defb    $19,$14,$38,$2a,$31,$2a,$28,$39,$00,$2c,$26,$32,$2a,$00,$32
        defb    $34,$29,$2a,$fe,$1b,$0c,$10,$1d,$11,$00,$32,$26,$33,$29,$26
        defb    $31,$26,$00,$28,$2d,$2a,$28,$30,$2a,$37,$38,$fe,$1b,$0a,$10
        defb    $1e,$11,$00,$28,$2d,$34,$35,$35,$2a,$37,$00,$28,$2d,$2a,$28
        defb    $30,$2a,$37,$38,$ff

        ;; Score display. Includes the actual score variables, which are
        ;; updated as the game proceeds. Cursor is homed after the score is
        ;; printed out.
scores_msg:
        defb    $0c,$18,$2d,$3a,$32,$26,$33,$0e,$fe,$02,$18
human_score:
        defb    $1c,$fe,$0c,$16,$28,$34,$32,$35,$3a,$39,$2a,$37,$0e,$00
computer_score:
        defb    $1c,$fe,$21,$18,$ff

        ;; Human move prompt
move_prompt_msg:
        defb    $0c,$0d,$3e,$34,$3a,$37,$00,$32,$34,$3b,$2a,$0f,$fe,$0a,$0c
        defb    $00,$00,$00,$00,$00,$fe,$0a,$0c,$ff
