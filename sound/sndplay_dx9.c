/**********************************************************************
 * Audio clip playback demo: DirectX 9/DirectSound
 * Bumbershoot Software, 2023
 **********************************************************************/
#include <stdlib.h>

#include <windows.h>
#include <tchar.h>
#include <dsound.h>

#include "dx9pixmap.h"
#include "wavefile.h"
#include "sndplay_dx9-res.h"

/* Interpreted resource data */
static wavefile_t wow, bumbershoot;
static DWORD font[64][64];

/* DirectX resources */
static dx9win_t dx9win;
static LPDIRECTSOUND8 audio_device;
static LPDIRECTSOUNDBUFFER wow_buf, bumbershoot_buf;

/********** RESOURCE EXTRACTORS **********/

/* Pull a binary blob out of the resource segment */
static const unsigned char*
get_res(int rsrc, unsigned int* sz)
{
    HRSRC info_block;
    HGLOBAL resource;

    info_block = FindResource(NULL, MAKEINTRESOURCE(rsrc), RT_RCDATA);
    if (!info_block) return NULL;

    resource = LoadResource(NULL, info_block);
    if (!resource) return NULL;

    if (sz) *sz = SizeofResource(NULL, info_block);
    return LockResource(resource);
}

/* Load the font data out of the resource segment, and convert each
 * character to a 64-pixel sequence. */
static void
load_font(void)
{
    int i = 32; /* Start halfway through to fix screencode nonsense */
    const unsigned char *dat = get_res(SINESTRA_BIN, NULL);

    for (int row = 0; row < 8; ++row) {
        for (int col = 0; col < 8; ++col) {
            for (int char_row = 0; char_row < 8; ++char_row) {
                int v = *dat++;
                for (int bit = 0; bit < 8; ++bit) {
                    font[i][char_row * 8 + bit] = (v & 0x80) ? D3DCOLOR_XRGB(0xFF, 0xFF, 0xFF) : D3DCOLOR_XRGB(0x00, 0x00, 0x00);
                    v <<= 1;
                }
            }
            i = (i + 1) % 64;
        }
    }
}

/* Extract a 16kHz 8-bit mono WAV out of the resource segment and
 * cache its parsed form. */
static int
load_wav(wavefile_t* target, int resource)
{
    unsigned int sz = 0;
    const unsigned char *dat = get_res(resource, &sz);
    return wavefile_parsebuf(target, dat, sz);
}

/********** DirectSound Support Routines **********/

/* Given a parsed WAV file, produce a DirectSound buffer that
 * represents that audio clip. */
static int
alloc_clip(LPDIRECTSOUNDBUFFER* clip, wavefile_t* wave)
{
    WAVEFORMATEX wave_format;
    wave_format.wFormatTag = WAVE_FORMAT_PCM;
    wave_format.nChannels = 1;
    wave_format.nSamplesPerSec = 16000;
    wave_format.nAvgBytesPerSec = 16000;
    wave_format.nBlockAlign = 1;
    wave_format.wBitsPerSample = 8;
    wave_format.cbSize = 0;

    *clip = NULL;
    DSBUFFERDESC buffer_desc;
    ZeroMemory(&buffer_desc, sizeof(DSBUFFERDESC));
    buffer_desc.dwSize = sizeof(DSBUFFERDESC);
    buffer_desc.dwFlags = 0;
    buffer_desc.dwBufferBytes = wave->data_size;
    buffer_desc.lpwfxFormat = &wave_format;
    if (SUCCEEDED(IDirectSound8_CreateSoundBuffer(audio_device, &buffer_desc, clip, NULL))) {
        void *p1, *p2;
        DWORD p1_sz, p2_sz;
        if (SUCCEEDED(IDirectSoundBuffer_Lock(*clip, 0, wave->data_size, &p1, &p1_sz, &p2, &p2_sz, 0))) {
            memcpy(p1, wave->data, p1_sz);
            if (p2) {
                memcpy(p2, (const char *)wave->data + p1_sz, p2_sz);
            }
            IDirectSoundBuffer_Unlock(*clip, p1, p1_sz, p2, p2_sz);
            return 1;
        }
    }
    return 0;
}

/* Silence any other playing clips and start playing the given clip
 * from the start. */
