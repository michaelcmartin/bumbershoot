        ;; Bookkeeping and Win32 imports
        GLOBAL  _start
        EXTERN  _ExitProcess@4, _GetStdHandle@4, _WriteConsoleW@20
        STD_OUTPUT_HANDLE equ -11

        ;; Main program
        section .text
_start:
        push    STD_OUTPUT_HANDLE
        call    _GetStdHandle@4
        push    0
        push    written
        push    msglen
        push    msg
        push    eax
        call    _WriteConsoleW@20
        push    0
        call    _ExitProcess@4
        ret

        ;; Our message
        section .data
msg:    dw      __utf16__("Hello, world!"),13,10
        msglen equ ($-msg)/2

        ;; Reserve some space to dump output we don't care about
        section .bss
written resd    1

