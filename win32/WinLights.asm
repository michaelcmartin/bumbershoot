;;; ----------------------------------------------------------------------
;;;    Lights-Out: Win32 edition
;;;    Copyright (c) 2019, Michael Martin / Bumbershoot Software.
;;;    Available under the MIT License.
;;;
;;;    This program is designed to be self-contained and to talk directly
;;;    To the Win32 routines without going through any language runtime.
;;;
;;;    This is normally not something you'd want to do, and if you *did*,
;;;    you'd do it with C and linking with /nodefaultlib, but this
;;;    repository is all about doing things at a lower level than is
;;;    strictly wise. Let's get to it!
;;; ----------------------------------------------------------------------

	cpu	386
	bits	32

;;; ----------------------------------------------------------------------
;;;   Structure and constant definitions
;;;   These have either been lifted from Win32.inc by Tamas Kaproncai or
;;;   extracted from Windows.h by interrogating it with the sizeof and
;;;   offsetof macros.
;;; ----------------------------------------------------------------------

STRUC WNDCLASSEX
	.cbSize		resd	1
	.style		resd	1
	.lpfnWndProc	resd	1
	.cbClsExtra	resd	1
	.cbWndExtra	resd	1
	.hInstance	resd	1
	.hIcon		resd	1
	.hCursor	resd	1
	.hbrBackground	resd	1
	.lpszMenuName	resd	1
	.lpszClassName	resd	1
	.hIconSm	resd	1
ENDSTRUC

STRUC POINT
	.x		resd	1
	.y		resd	1
ENDSTRUC

STRUC MINMAXINFO
	.ptReserved	resb	POINT_size
	.ptMaxSize	resb	POINT_size
	.ptMaxPosition	resb	POINT_size
	.ptMinTrackSize	resb	POINT_size
	.ptMaxTrackSize	resb	POINT_size
ENDSTRUC

STRUC MSG
	.hWnd		resd	1
	.message	resd	1
	.wParam		resd	1
	.lParam		resd	1
	.time		resd	1
	.pt		resb	POINT_size
ENDSTRUC

STRUC RECT
	.left		resd	1
	.top		resd	1
	.right		resd	1
	.bottom		resd	1
ENDSTRUC

STRUC PAINTSTRUCT
	.hdc		resd	1
	.fErase		resd	1
	.rcPaint	resb	RECT_size
	.fRestore	resd	1
	.fIncUpdate	resd	1
	.rgbReserved	resb	32
ENDSTRUC

	BLACK_PEN	equ	7
	COLOR_WINDOW	equ	5
	CS_VREDRAW	equ	1
	CS_HREDRAW	equ	2
	DC_BRUSH	equ	18
	IDC_ARROW	equ	32512
	IDM_NEW		equ	0x0101
	IDM_QUIT	equ	0x0102
	IDYES		equ	6
	MB_YESNO	equ	4
	MF_POPUP	equ	0x0010
	MF_SEPARATOR	equ	0x0800
	SW_SHOWDEFAULT	equ	10
	VK_F2		equ	0x71
	WM_COMMAND	equ	0x0111
	WM_DESTROY	equ	0x02
	WM_GETMINMAXINFO equ	0x24
	WM_LBUTTONDOWN	equ	0x0201
	WM_PAINT	equ	0x0F
	WM_QUIT		equ	0x12
	WS_OVERLAPPEDWINDOW equ	0x0CF0000
	WS_CLIPCHILDREN	equ	0x2000000

;;; ----------------------------------------------------------------------
;;;   Exports
;;; ----------------------------------------------------------------------
	GLOBAL	_start

;;; ----------------------------------------------------------------------
;;;   Imports
;;; ----------------------------------------------------------------------

	;; kernel32.lib
	EXTERN	_ExitProcess@4, _GetModuleHandleA@4, _GetTickCount@0

	;; user32.lib
	EXTERN	_AppendMenuA@16, _BeginPaint@8, _CreateAcceleratorTableA@8
	EXTERN	_CreateMenu@0, _CreateWindowExA@48, _DefWindowProcA@16
	EXTERN	_DestroyAcceleratorTable@4, _DispatchMessageA@4
	EXTERN	_DrawMenuBar@4, _EndPaint@8, _GetClientRect@8, _GetMessageA@16
	EXTERN	_InvalidateRect@12, _LoadCursorA@8, _LoadIconA@8
	EXTERN	_MessageBoxA@16, _PostQuitMessage@4, _RegisterClassExA@4
	EXTERN	_SetMenu@8, _ShowWindow@8, _TranslateAcceleratorA@12
	EXTERN	_TranslateMessage@4

	;; gdi32.lib
	EXTERN	_Ellipse@20, _GetStockObject@4, _SelectObject@8
	EXTERN	_SetDCBrushColor@8

