/**********************************************************************
 *                SIMULATED EVOLUTION: DX9 HARNESS
 *
 * This runs the simulated evolution simulation until the window is
 * closed, providing an animation of the process as it evolves.
 *
 * See simevo.h for authorship. provenance, and copyright information.
 **********************************************************************/

#include <stdint.h>
#include <stdlib.h>

#include <windows.h>
#include <tchar.h>

#include "simevo.h"
#include "modern_support.h"
#include "../win32/dx9pixmap.h"

void report_bug(const evo_state_t *state, int i, const char *action)
{
    /* This function nothing in the GUI; they are instead visible
     * in the animation */
    (void) state;
    (void) i;
    (void) action;
}

void report_birth(const evo_state_t *state, int parent, int child_1, int child_2)
{
    /* This function nothing in the GUI; they are instead visible
     * in the animation */
    (void) state;
    (void) parent;
    (void) child_1;
    (void) child_2;
}

/* Main program */

static dx9win_t dx9win;
static int warp = 0, garden = 1;

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message) {
    case WM_CLOSE:
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    case WM_KEYDOWN:
        if (wParam == 'G') {
            garden = 1 - garden;
        } else if (wParam == 'W') {
            warp = 1 - warp;
        }
        return 0;
    case WM_SIZE:
        dx9win.was_resized = TRUE;
        break;
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}

static const DWORD soup_color     = D3DCOLOR_XRGB(0x00, 0x00, 0x80);
static const DWORD plankton_color = D3DCOLOR_XRGB(0x00, 0xff, 0x00);
static const DWORD bug_color      = D3DCOLOR_XRGB(0xff, 0xff, 0xff);

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow)
{
    HWND hWnd;
    MSG msg;
    evo_state_t state;
    DWORD frameTimer;
    int64_t seed;
    int done = 0;

    hWnd = dx9win_init(&dx9win, NULL, _T("Simulated Evolution"), WindowProc, 450, 300, 150, 100, FALSE);
    if (!hWnd) {
        MessageBox(hWnd, _T("Could not initialize DirectX 9."), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        return 1;
    }
    dx9win.filter = D3DTEXF_NONE;

    seed_rng(GetTickCount());
    initialize(&state);

    frameTimer = GetTickCount();
    while (TRUE) {
        int i;
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

        run_cycle(&state);
        if (garden) {
            seed_garden(&state);
        }

        for (i = 0; i < 15000; ++i) {
            dx9win.pixels[i] = state.plankton[i] ? plankton_color : soup_color;
        }

        for (i = 0; i < state.num_bugs; ++i) {
            int x, y, dx, dy;
            x = state.bugs[i].x;
            y = state.bugs[i].y;
            for (dy = 0; dy < 3; ++dy) {
                for (dx = 0; dx < 3; ++dx) {
                    dx9win.pixels[((y + dy) * 150) + x + dx] = bug_color;
                }
            }
        }

        dx9win.dirty = TRUE;

        if (warp) {
            if (GetTickCount() - frameTimer >= 20) {
                dx9win_render(&dx9win);
                frameTimer = GetTickCount();
            }
        } else {
            dx9win_render(&dx9win);

            endFrame = GetTickCount();
            if (endFrame - frameTimer < 20) {
                Sleep(20 - (endFrame - frameTimer));
            }
            frameTimer = endFrame;
        }
    }

    dx9win_uninit(&dx9win);

    return (int)(msg.wParam);
}
