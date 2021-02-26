#include <math.h>
#include <stdlib.h>
#include <string.h>

#include <windows.h>
#include <tchar.h>
#include <d3d9.h>

#include "dx9pixmap.h"

/* #define FULLSCREEN */

/* The DX9 Pixmap window */
dx9win_t dx9win;

/* Our mostly-portable C implementation of the HAT function */
#define HAT_WIDTH 640
#define HAT_HEIGHT 480
#define HAT_PITCH (HAT_WIDTH * 4)

typedef struct hat_s {
    DWORD *pixels;
    double zz;
    BOOL dirty;
} hat_t;

hat_t hat;

void hat_slab(DWORD *pixels, int x, int y)
{
    pixels[y*HAT_WIDTH + x] = 0xffffff;
    ++y;
    while (y < HAT_HEIGHT - 1) {
        pixels[y*HAT_WIDTH + x] = 0;
        ++y;
    }
}

void hat_row(DWORD *pixels, double zz)
{
    double xp = 144.0, yp = 56.0, zp = 64.0, yr = 1.0;
    double xr = 1.5*3.14159265358979323846;
    double xf = xr / xp;
    double yf = yp / yr;
    double zt = zz * xp / zp;
    int xl = (int)(0.5 + sqrt(xp * xp - zt * zt));
    double xi;
    for (xi = -xl; xi <= xl; xi += 0.5) {
        double xt = sqrt(xi * xi + zt * zt) * xf;
        double xx = xi;
        double yy = (sin(xt) + 0.4*sin(3 * xt))*yf;
        int x1 = (int)((160.0 - xx - zz) * 2);
        int y1 = (int)((120.0 - yy + zz) * 2);
        hat_slab(pixels, x1, y1);
    }
}

void hat_init(hat_t *hat, DWORD *pixels)
{
    if (!hat || !pixels) {
        return;
    }
    hat->pixels = pixels;
    memset(hat->pixels, 0, HAT_PITCH * HAT_HEIGHT);
    hat->zz = -64.0;
    hat->dirty = TRUE;
}

void hat_step(hat_t *hat)
{
    if (!hat) {
        return;
    }
    if (hat->zz <= 64.0) {
        hat_row(hat->pixels, hat->zz);
        hat->zz += 0.5;
        hat->dirty = TRUE;
    } else {
        hat->dirty = FALSE;
    }
}

/* Win32-level initialization and main loop */

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow) {
    HWND hWnd;
    MSG msg;
#ifdef FULLSCREEN
    hWnd = dx9win_init(&dx9win, NULL, _T("The HAT Function"), WindowProc, 1920, 1080, HAT_WIDTH, HAT_HEIGHT, TRUE);
#else
    hWnd = dx9win_init(&dx9win, NULL, _T("The HAT Function"), WindowProc, HAT_WIDTH, HAT_HEIGHT, HAT_WIDTH, HAT_HEIGHT, FALSE);
#endif
    if (!hWnd) {
        MessageBox(hWnd, _T("Could not initialize DirectX 9."), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        return 1;
    }
    hat_init(&hat, dx9win.pixels);

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

        hat_step(&hat);
        dx9win.dirty = hat.dirty;
        dx9win_render(&dx9win);

        endFrame = GetTickCount();
        if (endFrame - frameTimer < 20) {
            Sleep(20 - (endFrame - frameTimer));
        }
        frameTimer = endFrame;
    }

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
    case WM_SIZE:
        dx9win.was_resized = TRUE;
        break;
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}