;;; ----------------------------------------------------------------------
;;;   Main Program
;;; ----------------------------------------------------------------------

	section	.text
_start:	call	_GetTickCount@0
	push	eax
	call	seedRand32
	call	initPuzzle

	sub	esp, WNDCLASSEX_size	; Reserve space for window class
	mov	ebx, esp		; And store a pointer to it
	mov	edi, ebx		; And zero it out
	xor	eax, eax
	xor	ecx, ecx
	mov	cl, WNDCLASSEX_size
	rep	stosb
	;; Now create the window and its class
	xor	esi, esi		; We'll be using a lot of zeroes here
	push	dword SW_SHOWDEFAULT	; Last arg to ShowWindow, later
	push	esi			; Last arg to CreateWindowEx (lpParam)
	push	esi			; Arg to GetModuleHandle(0)
	call	_GetModuleHandleA@4	; EAX = our app's HINSTANCE
	push	eax			; ... used as arg to CreateWindowEx
	push	esi			; CreateWindowEx: no menu
	push	esi			; CreateWindowEx: no parent window
	mov	edx, 425		; CreateWindowEx: 425x425 by default
	push	edx
	push	edx
	mov	edx, 150		; CreateWindowEx: at (150,150) default
	push	edx
	push	edx
	push	dword WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN
	push	windowCaption
	;; Now we need the Window Class Atom, which we'll need to register.
	;; This function takes a structure, so we'll fill out the space we
	;; allocated previously with that structure. The pointer to that
	;; structure is still in EBX. EAX also still holds our application's
	;; HINSTANCE. We'll be reusing that here too.
	mov	dword [ebx+WNDCLASSEX.cbSize], WNDCLASSEX_size
	mov	dword [ebx+WNDCLASSEX.style], CS_HREDRAW | CS_VREDRAW
	mov	dword [ebx+WNDCLASSEX.lpfnWndProc], wndProc
	mov	[ebx+WNDCLASSEX.hInstance], eax
	push	dword 1			; Argument to LoadIconA (res 1)
	push	eax			; hInstance for LoadIconA
	call	_LoadIconA@8		; EAX now the HICON
	mov	[ebx+WNDCLASSEX.hIcon], eax
	push	dword IDC_ARROW		; Argument to LoadCursor
	push	esi
	call	_LoadCursorA@8		; EAX now the HCURSOR
	mov	[ebx+WNDCLASSEX.hCursor], eax
	mov	dword [ebx+WNDCLASSEX.hbrBackground], COLOR_WINDOW+1
	mov	dword [ebx+WNDCLASSEX.lpszClassName], classNameString
	push	ebx			; Push apibuf ptr to stack
	call	_RegisterClassExA@4	; ... and register the class
	push	eax			; Push retval as atom to register
	push	esi			; No ExStyle
	call	_CreateWindowExA@48
	mov	esi, eax
	push	eax
	push	eax
	call	setupMenu		; Consumes first hWnd
	call	setupAccelerators	; Consumes nothing
	mov	edi, eax		; Save off accel table
	call	_ShowWindow@8

	;; Main event loop. ESI=hWnd, EDI=hAccelTable, EBX=pMsg
