;;; --------------------------------------------------------------------------
;;;   MANDALA CHECKERS/CHOPPER CHECKERS
;;;
;;;   Inspired and informed by the programs of the same name in "51 Game
;;;   Programs for the Timex Sinclair 1000 and 1500", Tim Hartnell, 1982
;;;
;;;   Redesigned and implemented by Michael Martin, 2019
;;; --------------------------------------------------------------------------
        org     $4090

        ;; ROM routines
KEYBOARD equ    $02bb          ; Scan keyboard
DECODE  equ     $07bd            ; Convert scancode to character
LOCADDR equ     $0918           ; Set cursor location
CLS     equ     $0a2a               ; Clear screen

        ;; System variables
FRAMES  equ     $4034            ; Frame count to seed RNG

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
main_lp:
        call    human_move
        call    draw
        call    check_game_over
        jr      z,game_over
        call    computer_move
        call    draw
        call    check_game_over
        jr      nz,main_lp
game_over:
        ld      hl,win_suffix_msg
        call    print
game_over_lp:
        call    get_key
        cp      a,$3E                   ; CODE "Y"
        jr      z,main
        cp      a,$33                   ; CODE "N"
        jr      nz,game_over_lp
        call    CLS
        ret

check_game_over:
        ld      a,(human_score)
        cp      $23                     ; CODE "7"
        jr      nz,check_game_over_0
        ld      hl,human_wins_msg
        jr      check_game_over_1
check_game_over_0:
        ld      a,(computer_score)
        cp      $23                     ; CODE "7"
        ret     nz
        ld      hl,computer_wins_msg
check_game_over_1:
        call    print_at
        xor     a                       ; Set zero flag
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
        ;; Seed RNG
        ld      hl,(FRAMES)
        ld      a,l
        or      1
        ld      l,a
        ld      (rnd_x),hl
        ld      (rnd_y),hl
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
;;;     TRASHES: ABCDEHL
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
        call    execute_move
        jr      nz,human_move           ; If it was illegal, go back!
        ret     nc                      ; If it wasn't a capture, done
        ld      hl,human_score          ; If it was, give a point
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
        add     36                      ; CODE "8"
        add     a,a
        add     a,a
        add     a,a
        pop     bc
        or      b
        ret

;;; --------------------------------------------------------------------------
;;;   computer_tell_move: Display the computer's move
;;;     ARGUMENT: B holds the starting index
;;;               C holds the ending index
;;;      TRASHES: ADEHL
;;; --------------------------------------------------------------------------

computer_tell_move:
        push    bc
        ld      hl,computer_move_msg
        call    print_at
        pop     bc
        ld      a,b
        call    computer_tell_one_move
        ld      a,22                    ; CODE "-"
        rst     $10
        ld      a,c
        ;; Fall through into computer-tell-one-move

computer_tell_one_move:
        push    af
        and     a,7
        add     a,38                    ; CODE "A"
        rst     $10
        pop     af
        ;; Rotating A is shorter and faster than shifting it
        rrca
        rrca
        rrca
        and     a,7
        neg
        add     36                      ; CODE "8"
        rst     $10
        ret

;;; --------------------------------------------------------------------------
;;;   computer_move: Generate and execute a computer move. If the computer
;;;                  has stalemated, it sets the player score to 7.
;;;     TRASHES: ABCDEHL
;;; --------------------------------------------------------------------------
computer_move:
        ;; Look for a capture move, systematically
        ld      b,64
computer_move_0:
        dec     b
        ld      a,b
        call    read_square
        cp      4
        jr      nz, computer_move_1     ; Not our piece
        ld      hl,move_priorities
        ld      e,4
        call    attempt_move_from
        jr      z, computer_move_3      ; Success!
computer_move_1:
        xor     a
        or      b
        jr      nz, computer_move_0
        ;; Look for a noncapture move with a flailing random search
        ld      d,0
computer_move_2:
        call    rnd
        ld      a,l
        and     63
        ld      b,a
        call    read_square
        cp      4
        jr      nz,computer_move_2
        ld      hl,move_priorities
        ld      e,8
        call    attempt_move_from
        jr      z, computer_move_3
        ;; Couldn't move that piece, find another
        dec     d
        jr      nz,computer_move_2
        ;; Couldn't move pieces after 256 tries! Concede the game
        ld      a,35                    ; CODE "7"
        ld      (human_score),a
        ld      hl,computer_concedes_msg
        jr      print_at
computer_move_3:
        push    af
        call    computer_tell_move
        pop     af
        ret     nc
        ld      hl,computer_score
        inc     (hl)
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
;;;   is_legal_move: Check a potential move for legality
;;;    ARGUMENT: B = offset of source square
;;;              C = offset of destination square
;;;    OUTPUT:   Zero flag set if move is legal
;;;              Carry flag set if move is a capture
;;;    TRASHES:  AHL
;;;    PRECONDITIONS: B must be in the range 0-63 and refer to a square that
;;;                   has one of the active player's pieces in it.
;;; --------------------------------------------------------------------------

is_legal_move:
        ;; First ensure the destination is in bounds
        ld      c,a
        cp      64
        jr      c,is_legal_move_0
        xor     a                       ; Failure! But Z could be either set
        cp      1                       ; or not, so force it off before
        ret                             ; returning
