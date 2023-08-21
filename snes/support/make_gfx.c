#include <stdio.h>
#include <stdint.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_PNG_ONLY
#include "stb_image.h"

uint8_t semigraph[16384], bitfont[512], font[4096];
uint16_t palette[256];
uint16_t cga[16] = {
    0x0000, 0x5400, 0x02a0, 0x56a0,
    0x0015, 0x5415, 0x0155, 0x56b5,
    0x294a, 0x7d4a, 0x2bea, 0x7fea,
    0x295f, 0x7d5f, 0x2bff, 0x7fff
};

void make_semigraphics(void)
{
    int i, l, r;
    for (i = 0; i < 8192; ++i) {
        semigraph[i] = 0;
    }
    i = 0;
    for (l = 0; l < 16; ++l) {
        for (r = 0; r < 16; ++r) {
            int j;
            for (j = 0; j < 4; ++j) {
                semigraph[i++] = l;
                semigraph[i++] = l;
                semigraph[i++] = l;
                semigraph[i++] = l;
                semigraph[i++] = r;
                semigraph[i++] = r;
                semigraph[i++] = r;
                semigraph[i++] = r;
            }
            for (j = 0; j < 32; ++j) {
                semigraph[i++] = 0;
            }
        }
    }
}

void make_font(void)
{
    int i, j, k, n, b, v;
    for (i = 0; i < 4096; ++i) {
        font[i] = 0;
    }
    i = 256; j = 0;
    for (n = 0; n < 64; ++n) {
        for (k = 0; k < 8; ++k) {
            v = bitfont[i];
            for (b = 0; b < 8; ++b) {
                if (v & 0x80) {
                    font[j] = (k != 3 && k != 4) ? 7 : 15;
                    if (b < 7 && k < 7) font[j+9] = 8;
                }
                v <<= 1;
                ++j;
            }
            ++i;
            if (i >= 512) i -= 512;
        }
    }
}

void encode(FILE *f, uint8_t *buf, int width, int height, int depth)
{
    int x, y;
    if (!f) {
        return;
    }
    for (y = 0; y < height; y += 8) {
        for (x = 0; x < width; x += 8) {
            int i, j;
            int c[8][8];
            for (i = 0; i < 8; ++i) {
                for (j = 0; j < 8; ++j) {
                    c[i][j] = 0;
                }
            }
            for (i = 0; i < 8; ++i) {
                for (j = 0; j < 8; ++j) {
                    int k;
                    int v = buf[(y+i) * width + x + j];
                    for (k = 0; k < 8; ++k) {
                        c[i][k] <<= 1;
                        if (v & 1) {
                            c[i][k] |= 1;
                        }
                        v >>= 1;
                    }
                }
            }
            for (i = 0; i < depth; i += 2) {
                for (j = 0; j < 8; ++j) {
                    fputc(c[j][i], f);
                    fputc(c[j][i+1], f);
                }
            }
        }
    }
}

int main(int argc, char **argv)
{
    int w, h, n;
    unsigned char *p;
    make_semigraphics();
    FILE *f = fopen("ancillary.bin", "wb");
    encode(f, semigraph, 8, 2048, 4);
    if (f) { fclose(f); }
    f = fopen("font_1bpp.bin", "rb");
    if (!f) {
        fprintf(stderr, "font_1bpp.bin not found, skipping\n");
        return 0;
    }
    fread(bitfont, 1, 512, f);
    fclose(f);
    make_font();
    f = fopen("ancillary.bin", "ab");
    encode(f, font, 8, 512, 4);
    if (f) { fclose(f); }
    return 0;
}
