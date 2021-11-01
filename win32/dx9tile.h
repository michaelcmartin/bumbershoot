#pragma once
#ifndef DX9PIXMAP_H_
#define DX9PIXMAP_H_

#include <windows.h>
#include <tchar.h>
#include <d3d9.h>

typedef struct dx9tile_vertex_s {
    FLOAT x, y, z, rhw;
    DWORD diffuse;
    FLOAT tu, tv;
} dx9tile_vertex_t;

typedef struct dx9tile_s {
    /* State that is part of any D3D9 rendering context */
    LPDIRECT3D9 d3d9;
    LPDIRECT3DDEVICE9 device;
    HWND hWnd;
    RECT render_rect;
    int screen_width, screen_height;
    D3DTEXTUREFILTERTYPE filter;
    D3DCOLOR clear_color;
    BOOL fullscreen, was_resized, device_lost;

    /* State that is specific to a display based on tile-drawing, like ours */
    int width, height;
    LPDIRECT3DTEXTURE9 screen_texture;
    LPDIRECT3DSURFACE9 texture_surf, screen_surf;
    LPDIRECT3DVERTEXBUFFER9 vertex_buffer;
    BOOL valid;

    dx9tile_vertex_t current_quad[4];
} dx9tile_t;

typedef struct dx9tex_s {
    LPDIRECT3DTEXTURE9 tex;
    int w, h;
} dx9tex_t;

HWND dx9tile_init(dx9tile_t *, LPCTSTR wnd_class, LPCTSTR wnd_caption, WNDPROC wnd_proc, int screen_w, int screen_h, int w, int h, BOOL fullscreen);
void dx9tile_uninit(dx9tile_t *);

HRESULT dx9tile_begin_scene(dx9tile_t *);
HRESULT dx9tile_end_scene(dx9tile_t *);

HRESULT dx9tile_draw_tile(dx9tile_t *, dx9tex_t *, RECT *src_rect, RECT *dest_rect);
HRESULT dx9tile_draw_fill_rect(dx9tile_t *, int r, int g, int b, int a, RECT *dest_rect);

HRESULT dx9tile_set_color(dx9tile_t *, int r, int g, int b);
HRESULT dx9tile_set_alpha(dx9tile_t *, int a);

#endif