is_legal_move_0:
        ;; Destination blank?
        call    read_square
        and     a,a
        ret     nz                      ; If not, fail
        ;; Non-capture move?
        ld      a,b
        sub     c
        jr      nc,is_legal_move_1
        neg
is_legal_move_1:                        ; A is now ABS(B-C)
        cp      a,7
        jr      z, is_legal_move_2
        cp      a,9
        jr      nz, is_legal_move_3
is_legal_move_2:
        ;; Legal non-capture move. Zero flag is already set, so just need to
        ;; clear the carry flag
        scf
        ccf
        ret
is_legal_move_3:
        ;; Now check for capture moves
        cp      a,14
        jr      z,is_legal_move_4
        cp      a,18
        ret     nz                      ; Wasn't a 1-or-2 square move!
is_legal_move_4:
        ;; 2-square move. Confirm enemy piece is in the middle.
        ld      a,b                     ; Check source piece
        call    read_square
        push    de
        neg                             ; Flip player value
        add     6
        ld      d,a
        ld      a,b                     ; Compute intermediate square
        add     c
        srl     a
        call    read_square             ; Read it
        cp      d                       ; Is it opposing player value?
        pop     de                      ;  (restore value; no flag changes)
        ret     nz                      ; Fail if it wasn't a valid jump!
        ;; Valid capture move. Z is set by "cp d", so set carry and exit.
        scf
        ret

;;; --------------------------------------------------------------------------
;;;   execute_move: Attempt a move, failing if it is illegal
;;;    ARGUMENT: B = offset of source square
;;;              C = offset of destination square
;;;    OUTPUT:   Zero flag set if move was legal
;;;              Carry flag set if move was a capture
;;;              Board array is updated if move was legal
;;;    TRASHES:  AHL
;;;    PRECONDITIONS: B must be in the range 0-63 and refer to a square that
;;;                   has one of the active player's pieces in it.
;;; --------------------------------------------------------------------------

execute_move:
        ;; Quit right away if this was an illegal move
        call    is_legal_move
        ret     nz
        push    af                      ; Remember flags for later
        jr      nc, execute_move_0      ; Skip capture step for noncaptures
        ld      a,b
        add     c
        srl     a
        call    read_square             ; Clear captured square
        ld      (hl),0
execute_move_0:
        ld      a,b
        call    read_square
        ld      (hl),0
        push    af                      ; Save identity of moved piece
        ld      a,c
        call    read_square
        pop     af
        ld      (hl),a                  ; Put it at destination
        pop     af                      ; Restore Z and C flags
        ret

;;; --------------------------------------------------------------------------
;;;   attempt_move_from: Look for valid moves from a source square
;;;    ARGUMENT: B  = offset of source square
;;;              E  = length of potential move array
;;;              HL = address of potential move array
;;;    OUTPUT:   Zero flag set if move was legal
;;;              Carry flag set if move was a capture
;;;              C  = offset of destination square of target move
;;;    TRASHES:  AHL
;;;    PRECONDITIONS: B must be in the range 0-63 and refer to a square that
;;;                   has one of the active player's pieces in it.
;;; --------------------------------------------------------------------------

attempt_move_from:
        ld      a,b
        add     (hl)
        ld      c,a
        push    hl
        call    execute_move
        pop     hl
        ret     z
        inc     hl
        dec     e
        jr      nz,attempt_move_from
        ;; Failed. Force zero flag off before returning to indicate failure.
        ld      a,1
        and     a,a
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
gk_0:   call    rnd                     ; Advance RNG while you wait
        call    KEYBOARD
        inc     l
        jr      z, gk_0
        dec     l
        ld      b, h
        ld      c, l
        call    DECODE
        ld      a, (hl)
        ret

        include "xorshift.asm"

;;; --------------------------------------------------------------------------
;;;   DATA BLOCK
;;; --------------------------------------------------------------------------

        ;; Tertiary loop variable for "draw" routine
tile_offset:
        defb    8

        ;; Move priorities for AI: SE-SW-NE-NW, capture over non-capture
move_priorities:
        defb    $12,$0e,$f2,$ee,$09,$07,$f9,$f7

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

        ;; Computer move report
computer_move_msg:
        defb    $0b,$10,$32,$3e,$00,$32,$34,$3b,$2a,$0e,$fe,$0a,$0f,$ff

        ;; Human wins
human_wins_msg:
        defb    $1e,$02,$3e,$34,$3a,$ff

        ;; Computer wins
computer_wins_msg:
        defb    $1d,$02,$2e,$ff

        ;; Computer concedes
computer_concedes_msg:
        defb    $1a,$03,$2e,$00,$28,$34,$33,$28,$2a,$29,$2a,$00,$39,$2d,$2a
        defb    $00,$2c,$26,$32,$2a,$ff

        ;; Play again?
win_suffix_msg:
        defb    $00,$3c,$2e,$33,$0e,$00,$35,$31,$26,$3e,$00,$26,$2c,$26,$2e
        defb    $33,$00,$10,$3e,$18,$33,$11,$0f,$ff
