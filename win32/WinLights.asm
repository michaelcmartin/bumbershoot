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
	SW_SHOWDEFAULT	equ	10
	WM_DESTROY	equ	0x02
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
	EXTERN	_ExitProcess@4, _GetModuleHandleA@4

	;; user32.lib
	EXTERN	_BeginPaint@8, _CreateWindowExA@48, _DefWindowProcA@16
	EXTERN	_DispatchMessageA@4, _EndPaint@8, _GetMessageA@16
	EXTERN	_InvalidateRect@12, _LoadCursorA@8, _PostQuitMessage@4
	EXTERN	_RegisterClassExA@4, _ShowWindow@8, _TranslateMessage@4

	;; gdi32.lib
	EXTERN	_Ellipse@20, _GetStockObject@4, _SelectObject@8
	EXTERN	_SetDCBrushColor@8

;;; ----------------------------------------------------------------------
;;;   Main Program
;;; ----------------------------------------------------------------------

	section	.text
_start:	mov	[boardState], dword 0x1bababb	; TEMP: canned board data
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
	mov	edx, 400		; CreateWindowEx: 400x400 by default
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
	push	eax
	call	_ShowWindow@8

	;; Main event loop. ESI is still zero, and EBX is still apibuf.
mainlp:	push	esi
	push	esi
	push	esi
	push	ebx			; Reuse the window class arg for msgs
	call	_GetMessageA@16
	or	eax, eax		; Is the result >= 0?
	jl	finis			; If not, something went wrong, quit
	push	ebx
	call	_TranslateMessage@4
	push	ebx
	call	_DispatchMessageA@4
	mov	eax, dword [ebx+MSG.message]
	cmp	eax, WM_QUIT		; Was this a quit message?
	jne	mainlp			; If not, back to main loop

	;; End of main program.
finis:	mov	eax, dword [ebx+MSG.wParam]
	push	eax			; Forward retcode from quit msg
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
	;; Otherwise we don't know what it is, so tailcall to default.
	mov	esp, ebp
	pop	ebp
	jmp	_DefWindowProcA@16
.destroy:
	xor	eax, eax		; Return code 0
	call	_PostQuitMessage@4	; ... and post a proper quit message
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
	xor	eax, eax
	mov	al, 70
	push	eax
	mov	al, 60
	push	eax
	mov	al, 10
	push	eax
	push	eax
	call	paint_grid

	;; Restore EBX and end painting
	pop	ebx
	mov	edx, esp
	push	edx
	push	dword [ebp+8]
	call	_EndPaint@8
	jmp	.fin
.lbuttondown:
	xor	eax, eax
	movsx	eax, word [ebp+22]	; Y
	push	eax
	movsx	eax, word [ebp+20]	; X
	push	eax
	xor	eax, eax
	mov	al, 70
	push	eax
	mov	al, 60
	push	eax
	mov	al, 10
	push	eax
	push	eax
	call	hit_test
	or	eax, eax		; Has a cell been clicked?
	jl	.fin			; If not, do nothing
	mov	eax, [moveTable+4*eax]	; If so, load the move mask...
	xor	[boardState], eax	; ... and make the move
	xor	eax, eax		; Now force a repaint
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

	;; paint_grid(left, top, size, stride)
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
;;;   Game management routines
;;; ----------------------------------------------------------------------

	;; hit_test(left, top, size, stride, x, y) -> returns 0-24 if we
	;; have hit a cell, or -1 if no target is hit.
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

;;; ----------------------------------------------------------------------
;;;   Program data
;;; ----------------------------------------------------------------------

	;; Constants for the window and its class
classNameString:
	db	"WLV",0

windowCaption:
	db	"Lights Out!",0

moveTable:
	dd	0x0000023, 0x0000047, 0x000008e, 0x000011c, 0x0000218
	dd	0x0000461, 0x00008e2, 0x00011c4, 0x0002388, 0x0004310
	dd	0x0008c20, 0x0011c40, 0x0023880, 0x0047100, 0x0086200
	dd	0x0118400, 0x0238800, 0x0471000, 0x08e2000, 0x10c4000
	dd	0x0308000, 0x0710000, 0x0e20000, 0x1c40000, 0x1880000

;;; ----------------------------------------------------------------------
;;;   Uninitialized program data
;;; ----------------------------------------------------------------------
	segment	.bss
boardState:
	resd	1