mainlp:	xor	eax, eax
	push	eax
	push	eax
	push	eax
	push	ebx			; Reuse the window class arg for msgs
	call	_GetMessageA@16
	or	eax, eax		; Is the result >= 0?
	jl	finis			; If not, something went wrong, quit
	push	ebx			; Was this an accelerator command?
	push	edi
	push	esi
	call	_TranslateAcceleratorA@12
	or	eax, eax		; If it was, proceed back to the
	jne	mainlp			;    main loop
	push	ebx
	call	_TranslateMessage@4
	push	ebx
	call	_DispatchMessageA@4
	mov	eax, dword [ebx+MSG.message]
	cmp	eax, WM_QUIT		; Was this a quit message?
	je	finis			; If so, we're done
	mov	al, [gameState]		; Did we win?
	cmp	al, 1
	jne	mainlp			; If not, back to event loop
	inc	byte [gameState]	; gameState to 2 (idle)
	push	dword MB_YESNO		; Display a win message
	push	dword windowCaption
	push	dword winStr
	push	esi
	call	_MessageBoxA@16
	cmp	eax, IDYES		; Did they say "Yes"?
	jne	mainlp			; If not, stay idle
	call	initPuzzle		; If so, do an immediate new puzzle
	xor	eax, eax		; And then repaint the window
	push	eax			; bErase = FALSE
	push	eax			; lpRect = NULL
	push	esi			; hWnd = hWnd
	call	_InvalidateRect@12
	jmp	mainlp

	;; End of main program.
finis:	mov	eax, dword [ebx+MSG.wParam]
	push	eax			; Forward retcode from quit msg
	;; Destroy our accelerator table on the way out
	push	edi
	call	_DestroyAcceleratorTable@4
	call	_ExitProcess@4

;;; ----------------------------------------------------------------------
;;;   Window Message Handler
;;; ----------------------------------------------------------------------

wndProc:
	push	ebp
	mov	ebp, esp
	mov	eax, [ebp+12]		; Load message into EAX
	cmp	eax, WM_DESTROY		; Check for messages we know about
	je	.destroy
	cmp	eax, WM_PAINT
	je	.paint
	cmp	eax, WM_LBUTTONDOWN
	je	.lbuttondown
	cmp	eax, WM_COMMAND
	je	.command
	cmp	eax, WM_GETMINMAXINFO
	je	.getminmaxinfo
	;; Otherwise we don't know what it is, so tailcall to default.
	mov	esp, ebp
	pop	ebp
	jmp	_DefWindowProcA@16
.command:
	movsx	eax, word [ebp+16]	; command code
	cmp	eax, IDM_NEW
	jne	.notnew
	call	initPuzzle
	jmp	.repaint
.notnew:
	cmp	eax, IDM_QUIT
	jne	.fin
	;; Otherwise fall through to .destroy
.destroy:
	xor	eax, eax		; Return code 0
	call	_PostQuitMessage@4	; ... and post a proper quit message
	jmp	.fin
.getminmaxinfo:
	mov	edx, [ebp+20]		; MINMAXINFO structure in lParam
	mov	eax, 200		; The minimum width and height
	mov	[edx+MINMAXINFO.ptMinTrackSize+POINT.x], eax
	mov	[edx+MINMAXINFO.ptMinTrackSize+POINT.y], eax
	jmp	.fin
.paint:	sub	esp, PAINTSTRUCT_size
	mov	edx, esp
	push	ebx			; EBX will hold HDC, save orig value
	push	edx
	push	dword [ebp+8]
	call	_BeginPaint@8
	mov	ebx, eax
	;; Now draw the grid
	push	dword [boardState]
	sub	esp, 16			; Space for board geometry
	push	dword [ebp+8]		; hWnd
	call	size_board		; Fills x/y/size/stride, consumes hWnd
	call	paint_grid

	;; Restore EBX and end painting
	pop	ebx
	mov	edx, esp
	push	edx
	push	dword [ebp+8]
	call	_EndPaint@8
	jmp	.fin
.lbuttondown:
	;; Ignore clicks if not in main game state
	mov	al, [gameState]
	or	al, al
	jnz	.fin
	xor	eax, eax
	movsx	eax, word [ebp+22]	; Y
	push	eax
	movsx	eax, word [ebp+20]	; X
	push	eax
	sub	esp, 16			; Space for board geometry
	push	dword [ebp+8]		; hWnd
	call	size_board
	call	hit_test
	or	eax, eax		; Has a cell been clicked?
	jl	.fin			; If not, do nothing
	mov	ecx, [moveTable+4*eax]	; If so, load the move mask...
	mov	eax, [boardState]	; ... and the board...
	xor	eax, ecx		; ... make the move...
	mov	[boardState], eax	; ... store it back...
	or	eax, eax		; ... and see if we've won
	jnz	.repaint		; If not, we're done
	inc	byte [gameState]	; If so, game state from 0 to 1...
					; ... then fall through to repaint
