#include <SDL2/SDL.h>
#include "wavefile.h"

/* Resource data, created by xxd */
extern unsigned char sinestra_bin[];
extern unsigned char wow_wav[];
extern unsigned char bumbershoot_wav[];

extern unsigned int sinestra_bin_len;
extern unsigned int wow_wav_len;
extern unsigned int bumbershoot_wav_len;

/* Interpreted resource data */
wavefile_t wow, bumbershoot;

SDL_Texture *
load_font(SDL_Renderer *renderer, unsigned char *dat, size_t len)
{
    unsigned char pixmap[16384];
    int i = 8192; /* Start halfway through to fix screencode nonsense */
    for (int row = 0; row < 8; ++row) {
        for (int col = 0; col < 8; ++col) {
            for (int char_row = 0; char_row < 8; ++char_row) {
                int i = 8192 + row * 2048 + char_row * 256 + col * 32;
                int v = *dat++;
                i = i % 16384;
                for (int bit = 0; bit < 8; ++bit) {
                    unsigned char color = (v & 0x80) ? 0xFF : 0x00;
                    pixmap[i] = color;
                    pixmap[i+1] = color;
                    pixmap[i+2] = color;
                    pixmap[i+3] = color;
                    i += 4;
                    v <<= 1;
                }
            }
        }
    }
    SDL_Surface *surf = SDL_CreateRGBSurfaceWithFormatFrom(pixmap, 64, 64, 4, 256, SDL_PIXELFORMAT_RGBA32);
    SDL_Texture *tex = NULL;
    if (surf) {
        tex = SDL_CreateTextureFromSurface(renderer, surf);
        SDL_FreeSurface(surf);
    }
    return tex;
}

void
draw_string(SDL_Renderer *renderer, SDL_Texture *font, int x, int y, const char *msg)
{
    for (; *msg; ++msg, x+=8) {
        SDL_Rect glyph, cell;
        int c = *msg - 32;
        if (c < 0 || c >= 64) continue;
        cell.x = x;
        cell.y = y;
        cell.w = 8;
        cell.h = 8;
        glyph.x = (c & 0x07) << 3;
        glyph.y = c & 0xf8;
        glyph.w = 8;
        glyph.h = 8;

        SDL_RenderCopy(renderer, font, &glyph, &cell);
    }
}

int
main(int argc, char **argv)
{
    SDL_Window *window;
    SDL_Renderer *renderer;
    SDL_AudioSpec wanted_audio, got_audio;
    SDL_AudioDeviceID audio_device = 0;
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_TIMER) < 0) {
        return 3;
    }

    if (SDL_CreateWindowAndRenderer(640,480, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        return 3;
    }

    SDL_SetWindowTitle(window, "Font Test");
    SDL_RenderSetLogicalSize(renderer, 320, 240);
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");

    SDL_Texture *font = load_font(renderer, sinestra_bin, sinestra_bin_len);
    if (!font) {
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 2;
    }

    SDL_zero(wanted_audio);
    wanted_audio.freq=16000;
    wanted_audio.format = AUDIO_U8;
    wanted_audio.channels = 1;
    wanted_audio.samples = 256;
    wanted_audio.callback = NULL;
    audio_device = SDL_OpenAudioDevice(NULL, 0, &wanted_audio, &got_audio, 0);
    if (audio_device == 0) {
        SDL_DestroyTexture(font);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        return 2;
    }
    SDL_PauseAudioDevice(audio_device, 0);
    wavefile_parsebuf(&wow, wow_wav, wow_wav_len);
    wavefile_parsebuf(&bumbershoot, bumbershoot_wav, bumbershoot_wav_len);
    if (!wow.valid) { fprintf(stderr, "WOW did not load.\n"); }
    if (!bumbershoot.valid) { fprintf(stderr, "BUMBERSHOOT did not load.\n"); }
    int done = 0;
    while (!done) {
        SDL_Event event;
        SDL_Rect dest;
        dest.x = 128;
        dest.y = 88;
        dest.w = 64;
        dest.h = 64;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                done = 1;
            } else if (event.type == SDL_KEYDOWN) {
                wavefile_t *chosen = NULL;
                if (event.key.keysym.sym == SDLK_1) {
                    chosen = &wow;
                } else if (event.key.keysym.sym == SDLK_2) {
                    chosen = &bumbershoot;
                } else {
                    chosen = NULL;
                }
                if (chosen) {
                    SDL_ClearQueuedAudio(audio_device);
                    SDL_QueueAudio(audio_device, chosen->data, chosen->data_size);
                }
            }
        }
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
        SDL_RenderClear(renderer);
        draw_string(renderer, font, 76,   8, "SDL AUDIO CLIP PLAYER");
        draw_string(renderer, font, 72, 108, "1. WOW! DIGITAL SOUND!");
        draw_string(renderer, font, 72, 124, "2. BUMBERSHOOT SONG");
        draw_string(renderer, font, 80, 224, "CLOSE WINDOW TO QUIT");
        SDL_RenderPresent(renderer);
        SDL_Delay(20);
    }

    SDL_CloseAudioDevice(audio_device);
    SDL_DestroyTexture(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