static void
play_clip(LPDIRECTSOUNDBUFFER clip)
{
    IDirectSoundBuffer_Stop(wow_buf);
    IDirectSoundBuffer_Stop(bumbershoot_buf);
    IDirectSoundBuffer_SetCurrentPosition(clip, 0);
    IDirectSoundBuffer_Play(clip, 0, 0, 0);
}

/********** VIDEO SUPPORT ROUTINES **********/

/* Draw a string in the loaded font into the dx9win pixmap. */
static void
draw_string(dx9win_t *win, int x, int y, const char *msg)
{
    for (; *msg; ++msg, x+=8) {
        int c = *msg - 32;
        int base = y * win->width + x;
        int index = 0;
        if (c < 0 || c >= 64) continue;
        for (int i = 0; i < 8; ++i) {
            for (int j = 0; j < 8; ++j) {
                win->pixels[base + j] = font[c][index++];
            }
            base += win->width;
        }
    }
}

/********** MAIN PROGRAM **********/

/* Window procedure. React appropriately to resize and window-close
 * messages, and play any clips asked for by keyboard presses. */
static LRESULT CALLBACK
WindowProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message) {
    case WM_CLOSE:
    case WM_DESTROY:
    {
        PostQuitMessage(0);
        return 0;
    } break;
    case WM_KEYDOWN:
        if (wParam == '1') play_clip(wow_buf);
        if (wParam == '2') play_clip(bumbershoot_buf);
        break;
    case WM_SIZE:
        dx9win.was_resized = TRUE;
        break;
    }

    return DefWindowProc(hWnd, message, wParam, lParam);
}

int APIENTRY
_tWinMain(HINSTANCE hInstance, HINSTANCE ignored, LPTSTR cmdLine, int nCmdShow) {
    HWND hWnd;
    MSG msg;

    /* Verify that our audio resources are OK */
    load_wav(&wow, WOW_WAV);
    load_wav(&bumbershoot, BUMBERSHOOT_WAV);
    if (!wow.valid || !bumbershoot.valid) {
        MessageBox(NULL, _T("Bundled sound clips are corrupt"), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        return 1;
    }

    /* Set up video */
    hWnd = dx9win_init(&dx9win, NULL, _T("DirectX Sound Clip Demo"), WindowProc, 640, 480, 320, 240, FALSE);
    if (!hWnd) {
        MessageBox(NULL, _T("Could not initialize DirectX 9."), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        return 1;
    }
    dx9win.filter = D3DTEXF_NONE;
    ZeroMemory(dx9win.pixels, sizeof(DWORD) * dx9win.width * dx9win.height);

    /* Set up audio, and create our clip buffers */
    if (FAILED(DirectSoundCreate8(NULL, &audio_device, NULL))) {
        MessageBox(NULL, _T("Could not initialize audio driver"), _T("Flagrant System Error"), MB_ICONEXCLAMATION);
        dx9win_uninit(&dx9win);
        return 1;
    }
    IDirectSound8_SetCooperativeLevel(audio_device, hWnd, DSSCL_NORMAL);
    alloc_clip(&wow_buf, &wow);
    alloc_clip(&bumbershoot_buf, &bumbershoot);

    /* Draw our display. The pixmap persists across frames, so we only
     * have to do this once. */
    load_font();
    draw_string(&dx9win, 76,   8, "SDL AUDIO CLIP PLAYER");
    draw_string(&dx9win, 72, 108, "1. WOW! DIGITAL SOUND!");
    draw_string(&dx9win, 72, 124, "2. BUMBERSHOOT SONG");
    draw_string(&dx9win, 80, 224, "CLOSE WINDOW TO QUIT");

    /* Main event loop. Everything exciting happens in WindowProc. */
    while (TRUE) {
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

        dx9win_render(&dx9win);

        Sleep(20);
    }

    /* Clean up audio */
    if (wow_buf) IDirectSoundBuffer_Release(wow_buf);
    if (bumbershoot_buf) IDirectSoundBuffer_Release(bumbershoot_buf);
    IDirectSound8_Release(audio_device);

    /* Clean up video */
    dx9win_uninit(&dx9win);

    /* Quit to Windows */
    return (int)msg.wParam;
}