.repaint:
	xor	eax, eax
	push	eax			; bErase = FALSE
	push	eax			; lpRect = NULL
	push	dword [ebp+8]		; hWnd = hWnd
	call	_InvalidateRect@12
	;; Fall through to routine finish
.fin:	xor	eax, eax		; And report success handling the event
	mov	esp, ebp
	pop	ebp
	ret	16

;;; ----------------------------------------------------------------------
;;;   Paint support routines
;;;
;;;   These routines all insist that EBX (which it preserves) holds the
;;;   HDC. The drawing state of the HDC may be mutated by the functions.
;;; ----------------------------------------------------------------------

	;; paint_ellipse(left, top, right, bottom)
	;; A more convenient wrapper around Ellipse that doesn't consume
	;; its arguments. cdecl ABI, with EBX as the HDC.
paint_ellipse:
	xor	ecx, ecx	; Copy four stack elements from args
	mov	cl, 4		; to our own frame
.lp:	mov	eax, [esp+16]	; As we push entries on the stack,
	push	eax		; this reads arguments in succession!
	loop	.lp
	push	ebx		; push HDC...
	call	_Ellipse@20	; and then forward to Ellipse
	ret

	;; paint_grid(left, top, size, stride, gameState)
	;; Draws a five-by-five grid of circles starting at (left, top),
	;; with each circle SIZE pixels in diameter and with their center
	;; points STRIDE apart. stdcall ABI, EBX holds the HDC.
paint_grid:
	push	ebp
	mov	ebp, esp
	;; Cache the original drawing state
	push	dword BLACK_PEN		; Select black pen
	call	_GetStockObject@4
	push	eax
	push	ebx
	call	_SelectObject@8
	push	eax		; Save original pen
	push	dword DC_BRUSH		; Select recolorable brush
	call	_GetStockObject@4
	push	eax
	push	ebx
	call	_SelectObject@8
	push	eax		; Save original brush
	;; Local variables: left, top, right, bottom, col, row
	sub	esp, 24

	;; Initialize 'top' value (left, right, bottom are set at
	;; start of each row)
	mov	eax, [ebp+12]
	mov	[esp+4], eax
	;; Initialize row iterator to 5
	xor	ecx, ecx
	mov	cl, 5
.y_lp:	mov	[esp+20], ecx
	mov	edx, [ebp+16]	; EDX = size
	mov	eax, [ebp+8]	; Reset left
	mov	[esp], eax
	add	eax, edx	; Reset right
	mov	[esp+8], eax
	mov	eax, [esp+4]	; top is set, so reset bottom
	add	eax, edx	; based on it
	mov	[esp+12], eax
	xor	ecx, ecx	; Column iterator to 5
	mov	cl, 5
.x_lp:	mov	[esp+16], ecx
	xor	eax, eax	; Red brush by default
	mov	al, 0xaa
	shr	dword [ebp+24], 1
	jc	.t_set
	mov	eax, 0x555555	; Dark grey brush if cell is off
.t_set:	push	eax
	push	ebx
	call	_SetDCBrushColor@8
	call	paint_ellipse
	mov	edx, [ebp+20]	; EDX = stride
	add	[esp], edx	; Advance left
	add	[esp+8], edx	; Advance right
	mov	ecx, [esp+16]
	loop	.x_lp
	;; One row done, prepare for next. EDX is already stride, so
	;; add that to TOP, and the other three will be fixed at the
	;; head of the loop.
	add	[esp+4], edx
	mov	ecx, [esp+20]
	loop	.y_lp
	;; All rows done. Clean up and ship out.
	add	esp, 24
	push	ebx			; Restore original brush and pen
	call	_SelectObject@8
	push	ebx
	call	_SelectObject@8
	pop	ebp
	ret	20


;;; ----------------------------------------------------------------------
;;;   Other routines
;;; ----------------------------------------------------------------------

	;; setupMenu(HWND hWnd). Creates and initializes the menu used
	;; by hWnd.
