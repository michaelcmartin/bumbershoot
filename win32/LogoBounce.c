#include <windows.h>
#include <tchar.h>
#include "dx9tile.h"
#include "imgload.h"
#include "LogoBounce-res.h"
#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define MIN_WIDTH 640
#define MIN_HEIGHT 480

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam);

static dx9tile_t d9;
static int min_width = SCREEN_WIDTH;
static int min_height = SCREEN_HEIGHT;

static void compute_min_size(void)
{
    RECT r;
    r.left = 0;
    r.top = 0;
    r.right = MIN_WIDTH;
    r.bottom = MIN_HEIGHT;
    AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
    min_width = r.right - r.left;
    min_height = r.bottom - r.top;
}

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow)
{
    HWND hWnd = dx9tile_init(&d9, NULL, _T("DX9 Tile Graphics Test"), WindowProc, SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT, FALSE);
    dx9tex_t bg_texture = { NULL, 0, 0 };
    dx9tex_t fg_texture = { NULL, 0, 0 };
    compute_min_size();

    load_texture_from_resource(&d9, BG_IMAGE, &bg_texture);
    load_texture_from_resource(&d9, FG_IMAGE, &fg_texture);

    DWORD frameTimer = GetTickCount();
    MSG msg;
    int x = (SCREEN_WIDTH - fg_texture.w) / 2;
    int y = (SCREEN_HEIGHT - fg_texture.h) / 2;
    int dx = 1, dy = 1;
    while (TRUE) {
        RECT dest;
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

        /* Render our scene */
        dx9tile_begin_scene(&d9);

        dest.left = x;
        dest.right = x + fg_texture.w;
        dest.top = y;
        dest.bottom = y + fg_texture.h;

	dx9tile_set_alpha(&d9, 255);
	dx9tile_draw_tile(&d9, &bg_texture, NULL, NULL);
	dx9tile_set_alpha(&d9, 128);
	dx9tile_draw_tile(&d9, &fg_texture, NULL, &dest);

        dx9tile_end_scene(&d9);

        x += dx; y += dy;
        if (x < 0 || x + fg_texture.w > SCREEN_WIDTH) {
            dx = -dx;
            x += 2 * dx;
        }
        if (y < 0 || y + fg_texture.h > SCREEN_HEIGHT) {
            dy = -dy;
            y += 2 * dy;
        }
        endFrame = GetTickCount();
        if (endFrame - frameTimer < 20) {
            Sleep(20 - (endFrame - frameTimer));
        }
        frameTimer = endFrame;
    }
    if (bg_texture.tex) {
	IDirect3DTexture9_Release(bg_texture.tex);
    }
    if (fg_texture.tex) {
	IDirect3DTexture9_Release(fg_texture.tex);
    }
    dx9tile_uninit(&d9);
    return (int)msg.wParam;
}

LRESULT CALLBACK WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    MINMAXINFO* mmi;
    switch (message) {
    case WM_CLOSE:
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    case WM_SIZE:
        d9.was_resized = TRUE;
        break;
    case WM_GETMINMAXINFO:
        mmi = (MINMAXINFO*)lParam;
        mmi->ptMinTrackSize.x = min_width;
        mmi->ptMinTrackSize.y = min_height;
        return 0;
    default:
        break;
    }
    return DefWindowProc(hWnd, message, wParam, lParam);
}
