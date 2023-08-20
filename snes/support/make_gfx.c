#include <stdio.h>
#include <stdint.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_PNG_ONLY
#include "stb_image.h"

uint8_t logo[30720];
uint16_t palette[256];
uint16_t cga[16] = {
    0x0000, 0x5400, 0x02a0, 0x56a0,
    0x0015, 0x5415, 0x0155, 0x56b5,
    0x294a, 0x7d4a, 0x2bea, 0x7fea,
    0x295f, 0x7d5f, 0x2bff, 0x7fff
};

void convert(unsigned char *img)
{
    int x, y, i;
    /* Preload initial palette to CGA equivalent */
    for (i = 0; i < 16; ++i) {
        palette[i] = cga[i];
    }
    for (i = 16; i < 256; ++i) {
        palette[i] = 0;
    }
    /* Clear image */
    for (i = 0; i < 30720; ++i) {
        logo[i] = 0;
    }
    /* Actual convertible characters from 16-176 */
    for (y = 0; y < 192; ++y) {
        int row = y * 192;
        for (x = 16; x < 176; ++x) {
            int i = (row + x) * 4;
            int r = img[i] >> 4;
            int g = img[i+1] >> 4;
            int b = img[i+2] >> 4;
            r = (r << 1) | ((r & 8) ? 1 : 0);
            g = (g << 1) | ((g & 8) ? 1 : 0);
            b = (b << 1) | ((b & 8) ? 1 : 0);
            int col = r + (g << 5) + (b << 10);
            if (col != 0) {
                /* Black stays black; everything else, we find it in
                 * the palette and add it if it's not there */
                for (i = 1; i < 256; ++i) {
                    if (palette[i] == 0) {
                        palette[i] = col;
                        break;
                    }
                    if (palette[i] == col) {
                        break;
                    }
                }
                if (i == 256) {
                    printf("Out of palette space!\n");
                    return;
                }
                logo[y * 160 + x - 16] = i;
            }
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
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return 1;
    }
    unsigned char *img = stbi_load(argv[1], &w, &h, &n, 4);
    if (!img) {
        fprintf(stderr, "Could not load %s\n", argv[1]);
        return 1;
    }
    if (w != 192 || h != 192) {
        printf("This is not the correct source image\n");
        stbi_image_free(img);
        return 1;
    }
    convert(img);
    FILE *f = fopen("bumberlogo.bin", "wb");
    encode(f, logo, 160, 192, 8);
    if (f) { fclose(f); }
    f = fopen("bumberpal.bin", "wb");
    if (f) {
        for (n = 0; n < 256; ++n) {
            if (n > 0 && palette[n] == 0) break;
            fputc(palette[n] & 0xff, f);
            fputc(palette[n] >> 8, f);
        }
        fclose(f);
    }
    stbi_image_free(img);
    return 0;
}