setupMenu:
	push	ebx
	call	_CreateMenu@0
	mov	ebx, eax
	push	dword newGameStr
	push	dword IDM_NEW
	xor	eax, eax
	push	eax
	push	ebx
	call	_AppendMenuA@16
	xor	eax, eax
	push	eax
	push	eax
	push	dword MF_SEPARATOR
	push	ebx
	call	_AppendMenuA@16
	push	dword quitStr
	push	dword IDM_QUIT
	xor	eax, eax
	push	eax
	push	ebx
	call	_AppendMenuA@16
	;; We've now created the Game Menu. Now we may create the menu
	;; bar and add it to that.
	call	_CreateMenu@0
	push	eax			; Save result to pass to SetMenu
	push	dword gameMenuStr
	push	ebx
	push	dword MF_POPUP
	push	eax
	call	_AppendMenuA@16
	mov	eax, [esp+12]		; hWnd
	push	eax
	call	_SetMenu@8
	pop	ebx
	jmp	_DrawMenuBar@4		; Tail call to DrawMenuBar

setupAccelerators:
	xor	eax, eax
	inc	eax
	push	eax
	push	dword acceleratorTable
	call	_CreateAcceleratorTableA@8
	ret

	;; size_board(hWnd, out left, out top, out size, out stride)
	;; Consumes only hWnd from stack. Uses hWnd's client rectangle
	;; to give a centered, max-sized board.
size_board:
	push	ebp
	mov	ebp, esp
	lea	eax, [ebp+12]		; Use output area as a RECT
	push	eax
	push	dword [ebp+8]
	call	_GetClientRect@8
	mov	eax, [ebp+20]		; width
	mov	ecx, [ebp+24]		; height
	mov	[ebp+12], eax		; x = width
	mov	[ebp+16], ecx		; y = width
	cmp	eax, ecx		; wider or taller?
	jle	.tallr
	mov	eax, ecx		; eax = min(w, h)
.tallr:	xor	edx, edx
	mov	ecx, 5
	div	ecx
	mov	[ebp+24], eax		; stride = min(w, h)/5
	push	eax			; save two copies
	push	eax
	shl	eax, 2
	xor	edx, edx
	div	ecx
	mov	[ebp+20], eax		; eax = size = stride * 4 / 5
	pop	edx			; edx = stride
	sub	edx, eax		; edx = offset = stride-size
	pop	eax			; eax = stride
	push	edx			; save offset since mul destroys edx
	mul	ecx			; edx = 0, eax = boardsize = stride*5
	pop	edx			; restore edx = offset
	sub	edx, eax		; offset - boardsize
	;; At this point, size and stride are correctly set, and x and y
	;; hold w and h, respectively. To produce the final left/top values
	;; we need to add (offset - boardsize) to them, and then divide the
	;; sum by two.
	add	[ebp+12], edx
	add	[ebp+16], edx
	shr	dword [ebp+12], 1
	shr	dword [ebp+16], 1
	;; We're done. The last four arguments are the return value,
	;; so we only consume hWnd on return.
	mov	esp, ebp
	pop	ebp
	ret	4

	;; hit_test(left, top, size, stride, x, y) -> returns 0-24 if we
	;; have hit a cell, or -1 if no target is hit. stdcall ABI.
hit_test:
	push	ebp
	mov	ebp, esp
	;; Local variables: index, test_top, row
	xor	eax, eax
	push	eax			; row (will be written before read)
	push	dword [ebp+12]		; test_top (= top)
	push	eax			; index (= 0)

	xor	ecx, ecx		; Initialize row loop
	mov	cl, 5
.rowlp:	mov	[esp+8], ecx		; save loop variable
	mov	eax, [ebp+28]		; EAX = y
	sub	eax, [esp+4]		; EAX = point relative to test_top
	jl	.r_no			; If negative, too far up
	cmp	eax, [ebp+16]		; Test againt bottom (test_top+size)
	jle	.r_yes

	;; Y is not in the row; hit is impossible. Advance index by 5 and
	;; skip directly to next row.
.r_no:	add	dword [esp], 5
	jmp	.next

	;; Loop through columns testing X values for a hit
.r_yes:	mov	edx, [ebp+8]		; test_left = left
	xor	ecx, ecx
	mov	cl, 5
