#pragma once
#ifndef DX9PIXMAP_H_
#define DX9PIXMAP_H_

#include <windows.h>
#include <tchar.h>
#include <d3d9.h>

typedef struct dx9win_s {
    /* State that is part of any D3D9 rendering context */
    LPDIRECT3D9 d3d9;
    LPDIRECT3DDEVICE9 device;
    HWND hWnd;
    RECT render_rect;
    int screen_width, screen_height;
    BOOL fullscreen, was_resized, device_lost;

    /* State that is specific to a display based on a pixmap, like ours */
    int width, height;
    DWORD *pixels;
    LPDIRECT3DSURFACE9 surface;
    BOOL surface_dirty, surface_valid;
} dx9win_t;

HWND dx9win_init(dx9win_t *, LPCTSTR wnd_class, LPCTSTR wnd_caption, WNDPROC wnd_proc, int screen_w, int screen_h, int w, int h, BOOL fullscreen);
void dx9win_uninit(dx9win_t *);

HRESULT dx9win_render(dx9win_t *);

#endif
