#include "dx9tile.h"

#include <stdlib.h>

typedef struct screen_vertex_s {
    FLOAT x, y, z, rhw;
    FLOAT tu, tv;
} screen_vertex_t;

static void
invalidate_surface(dx9tile_t* d9)
{
    if (!d9->valid) {
        return;
    }
    d9->valid = FALSE;
    IDirect3DVertexBuffer9_Release(d9->vertex_buffer);
    IDirect3DSurface9_Release(d9->texture_surf);
    IDirect3DTexture9_Release(d9->screen_texture);
    d9->vertex_buffer = NULL;
    d9->texture_surf = NULL;
    d9->screen_texture = NULL;
}

static void
ensure_surface(dx9tile_t* d9)
{
    if (d9->valid) {
        return;
    }
    d9->screen_texture = NULL;
    d9->screen_surf = NULL;
    d9->vertex_buffer = NULL;
    if (FAILED(IDirect3DDevice9_CreateTexture(d9->device, d9->width, d9->height, 1, D3DUSAGE_RENDERTARGET, D3DFMT_X8R8G8B8, D3DPOOL_DEFAULT, &d9->screen_texture, 0))) {
        goto fail;
    }
    if (FAILED(IDirect3DTexture9_GetSurfaceLevel(d9->screen_texture, 0, &d9->texture_surf))) {
        goto fail;
    }
    if (FAILED(IDirect3DDevice9_CreateVertexBuffer(d9->device, sizeof(screen_vertex_t) * 4, 0, D3DFVF_XYZRHW | D3DFVF_TEX1, D3DPOOL_DEFAULT, &d9->vertex_buffer, NULL))) {
        goto fail;
    }
    d9->valid = TRUE;
    return;
fail:
    if (d9->vertex_buffer) {
        IDirect3DVertexBuffer9_Release(d9->vertex_buffer);
        d9->vertex_buffer = NULL;
    }
    if (d9->texture_surf) {
        IDirect3DSurface9_Release(d9->texture_surf);
        d9->texture_surf = NULL;
    }
    if (d9->screen_texture) {
        IDirect3DTexture9_Release(d9->screen_texture);
        d9->screen_texture = NULL;
    }
    d9->valid = FALSE;
}

static void
update_render_rect(dx9tile_t* d9)
{
    double a_v = (double)d9->screen_width / (double)d9->screen_height;
    double a_i = (double)d9->width / (double)d9->height;
    double s_x = 1.0, s_y = 1.0;
    double o_x = 0.0, o_y = 0.0;
    if (a_v < a_i) {
        s_y = a_v / a_i;
        o_y = d9->screen_height * (1.0 - s_y) / 2.0;
    } else {
        s_x = a_i / a_v;
        o_x = d9->screen_width * (1.0 - s_x) / 2.0;
    }
    d9->render_rect.left = (LONG)o_x;
    d9->render_rect.right = (LONG)(d9->screen_width * s_x + o_x);
    d9->render_rect.top = (LONG)o_y;
    d9->render_rect.bottom = (LONG)(d9->screen_height * s_y + o_y);
}


