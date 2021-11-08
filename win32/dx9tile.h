#pragma once
#ifndef DX9PIXMAP_H_
#define DX9PIXMAP_H_

#include <windows.h>
#include <tchar.h>
#include <d3d9.h>

/* Vertex format for sprite draws. Clients should never need this,
 * except when computing sizeof(dx9tile_t). */
typedef struct dx9tile_vertex_s {
    FLOAT x, y, z, rhw;
    DWORD diffuse;
    FLOAT tu, tv;
} dx9tile_vertex_t;

/* Top-level type for managing a window with tile/sprite graphics. */
typedef struct dx9tile_s {
    LPDIRECT3D9 d3d9;                 /* D3D9 library handle */
    LPDIRECT3DDEVICE9 device;         /* D3D9 display device */
    HWND hWnd;                        /* The window we're drawing to */
    RECT render_rect;                 /* Render area within window */
    int screen_width, screen_height;  /* Window dimensions on-screen */
    D3DTEXTUREFILTERTYPE filter;      /* EDITABLE: nearest v. linear filter */
    D3DCOLOR clear_color;             /* EDITABLE: bg color */
    BOOL fullscreen;                  /* Are we in fullscreen mode? */
    BOOL was_resized;                 /* EDITABLE: window needs recreation */
    BOOL device_lost;                 /* window was taken from us */

    int width, height;                     /* Size of rendering area */
    LPDIRECT3DTEXTURE9 screen_texture;     /* Offscreen render target */
    LPDIRECT3DSURFACE9 texture_surf, screen_surf;  /* Render surfaces */
    LPDIRECT3DVERTEXBUFFER9 vertex_buffer;  /* Geometry for screen */
    BOOL valid;                            /* System ready for rendering */

    dx9tile_vertex_t current_quad[4]; /* sprite geometry/colors */
} dx9tile_t;

typedef struct dx9tex_s {
    LPDIRECT3DTEXTURE9 tex;
    int w, h;
} dx9tex_t;

/* Initialize the dx9tile_t argument, specifying the window's initial
 * properties and the properties of the render target. */
HWND dx9tile_init(dx9tile_t *, LPCTSTR wnd_class, LPCTSTR wnd_caption, WNDPROC wnd_proc, int screen_w, int screen_h, int w, int h, BOOL fullscreen);

/* Clean up all resources created by dx9tile_init. */
void dx9tile_uninit(dx9tile_t *);

/* Scene control. Call dx9tile_begin_scene before any of the
 * dx9tile_draw functions and then call dx9tile_end_scene to present
 * the resulting frame. */
HRESULT dx9tile_begin_scene(dx9tile_t *);
HRESULT dx9tile_end_scene(dx9tile_t *);

/* Draw a tile or sprite from the source rectangle in the texture to
 * the destination rectangle on the screen. */
HRESULT dx9tile_draw_tile(dx9tile_t *, dx9tex_t *, RECT *src_rect, RECT *dest_rect);
HRESULT dx9tile_draw_fill_rect(dx9tile_t *, int r, int g, int b, int a, RECT *dest_rect);

/* Set the color or alpha values for modulation of the sprites or
 * rectangles. */
HRESULT dx9tile_set_color(dx9tile_t *, int r, int g, int b);
HRESULT dx9tile_set_alpha(dx9tile_t *, int a);

#endif
