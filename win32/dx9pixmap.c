#include "dx9pixmap.h"

#include <stdlib.h>

static void
invalidate_surface(dx9win_t *d9)
{
    if (d9->valid) {
        d9->valid = FALSE;
        IDirect3DVertexBuffer9_Release(d9->vertex_buffer);
        d9->vertex_buffer = NULL;
    }
}

typedef struct tex_vertex_s {
    FLOAT x, y, z, rhw;
    FLOAT tu, tv;
} tex_vertex_t;

static tex_vertex_t quad[4] = {
        { 0.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f },
        { 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f },
        { 1.0f, 1.0f, 0.0f, 1.0f, 1.0f, 1.0f },
        { 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f } };

static void
recreate_vertex_buffer(dx9win_t *d9)
{
    void *locked_buffer = NULL;
    if (!d9->valid) {
        if (FAILED(IDirect3DDevice9_CreateVertexBuffer(d9->device, sizeof(quad), 0, D3DFVF_XYZRHW | D3DFVF_TEX1, D3DPOOL_DEFAULT, &d9->vertex_buffer, NULL))) {
            return;
        }
        d9->valid = TRUE;
    }
    if (SUCCEEDED(IDirect3DVertexBuffer9_Lock(d9->vertex_buffer, 0, 0, &locked_buffer, D3DLOCK_DISCARD))) {
        quad[0].x = quad[1].x = d9->render_rect.left - 0.5f;
        quad[2].x = quad[3].x = d9->render_rect.right - 0.5f;
        quad[0].y = quad[2].y = d9->render_rect.bottom - 0.5f;
        quad[1].y = quad[3].y = d9->render_rect.top - 0.5f;
        memcpy(locked_buffer, quad, sizeof(quad));
        IDirect3DVertexBuffer9_Unlock(d9->vertex_buffer);
    }
}

static void
update_render_rect(dx9win_t *d9)
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

static HRESULT
upload_pixmap(dx9win_t *d9)
{
    HRESULT result;
    if (d9->dirty) {
        D3DLOCKED_RECT locked_rect;
        int y;
        unsigned char *dest;
        DWORD *src;

        result = IDirect3DTexture9_LockRect(d9->texture, 0, &locked_rect, NULL, 0);
        if (FAILED(result)) {
            return result;
        }

        dest = locked_rect.pBits;
        src = d9->pixels;
        for (y = 0; y < d9->height; ++y) {
            memcpy(dest, src, d9->width * 4);
            dest += locked_rect.Pitch;
            src += d9->width;
        }
        IDirect3DTexture9_UnlockRect(d9->texture, 0);
        d9->dirty = FALSE;
    }
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
    d3dpp->EnableAutoDepthStencil = TRUE;
    d3dpp->AutoDepthStencilFormat = D3DFMT_D16;
}

HWND
dx9win_init(dx9win_t *d9, LPCTSTR wnd_class, LPCTSTR wnd_caption, WNDPROC wnd_proc, int screen_w, int screen_h, int w, int h, BOOL fullscreen)
{
    D3DPRESENT_PARAMETERS d3dpp;
    WNDCLASSEX wc;
    RECT winRect;
    int init_w, init_h;
    HRESULT result;
    HINSTANCE hInstance;
    DWORD *pixels;
    HWND hWnd;

    /* Try to do our big allocation first, and if this fails, abort entirely */
    pixels = malloc(sizeof(DWORD) * w * h);
    if (!pixels) {
        return NULL;
    }
    d9->d3d9 = Direct3DCreate9(D3D_SDK_VERSION);

    if (wnd_class == NULL) {
        wnd_class = _T("DX9PixmapWin");
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
        free(pixels);
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
    d9->pixels = pixels;
    d9->vertex_buffer = NULL;
    d9->dirty = TRUE;
    d9->valid = FALSE;

    result = IDirect3DDevice9_CreateTexture(d9->device, d9->width, d9->height, 1, 0, D3DFMT_X8R8G8B8, D3DPOOL_MANAGED, &d9->texture, 0);
    if (FAILED(result)) {
        free(d9->pixels);
        IDirect3DDevice9_Release(d9->device);
        IDirect3D9_Release(d9->d3d9);
        return NULL;
    }

    update_render_rect(d9);
    return hWnd;
}

void dx9win_uninit(dx9win_t *d9)
{
    if (d9) {
        if (d9->pixels) {
            free(d9->pixels);
        }
        if (d9->valid) {
            IDirect3DVertexBuffer9_Release(d9->vertex_buffer);
        }
        IDirect3DTexture9_Release(d9->texture);
        IDirect3DDevice9_Release(d9->device);
        IDirect3D9_Release(d9->d3d9);
        ZeroMemory(d9, sizeof(dx9win_t));
    }
}

HRESULT dx9win_render(dx9win_t *d9)
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
    recreate_vertex_buffer(d9);
    upload_pixmap(d9);
    IDirect3DDevice9_Clear(d9->device, 0, NULL, D3DCLEAR_TARGET, d9->clear_color, 1.0f, 0);
    if (SUCCEEDED(IDirect3DDevice9_BeginScene(d9->device))) {
        HRESULT result;
        result = IDirect3DDevice9_SetStreamSource(d9->device, 0, d9->vertex_buffer, 0, sizeof(tex_vertex_t));
        result = IDirect3DDevice9_SetFVF(d9->device, D3DFVF_XYZRHW | D3DFVF_TEX1);
        result = IDirect3DDevice9_SetTexture(d9->device, 0, (LPDIRECT3DBASETEXTURE9)d9->texture);
        result = IDirect3DDevice9_SetSamplerState(d9->device, 0, D3DSAMP_MAGFILTER, d9->filter);
        result = IDirect3DDevice9_SetSamplerState(d9->device, 0, D3DSAMP_MINFILTER, d9->filter);
        result = IDirect3DDevice9_DrawPrimitive(d9->device, D3DPT_TRIANGLESTRIP, 0, 2);
        result = IDirect3DDevice9_EndScene(d9->device);
    }
    if (IDirect3DDevice9_Present(d9->device, NULL, NULL, NULL, NULL) == D3DERR_DEVICELOST) {
        invalidate_surface(d9);
        d9->device_lost = TRUE;
        return D3DERR_DEVICELOST;
    }
    return D3D_OK;
}
