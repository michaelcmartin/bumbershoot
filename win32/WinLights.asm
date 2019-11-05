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

	COLOR_WINDOW	equ	5
	CS_VREDRAW	equ	1
	CS_HREDRAW	equ	2
	IDC_ARROW	equ	32512
	SW_SHOWDEFAULT	equ	10
	WM_DESTROY	equ	0x02
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
	EXTERN	_CreateWindowExA@48, _DefWindowProcA@16, _DispatchMessageA@4
	EXTERN	_GetMessageA@16, _LoadCursorA@8, _PostQuitMessage@4
	EXTERN	_RegisterClassExA@4, _ShowWindow@8, _TranslateMessage@4


;;; ----------------------------------------------------------------------
;;;   Main Program
;;; ----------------------------------------------------------------------

	section	.text
_start:	sub	esp, WNDCLASSEX_size	; Reserve space for window class
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
	mov	eax, [esp+8]		; Load message into EAX
	cmp	eax, WM_DESTROY		; Is this a destroy message?
	je	.destroy
	;; Otherwise we don't know what it is, so tailcall to default.
	jmp	_DefWindowProcA@16
.destroy:
	xor	eax, eax		; Return code 0
	call	_PostQuitMessage@4	; ... and post a proper quit message
.fin:	xor	eax, eax		; And report success handling the event
	ret	16

;;; ----------------------------------------------------------------------
;;;   Program data
;;; ----------------------------------------------------------------------

	;; Constants for the window and its class
classNameString:
	db	"WLV",0

windowCaption:
	db	"Lights Out!",0
