#include <math.h>
#include <stdlib.h>
#include <string.h>

#include <windows.h>
#include <tchar.h>

#include "dx9pixmap.h"
#include "CCA.h"

/* #define FULLSCREEN */
CCAContext *ctx = NULL;

/* The DX9 Pixmap window */
dx9win_t dx9win;

static void CCA_blit(CCAContext *ctx, dx9win_t *d9);

/* Win32-level initialization and main loop */

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow) {
    HWND hWnd;
    MSG msg;
#ifdef FULLSCREEN
    hWnd = dx9win_init(&dx9win, NULL, _T("The Cyclic Cellular Automaton"), WindowProc, 1920, 1080, CCA_WIDTH, CCA_HEIGHT, TRUE);
#else
    hWnd = dx9win_init(&dx9win, NULL, _T("The Cyclic Cellular Automaton"), WindowProc, CCA_WIDTH*5, CCA_HEIGHT * 5, CCA_WIDTH, CCA_HEIGHT, FALSE);
#endif
    if (!hWnd) {
        MessageBox(hWnd, _T("Could not initialize DirectX 9."), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        return 1;
    }
    dx9win.filter = D3DTEXF_NONE;
    CCA_seed_random();
    ctx = CCA_alloc();

    DWORD frameTimer = GetTickCount();
    while (TRUE) {
        DWORD endFrame;
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
            if (msg.message == WM_QUIT) {
                break;
            }
        }

        if (msg.message == WM_QUIT) {
            break;
        }

        CCA_step(ctx);
        CCA_blit(ctx, &dx9win);
        dx9win_render(&dx9win);

        endFrame = GetTickCount();
        if (endFrame - frameTimer < 50) {
            Sleep(50 - (endFrame - frameTimer));
        }
        frameTimer = endFrame;
    }

    CCA_free(ctx);
    dx9win_uninit(&dx9win);

    return (int)(msg.wParam);
}

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message) {
    case WM_CLOSE:
    case WM_DESTROY:
    {
        PostQuitMessage(0);
        return 0;
    } break;
    case WM_LBUTTONUP:
        CCA_scramble(ctx);
        break;
    case WM_SIZE:
        dx9win.was_resized = TRUE;
        break;
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}

static DWORD palette[16] = {
    D3DCOLOR_XRGB(0x00, 0x00, 0x00),
    D3DCOLOR_XRGB(0x00, 0x00, 0xAA),
    D3DCOLOR_XRGB(0x00, 0xAA, 0x00),
    D3DCOLOR_XRGB(0x00, 0xAA, 0xAA),
    D3DCOLOR_XRGB(0xAA, 0x00, 0x00),
    D3DCOLOR_XRGB(0xAA, 0x00, 0xAA),
    D3DCOLOR_XRGB(0xAA, 0x55, 0x00),
    D3DCOLOR_XRGB(0xAA, 0xAA, 0xAA),
    D3DCOLOR_XRGB(0x55, 0x55, 0x55),
    D3DCOLOR_XRGB(0x55, 0x55, 0xFF),
    D3DCOLOR_XRGB(0x55, 0xFF, 0x55),
    D3DCOLOR_XRGB(0x55, 0xFF, 0xFF),
    D3DCOLOR_XRGB(0xFF, 0x55, 0x55),
    D3DCOLOR_XRGB(0xFF, 0x55, 0xFF),
    D3DCOLOR_XRGB(0xFF, 0xFF, 0x55),
    D3DCOLOR_XRGB(0xFF, 0xFF, 0xFF)
};

static void CCA_blit(CCAContext *ctx, dx9win_t *d9)
{
    int x, y;
    CCA *grid = ctx->front;
    DWORD *target = d9->pixels;
    for (y = 0; y < CCA_HEIGHT; ++y) {
        for (x = 0; x < CCA_WIDTH; ++x) {
            *target++ = palette[grid->grid[y][x] & 0x0F];
        }
    }
    d9->surface_dirty = TRUE;
}