static void
configure_vertex_buffer(dx9tile_t* d9)
{
    static screen_vertex_t screen_quad[4] = {
        { 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f },
        { 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
        { 1.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f },
        { 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f } };
    void* locked_buffer = NULL;

    if (!d9->valid) {
        return;
    }
    if (SUCCEEDED(IDirect3DVertexBuffer9_Lock(d9->vertex_buffer, 0, 0, &locked_buffer, D3DLOCK_DISCARD))) {
        screen_quad[0].x = screen_quad[1].x = d9->render_rect.left - 0.5f;
        screen_quad[2].x = screen_quad[3].x = d9->render_rect.right - 0.5f;
        screen_quad[0].y = screen_quad[2].y = d9->render_rect.bottom - 0.5f;
        screen_quad[1].y = screen_quad[3].y = d9->render_rect.top - 0.5f;
        memcpy(locked_buffer, screen_quad, sizeof(screen_vertex_t) * 4);
        IDirect3DVertexBuffer9_Unlock(d9->vertex_buffer);
    }
}

HRESULT
dx9tile_set_alpha(dx9tile_t *d9, int a)
{
    int i;
    if (!d9) {
        return D3DERR_INVALIDCALL;
    }
    for (i = 0; i < 4; ++i) {
        d9->current_quad[i].diffuse = ((a & 0xff) << 24) | (d9->current_quad[i].diffuse & 0xffffff);
    }
    return D3D_OK;
}

HRESULT
dx9tile_set_color(dx9tile_t* d9, int r, int g, int b)
{
    int i;
    if (!d9) {
        return D3DERR_INVALIDCALL;
    }
    for (i = 0; i < 4; ++i) {
        d9->current_quad[i].diffuse = D3DCOLOR_ARGB((d9->current_quad[i].diffuse >> 24) & 0xff, r, g, b);
    }
    return D3D_OK;
}

HRESULT
dx9tile_draw_tile(dx9tile_t *d9, dx9tex_t* tile, RECT* src_rect, RECT* dest_rect)
{
    float src_x1, src_y1, src_x2, src_y2;
    float dest_x1, dest_y1, dest_x2, dest_y2;
    dx9tile_vertex_t* quad;
    if (!tile || !d9) {
        return D3DERR_INVALIDCALL;
    }
    quad = d9->current_quad;

    if (src_rect) {
        src_x1 = (float)src_rect->left / tile->w;
        src_x2 = (float)src_rect->right / tile->w;
        src_y1 = (float)src_rect->top / tile->h;
        src_y2 = (float)src_rect->bottom / tile->h;
    }
    else {
        src_x1 = src_y1 = 0.0f;
        src_x2 = src_y2 = 1.0f;
    }

    if (dest_rect) {
        dest_x1 = (float)dest_rect->left - 0.5f;
        dest_x2 = (float)dest_rect->right - 0.5f;
        dest_y1 = (float)dest_rect->top - 0.5f;
        dest_y2 = (float)dest_rect->bottom - 0.5f;
    }
    else {
        dest_x1 = dest_y1 = -0.5f;
        dest_x2 = (float)d9->width - 0.5f;
        dest_y2 = (float)d9->height - 0.5f;
    }

    quad[0].x = quad[1].x = dest_x1;
    quad[2].x = quad[3].x = dest_x2;
    quad[1].y = quad[3].y = dest_y1;
    quad[0].y = quad[2].y = dest_y2;

    quad[0].tu = quad[1].tu = src_x1;
    quad[2].tu = quad[3].tu = src_x2;
    quad[1].tv = quad[3].tv = src_y1;
    quad[0].tv = quad[2].tv = src_y2;

    IDirect3DDevice9_SetTexture(d9->device, 0, (LPDIRECT3DBASETEXTURE9)tile->tex);
    IDirect3DDevice9_DrawPrimitiveUP(d9->device, D3DPT_TRIANGLESTRIP, 2, quad, sizeof(dx9tile_vertex_t));
    return D3D_OK;
}

static void
config_parameters(D3DPRESENT_PARAMETERS *d3dpp, HWND hWnd, int w, int h, BOOL fullscreen)
{
    ZeroMemory(d3dpp, sizeof(D3DPRESENT_PARAMETERS));
    d3dpp->Windowed = !fullscreen;
    d3dpp->SwapEffect = D3DSWAPEFFECT_DISCARD;
    d3dpp->hDeviceWindow = hWnd;
    d3dpp->BackBufferFormat = fullscreen ? D3DFMT_X8R8G8B8 : D3DFMT_UNKNOWN;
    d3dpp->BackBufferWidth = w;
    d3dpp->BackBufferHeight = h;
    d3dpp->EnableAutoDepthStencil = FALSE;
}

HWND
dx9tile_init(dx9tile_t *d9, LPCTSTR wnd_class, LPCTSTR wnd_caption, WNDPROC wnd_proc, int screen_w, int screen_h, int w, int h, BOOL fullscreen)
{
    D3DPRESENT_PARAMETERS d3dpp;
    WNDCLASSEX wc;
    RECT winRect;
    int init_w, init_h, i;
    HRESULT result;
    HINSTANCE hInstance;
    HWND hWnd;

    d9->d3d9 = Direct3DCreate9(D3D_SDK_VERSION);

    if (wnd_class == NULL) {
        wnd_class = _T("DX9TileWin");
    }
    hInstance = GetModuleHandle(NULL);
    if (!GetClassInfoEx(hInstance, wnd_class, &wc)) {
        ZeroMemory(&wc, sizeof(WNDCLASSEX));
        wc.cbSize = sizeof(WNDCLASSEX);
        wc.style = CS_HREDRAW | CS_VREDRAW;
        wc.lpfnWndProc = wnd_proc;
        wc.hInstance = hInstance;
        wc.hCursor = LoadCursor(NULL, IDC_ARROW);
        wc.lpszClassName = wnd_class;

        RegisterClassEx(&wc);
    }
    init_w = screen_w;
    init_h = screen_h;
    winRect.top = 0;
    winRect.left = 0;
    winRect.right = init_w;
    winRect.bottom = init_h;
    if (fullscreen) {
        hWnd = CreateWindowEx(0, wnd_class, wnd_caption,
            WS_POPUP | WS_VISIBLE,
            CW_USEDEFAULT, CW_USEDEFAULT,
            winRect.right - winRect.left, winRect.bottom - winRect.top,
            NULL, NULL, hInstance, NULL);
    } else {
        AdjustWindowRect(&winRect, WS_OVERLAPPEDWINDOW, FALSE);
        hWnd = CreateWindowEx(0, wnd_class, wnd_caption,
            WS_OVERLAPPEDWINDOW,
            0, 0,
            winRect.right - winRect.left, winRect.bottom - winRect.top,
            NULL, NULL, hInstance, NULL);
    }
    ShowWindow(hWnd, SW_SHOWDEFAULT);

    config_parameters(&d3dpp, hWnd, screen_w, screen_h, fullscreen);

    result = IDirect3D9_CreateDevice(d9->d3d9, D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd, D3DCREATE_HARDWARE_VERTEXPROCESSING, &d3dpp, &d9->device);
    if (FAILED(result)) {
        result = IDirect3D9_CreateDevice(d9->d3d9, D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd, D3DCREATE_MIXED_VERTEXPROCESSING, &d3dpp, &d9->device);
    }
    if (FAILED(result)) {
        result = IDirect3D9_CreateDevice(d9->d3d9, D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd, D3DCREATE_SOFTWARE_VERTEXPROCESSING, &d3dpp, &d9->device);
    }
    if (FAILED(result)) {
        IDirect3D9_Release(d9->d3d9);
        return NULL;
    }
    d9->hWnd = hWnd;
    d9->screen_width = screen_w;
    d9->screen_height = screen_h;
    d9->filter = D3DTEXF_LINEAR;
    d9->clear_color = D3DCOLOR_XRGB(0, 0, 0);
    d9->was_resized = FALSE;
    d9->device_lost = FALSE;
    d9->fullscreen = fullscreen;
    d9->width = w;
    d9->height = h;
    d9->vertex_buffer = NULL;
    d9->screen_texture = NULL;
    d9->screen_surf = NULL;
    d9->texture_surf = NULL;
    d9->valid = FALSE;

    ZeroMemory(d9->current_quad, sizeof(dx9tile_vertex_t) * 4);
    for (i = 0; i < 4; ++i) {
        d9->current_quad[i].rhw = 1.0f;
        d9->current_quad[i].diffuse = D3DCOLOR_ARGB(255, 255, 255, 255);
    }

    update_render_rect(d9);
    ensure_surface(d9);
    return hWnd;
}

void dx9tile_uninit(dx9tile_t *d9)
{
    if (d9) {
        invalidate_surface(d9);
        IDirect3DDevice9_Release(d9->device);
        IDirect3D9_Release(d9->d3d9);
        ZeroMemory(d9, sizeof(dx9tile_t));
    }
}

HRESULT dx9tile_begin_scene(dx9tile_t *d9)
{
    BOOL needs_reset = FALSE;
    if (d9->device_lost) {
        HRESULT dev_status = IDirect3DDevice9_TestCooperativeLevel(d9->device);
        if (SUCCEEDED(dev_status) || dev_status == D3DERR_DEVICENOTRESET) {
            needs_reset = TRUE;
        } else {
            return dev_status;
        }
    } else if (d9->was_resized) {
        invalidate_surface(d9);
        needs_reset = TRUE;
    }
    if (needs_reset) {
        RECT client_rect;
        D3DPRESENT_PARAMETERS d3dpp;
        GetClientRect(d9->hWnd, &client_rect);
        if (client_rect.left >= client_rect.right || client_rect.top >= client_rect.bottom) {
            /* Our context might still be valid, but we've got nothing to draw to. */
            return D3D_OK;
        }
        d9->screen_width = client_rect.right - client_rect.left;
        d9->screen_height = client_rect.bottom - client_rect.top;
        config_parameters(&d3dpp, d9->hWnd, d9->screen_width, d9->screen_height, d9->fullscreen);
        update_render_rect(d9);
        if (FAILED(IDirect3DDevice9_Reset(d9->device, &d3dpp))) {
            d9->device_lost = TRUE;
            return D3DERR_DEVICELOST;
        }
        d9->device_lost = FALSE;
        d9->was_resized = FALSE;
    }
    ensure_surface(d9);
    configure_vertex_buffer(d9);
    IDirect3DDevice9_Clear(d9->device, 0, NULL, D3DCLEAR_TARGET, d9->clear_color, 1.0f, 0);
    if (SUCCEEDED(IDirect3DDevice9_BeginScene(d9->device))) {
        /* TODO: Make sure that screen_surf is NULL here and that we are not nesting our scene calls. */
        IDirect3DDevice9_GetBackBuffer(d9->device, 0, 0, D3DBACKBUFFER_TYPE_MONO, &d9->screen_surf);
        IDirect3DDevice9_SetRenderTarget(d9->device, 0, d9->texture_surf);

        IDirect3DDevice9_SetFVF(d9->device, D3DFVF_XYZRHW | D3DFVF_DIFFUSE | D3DFVF_TEX1);
        IDirect3DDevice9_SetRenderState(d9->device, D3DRS_ALPHABLENDENABLE, TRUE);
        IDirect3DDevice9_SetRenderState(d9->device, D3DRS_SRCBLEND, D3DBLEND_SRCALPHA);
        IDirect3DDevice9_SetRenderState(d9->device, D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
        IDirect3DDevice9_SetSamplerState(d9->device, 0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
        IDirect3DDevice9_SetSamplerState(d9->device, 0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
        IDirect3DDevice9_SetTextureStageState(d9->device, 0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        IDirect3DDevice9_SetTextureStageState(d9->device, 0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
        IDirect3DDevice9_SetTextureStageState(d9->device, 0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
        IDirect3DDevice9_SetDepthStencilSurface(d9->device, NULL);
    }
    return D3D_OK;
}

HRESULT dx9tile_end_scene(dx9tile_t *d9)
{
    if (d9->screen_surf) {
        dx9tex_t tex = { d9->screen_texture, 100, 100 };
        IDirect3DDevice9_SetRenderTarget(d9->device, 0, d9->screen_surf);
        IDirect3DSurface9_Release(d9->screen_surf);
        d9->screen_surf = NULL;

        IDirect3DDevice9_SetStreamSource(d9->device, 0, d9->vertex_buffer, 0, sizeof(screen_vertex_t));
        IDirect3DDevice9_SetFVF(d9->device, D3DFVF_XYZRHW | D3DFVF_TEX1);
        IDirect3DDevice9_SetRenderState(d9->device, D3DRS_ALPHABLENDENABLE, FALSE);
        IDirect3DDevice9_SetTexture(d9->device, 0, (LPDIRECT3DBASETEXTURE9)d9->screen_texture);
        IDirect3DDevice9_SetSamplerState(d9->device, 0, D3DSAMP_MAGFILTER, d9->filter);
        IDirect3DDevice9_SetSamplerState(d9->device, 0, D3DSAMP_MINFILTER, d9->filter);


        IDirect3DDevice9_DrawPrimitive(d9->device, D3DPT_TRIANGLESTRIP, 0, 2);
    }
    IDirect3DDevice9_EndScene(d9->device);
    if (IDirect3DDevice9_Present(d9->device, NULL, NULL, NULL, NULL) == D3DERR_DEVICELOST) {
        d9->device_lost = TRUE;
        return D3DERR_DEVICELOST;
    }
    InvalidateRect(d9->hWnd, NULL, FALSE);
    return D3D_OK;
}
