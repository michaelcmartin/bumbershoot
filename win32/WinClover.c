/*******************************************************************
 * CLOVER.C - Implements the famous "Smoking Clover" effect
 * (c) 2020 Michael Martin/Bumbershoot Software.
 * Published under the 2-clause BSD license.
 *******************************************************************/

#include <math.h>
#include <string.h>

#include <windows.h>
#include <tchar.h>
#include <d3d9.h>

#include "dx9pixmap.h"

/* #define FULLSCREEN */

/* Simulated 320x200 paletted display. */
unsigned char screen[76800];

/* Our palette sequence, with buffers for intro and overlaps */
D3DCOLOR palette[959];
static int current_counter = 0;

/* Truecolor DX9 context. */
dx9win_t dx9;

/* Simple implementation of Bresenham's algorithm from Paul Heckbert's
 * version in Graphics Gems. The plot routine is an increment operation. */
static void
line_inc(int x1, int y1, int x2, int y2)
{
    int d, x, y, ax, ay, sx, sy, dx, dy;

    dx = x2-x1; ax = dx < 0 ? -dx : dx; sx = dx < 0 ? -1 : (dx > 0 ? 1 : 0);
    dy = y2-y1; ay = dy < 0 ? -dy : dy; sy = dy < 0 ? -1 : (dy > 0 ? 1 : 0);
    ax <<= 1; ay <<= 1;

    x = x1; y = y1;
    if (ax > ay) {                      /* x dominant */
        d = ay - (ax >> 1);
        for (;;) {
            if (x >= 0 && y >= 0 && x < 320 && y < 240) {
                ++screen[y*320+x];
            }
            if (x == x2) {
                return;
            }
            if (d >= 0) {
                y += sy;
                d -= ax;
            }
            x += sx;
            d += ay;
        }
    } else {                            /* y dominant */
        d = ax - (ay >> 1);
        for (;;) {
            if (x >= 0 && y >= 0 && x < 320 && y < 240) {
                ++screen[y*320+x];
            }
            if (y == y2) {
                return;
            }
            if (d >= 0) {
                x += sx;
                d -= ay;
            }
            y += sy;
            d += ax;
        }
    }
}

/* Draw the clover image itself by drawing a circle of radius r
 * converging on the center. We need to hit each pixel in the circle
 * exactly once, so we solve x^2+y^2=r^2 in the first octant and then
 * mirror the rest. */
static void
draw_display(int r)
{
    int x;
    double r2 = (double)r * (double)r;
    for (x = 0; x < r; ++x) {
        double x2 = (double)x * (double)x;
        int y = sqrt(r2-x2);
        if (y < x) break;
        line_inc(160, 120, 160+x, 120+y);
        line_inc(160, 120, 160+y, 120+x);
        line_inc(160, 120, 160-x, 120+y);
        line_inc(160, 120, 160-y, 120+x);
        line_inc(160, 120, 160+x, 120-y);
        line_inc(160, 120, 160+y, 120-x);
        line_inc(160, 120, 160-x, 120-y);
        line_inc(160, 120, 160-y, 120-x);
    }
}

void init_palette(void)
{
    int i;
    /* Start with all zeros */
    memset(palette, 0, 959*sizeof(D3DCOLOR));
    /* Then create all of our gradients after that */
    for (i = 0; i < 64; ++i) {
        palette[256+i] = D3DCOLOR_XRGB(i*4, 0, 0);
        palette[320+i] = D3DCOLOR_XRGB(252, i*4, 0);
        palette[384+i] = D3DCOLOR_XRGB(252-i*4, 252, 0);
        palette[448+i] = D3DCOLOR_XRGB(0, 252, i*4);
        palette[512+i] = D3DCOLOR_XRGB(0, 252-i*4, 252);
        palette[576+i] = D3DCOLOR_XRGB(i*4, 0, 252);
        palette[640+i] = D3DCOLOR_XRGB(252, 0, 252-4*i);
    }
    /* Finally copy the beginning of the sequence to the end, so that
     * we can smoothly loop. */
    memcpy(palette+704, palette+320, 255*sizeof(D3DCOLOR));
}

void clover_frame(void)
{
    int i;
    if (++current_counter > 703) {
        current_counter = 320;
    }
    /* Now do the palette translation over to the DX9 surface */
    for (i = 0; i < 76800; ++i) {
        dx9.pixels[i] = palette[current_counter + (int)screen[i]];
    }
    dx9.surface_dirty = TRUE;
}

/* Win32-level initialization and main loop */

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow) {
    HWND hWnd;
    MSG msg;
#ifdef FULLSCREEN
    hWnd = dx9win_init(&dx9, NULL, _T("Smoking Clover"), WindowProc, 1920, 1080, 320, 240, TRUE);
#else
    hWnd = dx9win_init(&dx9, NULL, _T("Smoking Clover"), WindowProc, 960, 720, 320, 240, FALSE);
#endif
    if (!hWnd) {
        MessageBox(hWnd, _T("Could not initialize DirectX 9."), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        return 1;
    }

    memset(screen, 0, 76800);           /* Clear the simulated screen */
    draw_display(1000);                 /* Create the display */
    init_palette();

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

        clover_frame();
        dx9win_render(&dx9);

        endFrame = GetTickCount();
        if (endFrame - frameTimer < 20) {
            Sleep(20 - (endFrame - frameTimer));
        }
        frameTimer = endFrame;
    }

    dx9win_uninit(&dx9);

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
        dx9.was_resized = TRUE;
        break;
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}