.collp:	mov	eax, [ebp+24]		; EAX = x
	sub	eax, edx		; EAX = point relative to cell left
	jl	.c_no			; If negative, too far left
	cmp	eax, dword [ebp+16]	; Check against cell right
	jle	.found
.c_no:	inc	dword [esp]		; Next index
	add	edx, dword [ebp+20]	; Advance test_left by stride
	loop	.collp

	;; No matches this row. Jump to next row.
.next:	mov	eax, [ebp+20]		; EAX = stride...
	add	[esp+4], eax		; ...add stride to test_top
	mov	ecx, [esp+8]		; Restore loop variable
	loop	.rowlp			; and try again

	;; No matches at all. Return -1.
	xor	eax, eax
	dec	eax
	jmp	.fin

	;; Found a match! pop index into EAX as the return value.
.found:	pop	eax
.fin:	mov	esp, ebp
	pop	ebp
	ret	24

	;; void initPuzzle(): advance the PRNG and create a random
	;; puzzle to solve. stdcall ABI.
initPuzzle:
	call	rand32
	mov	edx, eax		; Move list is random
	xor	eax, eax		; Board starts empty
	mov	[gameState], al		; Start in game state 0 too
	xor	ecx, ecx		; 25 bits to read
	mov	cl, 25
.lp:	shr	edx, 1			; Move for each cell if bit is on
	jnc	.end
	xor	eax, [moveTable+4*ecx-4]
.end:	loop	.lp
	;; Pretty darn unlikely, but just in case; did we create the
	;; solved puzzle? If so, try again.
	or	eax, eax
	jz	initPuzzle
	;; Otherwise, we have our puzzle.
	mov	[boardState], eax
	ret

	;; DWORD rand32(): 32-bit Xorshift-Star PRNG. stdcall ABI.
rand32:	push	ebx
	mov	ebx, [rngState]
	mov	ecx, [rngState+4]
	mov	eax, ebx
	mov	edx, ecx
	shrd	eax, edx, 12
	shr	edx, 12
	xor	ebx, eax
	xor	ecx, edx
	mov	eax, ebx
	mov	edx, ecx
	shld	edx, eax, 25
	shl	eax, 25
	xor	ebx, eax
	xor	ecx, edx
	mov	eax, ebx
	mov	edx, ecx
	shrd	eax, edx, 27
	shr	edx, 27
	xor	ebx, eax
	xor	ecx, edx
	mov	[rngState], ebx
	mov	[rngState+4], ecx
	mov	eax, 0x4f6cdd1d
	imul	ecx, eax
	mul	ebx
	add	ecx, edx
	imul	eax, ebx, 0x2545f491
	add	eax, ecx
	pop	ebx
	ret

	;; void seedRand32(DWORD seed): seeds the rand32 PRNG. stdcall ABI.
seedRand32:
	mov	eax, [esp+4]
	mov	[rngState], eax
	mov	[rngState+4], eax
	ret	4

;;; ----------------------------------------------------------------------
;;;   Program data
;;; ----------------------------------------------------------------------

	;; Constants for the window and its class
classNameString:
	db	"WLV",0

windowCaption:
	db	"Lights Out!",0

gameMenuStr:
	db	"&Game",0

newGameStr:
	db	"&New Game",9,"F2",0

quitStr:
	db	"&Quit",0

winStr:
	db	"Congratulations, you win!",13,10,13,10,"Play again?",0

	align	4
moveTable:
	dd	0x0000023, 0x0000047, 0x000008e, 0x000011c, 0x0000218
	dd	0x0000461, 0x00008e2, 0x00011c4, 0x0002388, 0x0004310
	dd	0x0008c20, 0x0011c40, 0x0023880, 0x0047100, 0x0086200
	dd	0x0118400, 0x0238800, 0x0471000, 0x08e2000, 0x10c4000
	dd	0x0308000, 0x0710000, 0x0e20000, 0x1c40000, 0x1880000

acceleratorTable:
	dw	1, VK_F2, IDM_NEW

;;; ----------------------------------------------------------------------
;;;   Uninitialized program data
;;; ----------------------------------------------------------------------
	segment	.bss
boardState:
	resd	1
rngState:
	resd	2
gameState:
	resb	1			; 0: in-game, 1: just won, 2: inert
