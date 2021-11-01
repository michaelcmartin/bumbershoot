#include "imgload.h"

#include <stdlib.h>

#define STB_IMAGE_PNG_ONLY
#define STB_IMAGE_JPEG_ONLY
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

BOOL
load_texture_from_resource(dx9tile_t *d9, int rsc_id, dx9tex_t* out)
{
    LPDIRECT3DTEXTURE9 tex = NULL;
    DWORD* row = NULL;
    D3DLOCKED_RECT locked_rect;
    int w, h, n, y;
    const unsigned char* rsc_data;
    int rsc_len;
    unsigned char* picture;
    unsigned char* data, * src;
    HRSRC info_block;
    HGLOBAL resource;

    if (!out || !d9) {
        return FALSE;
    }

    info_block = FindResource(NULL, MAKEINTRESOURCE(rsc_id), RT_RCDATA);
    if (!info_block) {
        return FALSE;
    }
    resource = LoadResource(NULL, info_block);
    if (!resource) {
        return FALSE;
    }
    rsc_len = SizeofResource(NULL, info_block);
    rsc_data = LockResource(resource);

    picture = stbi_load_from_memory(rsc_data, rsc_len, &w, &h, &n, 4);
    if (!picture) {
        return FALSE;
    }

    if (FAILED(IDirect3DDevice9_CreateTexture(d9->device, w, h, 1, 0, (n & 1) ? D3DFMT_X8R8G8B8 : D3DFMT_A8R8G8B8, D3DPOOL_MANAGED, &tex, 0))) {
        stbi_image_free(picture);
        return FALSE;
    }
    if (FAILED(IDirect3DTexture9_LockRect(tex, 0, &locked_rect, NULL, 0))) {
        IDirect3DTexture9_Release(tex);
        stbi_image_free(picture);
        return FALSE;
    }
    data = locked_rect.pBits;
    src = picture;
    for (y = 0; y < h; ++y) {
        DWORD* row = (DWORD*)data;
        int x;
        for (x = 0; x < w; ++x) {
            *row++ = D3DCOLOR_ARGB(src[3], src[0], src[1], src[2]);
            src += 4;
        }
        data += locked_rect.Pitch;
    }
    IDirect3DTexture9_UnlockRect(tex, 0);
    stbi_image_free(picture);

    out->tex = tex;
    out->w = w;
    out->h = h;
    return TRUE;
}
